# frozen_string_literal: true

class PaymentsController < ApplicationController # rubocop:disable Metrics/ClassLength
  # include Tosspayments::Rails::ControllerHelpers

  # 결제 페이지
  def new
    @post = Post.find(params[:post_id])
    @user = User.find(params[:user_id])

    # 이미 결제한 사용자인지 확인
    if @post.paid_by_user?(@user)
      flash[:notice] = '이미 결제하신 게시글입니다.'
      redirect_to post_path(@post)
      return
    end

    @order_id = "POST_#{@post.id}_USER_#{@user.id}_#{Time.current.to_i}"
    # TossPayments 표준결제 금액은 원화 그대로 사용 (소수점 제거 정수)
    @amount = @post.price.to_i
    @order_name = @post.title
    @customer_key = customer_key_for(@user)
  end

  # 결제 승인 처리
  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    payment_key = params[:paymentKey]
    order_id = params[:orderId]
    amount = params[:amount].to_i

    # order_id에서 post_id와 user_id 추출
    post_id, user_id = extract_ids_from_order_id(order_id)

    unless post_id && user_id
      redirect_to fail_payments_path(message: '잘못된 주문 정보입니다.')
      return
    end

    post = Post.find(post_id)
    user = User.find(user_id)

    result = confirm_tosspayments_payment(
      payment_key: payment_key,
      order_id: order_id,
      amount: amount
    )

    if result[:success]
      # Payment 레코드 생성
      payment = create_payment_record(post, user, result[:data], amount)

      if payment
        redirect_to success_payments_path(paymentKey: payment_key, post_id: post.id)
      else
        redirect_to fail_payments_path(message: '결제 정보 저장에 실패했습니다.')
      end
    else
      redirect_to fail_payments_path(message: result[:error])
    end
  end

  # 결제 성공 페이지
  def success
    @payment_key = params[:paymentKey]
    @post = Post.find(params[:post_id]) if params[:post_id]
    @payment = get_tosspayments_payment(@payment_key) if @payment_key
  end

  # 결제 실패 페이지
  def fail
    @error_code = params[:code]
    @error_message = params[:message]
  end

  # 웹훅 처리 (토스페이먼츠에서 결제 상태 변경시 호출)
  def webhook # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
    data = params[:data] || {}
    payment_key = data[:paymentKey] || data['paymentKey']
    return head :bad_request unless payment_key

    # 결제 정보 조회
    payment = get_tosspayments_payment(payment_key)
    if payment[:success]
      case payment[:status]
      when 'DONE'
        Rails.logger.info "결제 완료: #{payment_key}"
        # 웹훅에서도 PaymentDetail 저장 (중복 방지를 위해 upsert 방식 사용)
        save_payment_detail(payment[:data]) if payment_detail_model_exists?
      when 'CANCELED'
        Rails.logger.info "결제 취소: #{payment_key}"
        # 결제 취소 시 상태 업데이트
        update_payment_detail_status(payment_key, 'canceled') if payment_detail_model_exists?
      end
    end

    head :ok
  end

  private

  # order_id에서 post_id와 user_id 추출
  def extract_ids_from_order_id(order_id)
    # 형식: "POST_#{post_id}_USER_#{user_id}_#{timestamp}"
    match = order_id.match(/POST_(\d+)_USER_(\d+)_\d+/)
    return nil unless match

    [match[1].to_i, match[2].to_i]
  end

  # Payment 레코드 생성
  def create_payment_record(post, user, payment_data, amount)
    Payment.create!(
      user: user,
      post: post,
      order_id: payment_data['orderId'],
      payment_key: payment_data['paymentKey'],
      amount: amount, # 이미 원 단위 정수
      status: payment_data['status']&.downcase || 'done',
      method: payment_data['method'],
      customer_email: user.email,
      customer_name: user.name,
      order_name: payment_data['orderName'],
      raw_data: payment_data.to_json,
      paid_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error "Payment 레코드 생성 실패: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def current_user
    # 실제 애플리케이션에서는 인증된 사용자를 반환하도록 구현
    nil
  end

  # PaymentDetail 모델이 존재하는지 확인
  def payment_detail_model_exists?
    defined?(Tosspayments::Rails::PaymentDetail)
  end

  # 결제 상세 정보 저장
  def save_payment_detail(payment_data)
    return unless payment_data

    payment_key = payment_data['paymentKey']
    existing_payment = find_existing_payment(payment_key)

    if existing_payment
      update_existing_payment(existing_payment, payment_data)
    else
      create_new_payment(payment_data)
    end
  rescue StandardError => e
    log_payment_error('저장', e)
  end

  def find_existing_payment(payment_key)
    Tosspayments::Rails::PaymentDetail.find_by(payment_key: payment_key)
  end

  def update_existing_payment(payment_detail, payment_data)
    payment_detail.update!(payment_attributes_from_api(payment_data))
    Rails.logger.info "PaymentDetail 업데이트 완료: #{payment_data['paymentKey']}"
  end

  def create_new_payment(payment_data)
    payment_detail = Tosspayments::Rails::PaymentDetail.from_api_response(payment_data)
    payment_detail.save!
    Rails.logger.info "PaymentDetail 저장 완료: #{payment_data['paymentKey']}"
  end

  # 결제 상태 업데이트
  def update_payment_detail_status(payment_key, status)
    return unless payment_key && status

    payment_detail = find_existing_payment(payment_key)
    return unless payment_detail

    payment_detail.update!(status: status)
    Rails.logger.info "PaymentDetail 상태 업데이트 완료: #{payment_key} -> #{status}"
  rescue StandardError => e
    log_payment_error('상태 업데이트', e)
  end

  def log_payment_error(operation, error)
    Rails.logger.error "PaymentDetail #{operation} 실패: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
  end

  # API 응답 데이터를 PaymentDetail 속성으로 변환
  def payment_attributes_from_api(payment_data)
    basic_attributes(payment_data).merge(
      payment_method_attributes(payment_data)
    ).merge(
      financial_attributes(payment_data)
    )
  end

  def basic_attributes(payment_data)
    {
      order_id: payment_data['orderId'],
      order_name: payment_data['orderName'],
      method: payment_data['method'],
      status: payment_data['status']&.downcase,
      currency: payment_data['currency'],
      receipt_url: payment_data['receiptUrl'],
      approved_at: parse_approved_at(payment_data['approvedAt'])
    }
  end

  def payment_method_attributes(payment_data)
    {
      card: payment_data['card'],
      virtual_account: payment_data['virtualAccount'],
      transfer: payment_data['transfer'],
      cancels: payment_data['cancels']
    }
  end

  def financial_attributes(payment_data)
    {
      total_amount: payment_data['totalAmount'],
      balance_amount: payment_data['balanceAmount'],
      supplied_amount: payment_data['suppliedAmount'],
      vat: payment_data['vat'],
      use_escrow: payment_data['useEscrow'],
      culture_expense: payment_data['cultureExpense'],
      tax_free_amount: payment_data['taxFreeAmount'],
      tax_exemption_amount: payment_data['taxExemptionAmount']
    }
  end

  def parse_approved_at(approved_at_string)
    return nil unless approved_at_string

    Time.parse(approved_at_string)
  rescue ArgumentError
    nil
  end

  # Toss Payments 고객 키 생성 (2~50자, 허용문자: A-Z a-z 0-9 - _ = . @)
  def customer_key_for(user)
    base = if user.respond_to?(:email) && user.email.present?
             user.email.to_s.downcase
           else
             "user-#{user.id}"
           end
    # 제거: 허용되지 않는 문자
    base = base.gsub(/[^A-Za-z0-9\-_=\.@]/, '')
    base = "user-#{user.id}" if base.blank?
    # 최대 50자
    base = base[0, 50]
    # 최소 2자 보장
    base = base.ljust(2, '0') if base.length < 2
    base
  end
end
