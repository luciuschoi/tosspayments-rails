# frozen_string_literal: true

class PaymentsController < ApplicationController
  include Tosspayments::Rails::ControllerHelpers

  # 결제 페이지
  def new
    @order_id = "ORDER_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
    @amount = params[:amount] || 15000
    @order_name = params[:order_name] || "토스 티셔츠 외 2건"
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

    if result[:success] != false
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
    payment_key = params[:data][:paymentKey]
    
    # 결제 정보 조회
    payment = get_tosspayments_payment(payment_key)
    
    if payment[:success] != false
      # 결제 상태에 따른 비즈니스 로직 처리
      case payment[:status]
      when "DONE"
        # 결제 완료 처리
        Rails.logger.info "결제 완료: #{payment_key}"
      when "CANCELED"
        # 결제 취소 처리
        Rails.logger.info "결제 취소: #{payment_key}"
      end
    end

    head :ok
  end

  private

  def current_user
    # 실제 애플리케이션에서는 인증된 사용자를 반환하도록 구현
    nil
  end
end