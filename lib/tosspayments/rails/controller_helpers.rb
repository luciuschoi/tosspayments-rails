# frozen_string_literal: true

module Tosspayments
  module Rails
    module ControllerHelpers
      extend ActiveSupport::Concern

      included do
        # Rails 7.1에서 존재하지 않는 액션을 only로 지정하면 예외가 발생하므로
        # 템플릿 컨트롤러의 액션명(:webhook)에 맞춰 설정합니다.
        before_action :verify_tosspayments_webhook, only: [:webhook] if respond_to?(:before_action)
      end

      private

      def tosspayments_client
        @tosspayments_client ||= Tosspayments::Rails::Client.new
      end

      # before_action에서 호출될 실제 콜백 메서드
      def verify_tosspayments_webhook
        # 실제 서명 검증 로직으로 대체 가능
        # verifier = Tosspayments::Rails::WebhookVerifier.new
        # ok = verifier.verify_signature(request.raw_post, request.headers['X-TossPayments-Signature'])
        ok = verify_tosspayments_webhook?
        return true if ok

        head :unauthorized
      end

      # 결제 승인 헬퍼
      def confirm_tosspayments_payment(payment_key:, order_id:, amount:)
        tosspayments_client.confirm_payment(
          payment_key: payment_key,
          order_id: order_id,
          amount: amount
        )
      rescue Tosspayments::Rails::PaymentError => e
        ::Rails.logger.error "토스페이먼츠 결제 승인 실패: #{e.message}"
        { success: false, error: e.message }
      end

      # 결제 취소 헬퍼
      def cancel_tosspayments_payment(payment_key:, cancel_reason:, cancel_amount: nil)
        tosspayments_client.cancel_payment(
          payment_key: payment_key,
          cancel_reason: cancel_reason,
          cancel_amount: cancel_amount
        )
      rescue Tosspayments::Rails::PaymentError => e
        ::Rails.logger.error "토스페이먼츠 결제 취소 실패: #{e.message}"
        { success: false, error: e.message }
      end

      # 결제 조회 헬퍼
      def get_tosspayments_payment(payment_key)
        tosspayments_client.get_payment(payment_key)
      rescue Tosspayments::Rails::PaymentError => e
        ::Rails.logger.error "토스페이먼츠 결제 조회 실패: #{e.message}"
        { success: false, error: e.message }
      end
    end
  end
end
