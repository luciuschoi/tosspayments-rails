# frozen_string_literal: true

require "digest"

module Tosspayments
  module Rails
    class WebhookVerifier
      def initialize(secret_key = nil)
        @secret_key = secret_key || Tosspayments::Rails.configuration.secret_key
      end

      # 토스페이먼츠 웹훅 서명 검증
      # 실제 토스페이먼츠에서 제공하는 서명 검증 방식에 따라 구현해야 합니다
      def verify_signature(payload, signature)
        # 예시 구현 - 실제로는 토스페이먼츠 문서의 서명 검증 방식을 따라야 합니다
        expected_signature = generate_signature(payload)
        secure_compare(signature, expected_signature)
      end

      private

      def generate_signature(payload)
        # 실제 구현에서는 토스페이먼츠의 서명 생성 방식을 따라야 합니다
        Digest::SHA256.hexdigest("#{@secret_key}#{payload}")
      end

      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack("C*")
        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res == 0
      end
    end
  end
end