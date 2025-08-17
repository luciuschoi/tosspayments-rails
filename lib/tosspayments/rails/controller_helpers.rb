# frozen_string_literal: true

module Tosspayments
  module Rails
    module ControllerHelpers
      extend ActiveSupport::Concern

      included do
        before_action :verify_tosspayments_webhook, only: [:tosspayments_webhook] if respond_to?(:before_action)
      end

      private

      def tosspayments_client
        @tosspayments_client ||= Tosspayments::Rails::Client.new
      end

      def verify_tosspayments_webhook?
        # 토스페이먼츠 웹훅 검증 로직
        # 실제 구현시에는 토스페이먼츠에서 제공하는 서명 검증을 구현해야 합니다
        true
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
