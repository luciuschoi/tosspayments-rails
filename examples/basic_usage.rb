# frozen_string_literal: true

# 토스페이먼츠 Rails gem 기본 사용 예제

# 로컬 개발 환경에서는 상대 경로로 로드
require_relative "../lib/tosspayments/rails"

# 1. 설정 예제
Tosspayments::Rails.configure do |config|
  config.client_key = "test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq"
  config.secret_key = "test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R"
  config.sandbox = true
end

# 2. API 클라이언트 사용 예제
client = Tosspayments::Rails::Client.new

# 결제 승인 예제
begin
  result = client.confirm_payment(
    payment_key: "payment_key_from_frontend",
    order_id: "ORDER_20231201_001",
    amount: 15000
  )
  
  puts "결제 승인 성공: #{result}"
rescue Tosspayments::Rails::PaymentError => e
  puts "결제 승인 실패: #{e.message}"
end

# 결제 조회 예제
begin
  payment = client.get_payment("payment_key_from_frontend")
  puts "결제 정보: #{payment}"
rescue Tosspayments::Rails::PaymentError => e
  puts "결제 조회 실패: #{e.message}"
end

# 결제 취소 예제
begin
  result = client.cancel_payment(
    payment_key: "payment_key_from_frontend",
    cancel_reason: "고객 요청"
  )
  
  puts "결제 취소 성공: #{result}"
rescue Tosspayments::Rails::PaymentError => e
  puts "결제 취소 실패: #{e.message}"
end

# 3. 브랜드페이 예제
begin
  # Access Token 발급
  token_result = client.create_brandpay_access_token(
    code: "authorization_code_from_frontend",
    customer_key: "customer_unique_id"
  )
  
  puts "브랜드페이 토큰 발급 성공: #{token_result}"
  
  # 결제수단 조회
  payment_methods = client.get_brandpay_payment_methods("customer_unique_id")
  puts "브랜드페이 결제수단: #{payment_methods}"
rescue Tosspayments::Rails::PaymentError => e
  puts "브랜드페이 API 호출 실패: #{e.message}"
end