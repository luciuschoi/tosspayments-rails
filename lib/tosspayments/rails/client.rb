# frozen_string_literal: true

require 'faraday'
require 'faraday/net_http'
require 'json'
require 'base64'

module Tosspayments
  module Rails
    class Client
      BASE_URL = 'https://api.tosspayments.com'

      def initialize(secret_key: nil)
        @secret_key = secret_key || Tosspayments::Rails.configuration.secret_key
        raise ConfigurationError, 'Secret key is required' if @secret_key.nil? || @secret_key.empty?
      end

      # 결제 승인 API
      def confirm_payment(payment_key:, order_id:, amount:)
        result = post('/v1/payments/confirm', {
                        paymentKey: payment_key,
                        orderId: order_id,
                        amount: amount
                      })

        # 결제 성공 시 상세 정보 저장
        save_payment_details(result) if result[:status] == 'DONE'

        result
      end

      # 결제 조회 API
      def get_payment(payment_key)
        get("/v1/payments/#{payment_key}")
      end

      # 결제 취소 API
      def cancel_payment(payment_key:, cancel_reason: nil, cancel_amount: nil, refund_receive_account: nil)
        body = { cancelReason: cancel_reason }
        body[:cancelAmount] = cancel_amount if cancel_amount
        body[:refundReceiveAccount] = refund_receive_account if refund_receive_account

        result = post("/v1/payments/#{payment_key}/cancel", body)

        # 결제 취소 시 상태 업데이트
        update_payment_status(payment_key, 'CANCELED', result) if result[:status] == 'CANCELED'

        result
      end

      # 가상계좌 콜백 인증 API
      def verify_virtual_account_callback(payment_key)
        get("/v1/payments/#{payment_key}")
      end

      # 브랜드페이 Access Token 발급 API
      def create_brandpay_access_token(code:, customer_key:, grant_type: 'AuthorizationCode')
        post('/v1/brandpay/authorizations/access-token', {
               grantType: grant_type,
               customerKey: customer_key,
               code: code
             })
      end

      # 브랜드페이 결제수단 조회 API
      def get_brandpay_payment_methods(customer_key)
        get('/v1/brandpay/payment-methods', { customerKey: customer_key })
      end

      # 상세 결제 정보 저장 (한글/영문 변환, 영수증 URL, 실패 정보 반영)
      def save_payment_details(payment_data)
        return unless defined?(::PaymentDetail)

        # 문자열/심볼 키 모두 지원
        data = payment_data.is_a?(Hash) ? payment_data : payment_data.to_h

        # 한글/영문 변환
        method = normalize_payment_method(data[:method] || data['method'])
        status = normalize_payment_status(data[:status] || data['status'])

        # 영수증 URL 추출
        receipt_url =
          if data[:receipt]&.dig(:url)
            data[:receipt][:url]
          elsif data['receipt']&.dig('url')
            data['receipt']['url']
          elsif data[:checkout]&.dig(:url)
            data[:checkout][:url]
          elsif data['checkout']&.dig('url')
            data['checkout']['url']
          else
            data[:receiptUrl] || data['receiptUrl']
          end

        # 실패 정보
        failure_code = data.dig(:failure, :code) || data.dig('failure', 'code')
        failure_reason = data.dig(:failure, :message) || data.dig('failure', 'message')

        PaymentDetail.create!(
          payment_key: data[:paymentKey] || data['paymentKey'],
          order_id: data[:orderId] || data['orderId'],
          order_name: data[:orderName] || data['orderName'],
          method: method,
          status: status,
          total_amount: data[:totalAmount] || data['totalAmount'],
          balance_amount: data[:balanceAmount] || data['balanceAmount'],
          supplied_amount: data[:suppliedAmount] || data['suppliedAmount'],
          vat: data[:vat] || data['vat'],
          currency: data[:currency] || data['currency'],
          card: data[:card] || data['card'],
          virtual_account: data[:virtualAccount] || data['virtualAccount'],
          transfer: data[:transfer] || data['transfer'],
          cancels: data[:cancels] || data['cancels'],
          receipt_url: receipt_url,
          approved_at: parse_datetime(data[:approvedAt] || data['approvedAt']),
          use_escrow: data[:useEscrow] || data['useEscrow'],
          culture_expense: data[:cultureExpense] || data['cultureExpense'],
          tax_free_amount: data[:taxFreeAmount] || data['taxFreeAmount'],
          tax_exemption_amount: data[:taxExemptionAmount] || data['taxExemptionAmount'],
          failure_code: failure_code,
          failure_reason: failure_reason
        )
      rescue StandardError => e
        Rails.logger.error "결제 상세 정보 저장 실패: #{e.message}"
        nil
      end

      # 한글 결제방법을 영문 enum으로 변환
      def normalize_payment_method(method_value)
        return nil if method_value.blank?

        case method_value.to_s
        when '카드' then 'card'
        when '계좌이체' then 'transfer'
        when '가상계좌' then 'virtual_account'
        when '휴대폰' then 'phone'
        when '상품권' then 'gift_certificate'
        when '문화상품권' then 'culture_gift_certificate'
        when '도서문화상품권' then 'book_gift_certificate'
        when '게임문화상품권' then 'game_gift_certificate'
        else
          method_value.to_s.downcase
        end
      end

      # 한글/영문 결제상태를 영문 enum으로 변환
      def normalize_payment_status(status_value)
        return 'pending' if status_value.blank?

        case status_value.to_s.downcase
        when 'ready', 'in_progress', 'waiting_for_deposit' then 'ready'
        when 'waiting_for_acceptance' then 'in_progress'
        when 'done' then 'done'
        when 'canceled' then 'canceled'
        when 'partial_canceled' then 'partial_canceled'
        when 'aborted' then 'aborted'
        when 'expired', 'failed' then 'failed'
        else
          status_value.to_s.downcase
        end
      end

      def parse_datetime(datetime_string)
        return nil if datetime_string.blank?

        begin
          Time.parse(datetime_string)
        rescue StandardError
          nil
        end
      end

      # 결제 상태 업데이트
      def update_payment_status(payment_key, status, additional_data = {})
        return unless defined?(::PaymentDetail)

        payment_detail = PaymentDetail.find_by(payment_key: payment_key)
        return unless payment_detail

        update_attributes = { status: status }
        update_attributes.merge!(additional_data) if additional_data && !additional_data.empty?

        payment_detail.update!(update_attributes)
      rescue StandardError => e
        Rails.logger.error "결제 상태 업데이트 실패: #{e.message}"
        nil
      end

      # 결제 상세 정보 조회
      def get_payment_detail(payment_key)
        return unless defined?(::PaymentDetail)

        PaymentDetail.find_by(payment_key: payment_key)
      end

      # 결제 통계 조회
      def get_payment_statistics(start_date: nil, end_date: nil, status: nil)
        return unless defined?(::PaymentDetail)

        query = PaymentDetail.all
        query = query.where(created_at: start_date..end_date) if start_date && end_date
        query = query.where(status: status) if status

        {
          total_count: query.count,
          total_amount: query.sum(:total_amount),
          by_status: query.group(:status).count,
          by_method: query.group(:method).count
        }
      end

      private

      def connection
        @connection ||= Faraday.new(
          url: BASE_URL,
          headers: {
            'Authorization' => "Basic #{auth_header}",
            'Content-Type' => 'application/json'
          }
        ) do |faraday|
          faraday.adapter Faraday.default_adapter
          faraday.response :json
        end
      end

      def auth_header
        Base64.strict_encode64("#{@secret_key}:")
      end

      def get(path, params = {})
        response = connection.get(path, params)
        handle_response(response)
      end

      def post(path, body = {})
        response = connection.post(path, body.to_json)
        handle_response(response)
      end

      def handle_response(response)
        case response.status
        when 200..299
          response.body
        when 400..499
          error_body = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
          raise PaymentError, "클라이언트 오류: #{error_body['message'] || response.body}"
        when 500..599
          raise PaymentError, "서버 오류: #{response.status}"
        else
          raise PaymentError, "알 수 없는 오류: #{response.status}"
        end
      rescue JSON::ParserError
        raise PaymentError, '응답 파싱 오류'
      end
    end
  end
end
