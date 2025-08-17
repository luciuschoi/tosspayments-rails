# frozen_string_literal: true

class PaymentsController < ApplicationController
  include Tosspayments::Rails::ControllerHelpers

  # 결제 페이지
  def new
    @order_id = "ORDER_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
    @amount = params[:amount] || 15_000
    @order_name = params[:order_name] || '토스 티셔츠 외 2건'
    @customer_key = current_user&.id || "GUEST_#{SecureRandom.hex(8)}"
  end

  # 결제 승인 처리
  def create
    payment_key = params[:paymentKey]
    order_id = params[:orderId]
    amount = params[:amount].to_i

    result = confirm_tosspayments_payment(
      payment_key: payment_key,
      order_id: order_id,
      amount: amount
    )

    if result[:success]
      # 결제 성공 시 PaymentDetail 저장
      save_payment_detail(result[:data]) if payment_detail_model_exists?
      redirect_to success_payments_path(paymentKey: payment_key)
    else
      redirect_to fail_payments_path(message: result[:error])
    end
  end

  # 결제 성공 페이지
  def success
    @payment_key = params[:paymentKey]
    @payment = get_tosspayments_payment(@payment_key) if @payment_key
  end

  # 결제 실패 페이지
  def fail
    @error_code = params[:code]
    @error_message = params[:message]
  end

  # 웹훅 처리 (토스페이먼츠에서 결제 상태 변경시 호출)
  def webhook
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
    log_payment_error("저장", e)
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
    log_payment_error("상태 업데이트", e)
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
end
