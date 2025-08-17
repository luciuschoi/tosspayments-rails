# frozen_string_literal: true

module Tosspayments
  module Rails
    module TestHelpers
      # 테스트용 결제 데이터 생성
      def build_test_payment_data(options = {})
        {
          paymentKey: options[:payment_key] || "test_payment_key_#{SecureRandom.hex(8)}",
          orderId: options[:order_id] || "ORDER_#{Time.current.to_i}",
          amount: options[:amount] || 15000,
          method: options[:method] || "카드",
          status: options[:status] || "DONE",
          approvedAt: options[:approved_at] || Time.current.iso8601,
          orderName: options[:order_name] || "토스 티셔츠 외 2건"
        }
      end

      # 테스트용 브랜드페이 토큰 데이터 생성
      def build_test_brandpay_token_data(options = {})
        {
          accessToken: options[:access_token] || "test_access_token_#{SecureRandom.hex(16)}",
          refreshToken: options[:refresh_token] || "test_refresh_token_#{SecureRandom.hex(16)}",
          tokenType: "Bearer",
          expiresIn: options[:expires_in] || 3600
        }
      end

      # 테스트용 웹훅 데이터 생성
      def build_test_webhook_data(options = {})
        {
          eventType: options[:event_type] || "PAYMENT_STATUS_CHANGED",
          createdAt: options[:created_at] || Time.current.iso8601,
          data: build_test_payment_data(options[:payment_data] || {})
        }
      end

      # 모의 API 응답 설정 (WebMock 사용 시)
      def stub_tosspayments_confirm_payment(payment_data = {})
        data = build_test_payment_data(payment_data)
        
        stub_request(:post, "https://api.tosspayments.com/v1/payments/confirm")
          .to_return(
            status: 200,
            body: data.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      def stub_tosspayments_get_payment(payment_key, payment_data = {})
        data = build_test_payment_data(payment_data.merge(paymentKey: payment_key))
        
        stub_request(:get, "https://api.tosspayments.com/v1/payments/#{payment_key}")
          .to_return(
            status: 200,
            body: data.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      def stub_tosspayments_cancel_payment(payment_key, cancel_data = {})
        data = build_test_payment_data(
          cancel_data.merge(
            paymentKey: payment_key,
            status: "CANCELED"
          )
        )
        
        stub_request(:post, "https://api.tosspayments.com/v1/payments/#{payment_key}/cancel")
          .to_return(
            status: 200,
            body: data.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
    end
  end
end