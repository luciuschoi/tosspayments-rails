# frozen_string_literal: true

# 모킹을 통한 네트워크 없는 테스트 예제
# 실행: bundle exec ruby examples/mock_test.rb

require 'bundler/setup'
require 'webmock'
require 'tosspayments-rails'

# WebMock 활성화 (모든 HTTP 요청 차단)
WebMock.enable!

# 실시간 HTTP 연결 차단 (등록되지 않은 요청은 실패하도록)
WebMock.disable_net_connect!

puts "[tosspayments-rails] Mock Test => VERSION #{Tosspayments::Rails::VERSION}"

# 테스트용 설정
Tosspayments::Rails.configure do |config|
  config.client_key = 'test_ck_D5GePWvyJnrK0W0k'
  config.secret_key = 'test_gsk_GjLJoQ1aVZ2GyLBLq9ydVw6KYe2R'
  config.sandbox = true
end

puts "Mock 테스트 설정 완료 (sandbox=true)"

client = Tosspayments::Rails::Client.new
puts "클라이언트 초기화 완료 => #{client.class}"

# 테스트 데이터
test_payment_key = "test_payment_key_#{Time.now.to_i}"
test_order_id = "ORDER_#{Time.now.to_i}"

puts "\n=== 성공 시나리오 테스트 ==="

# 1. 결제 조회 성공 모킹
success_payment_data = {
  paymentKey: test_payment_key,
  orderId: test_order_id,
  orderName: "토스 티셔츠 외 2건",
  method: "카드",
  totalAmount: 15000,
  status: "DONE",
  approvedAt: Time.now.iso8601,
  card: {
    company: "현대카드",
    number: "433012******1234",
    installmentPlanMonths: 0,
    approveNo: "00000000",
    useCardPoint: false,
    cardType: "신용",
    ownerType: "개인",
    acquireStatus: "READY"
  },
  receipt: {
    url: "https://dashboard.tosspayments.com/receipt/3b33e5b0-5111-4a20-b2d1-93ee"
  }
}

WebMock.stub_request(:get, "https://api.tosspayments.com/v1/payments/#{test_payment_key}")
       .to_return(
         status: 200,
         body: success_payment_data.to_json,
         headers: { 'Content-Type' => 'application/json' }
       )

begin
  puts "결제 조회 API 호출 중..."
  payment = client.get_payment(test_payment_key)
  puts "✅ 성공: #{payment['orderName']}"
  puts "   상태: #{payment['status']}"
  puts "   금액: #{payment['totalAmount']}원"
  puts "   카드: #{payment.dig('card', 'company')} #{payment.dig('card', 'number')}"
rescue StandardError => e
  puts "❌ 오류: #{e.class}: #{e.message}"
end

puts "\n=== 실패 시나리오 테스트 ==="

# 2. 존재하지 않는 결제 조회 (404 에러)
invalid_payment_key = "invalid_payment_key"
error_response = {
  code: "NOT_FOUND_PAYMENT",
  message: "존재하지 않는 결제 정보 입니다."
}

WebMock.stub_request(:get, "https://api.tosspayments.com/v1/payments/#{invalid_payment_key}")
       .to_return(
         status: 404,
         body: error_response.to_json,
         headers: { 'Content-Type' => 'application/json' }
       )

begin
  puts "존재하지 않는 결제 조회 중..."
  payment = client.get_payment(invalid_payment_key)
  puts "✅ 성공: #{payment}"
rescue StandardError => e
  puts "✅ 예상된 오류: #{e.class}: #{e.message}"
end

puts "\n=== 결제 승인 테스트 ==="

# 3. 결제 승인 성공 모킹
confirm_response = success_payment_data.merge(
  status: "DONE",
  approvedAt: Time.now.iso8601
)

WebMock.stub_request(:post, "https://api.tosspayments.com/v1/payments/confirm")
       .to_return(
         status: 200,
         body: confirm_response.to_json,
         headers: { 'Content-Type' => 'application/json' }
       )

begin
  puts "결제 승인 API 호출 중..."
  confirmed_payment = client.confirm_payment(
    payment_key: test_payment_key,
    order_id: test_order_id,
    amount: 15000
  )
  puts "✅ 결제 승인 성공: #{confirmed_payment['orderName']}"
  puts "   승인 시간: #{confirmed_payment['approvedAt']}"
rescue StandardError => e
  puts "❌ 오류: #{e.class}: #{e.message}"
end

puts "\n=== 결제 취소 테스트 ==="

# 4. 결제 취소 성공 모킹
cancel_response = success_payment_data.merge(
  status: "CANCELED",
  canceledAt: Time.now.iso8601,
  cancels: [
    {
      cancelAmount: 15000,
      cancelReason: "고객 변심",
      canceledAt: Time.now.iso8601,
      receiptKey: "cancel_receipt_key"
    }
  ]
)

WebMock.stub_request(:post, "https://api.tosspayments.com/v1/payments/#{test_payment_key}/cancel")
       .to_return(
         status: 200,
         body: cancel_response.to_json,
         headers: { 'Content-Type' => 'application/json' }
       )

begin
  puts "결제 취소 API 호출 중..."
  canceled_payment = client.cancel_payment(
    payment_key: test_payment_key,
    cancel_reason: "고객 변심"
  )
  puts "✅ 결제 취소 성공: #{canceled_payment['status']}"
  puts "   취소 시간: #{canceled_payment['canceledAt']}"
rescue StandardError => e
  puts "❌ 오류: #{e.class}: #{e.message}"
end

puts "\n=== 네트워크 오류 시나리오 테스트 ==="

# 5. 네트워크 타임아웃 모킹
timeout_payment_key = "timeout_payment_key"

WebMock.stub_request(:get, "https://api.tosspayments.com/v1/payments/#{timeout_payment_key}")
       .to_timeout

begin
  puts "네트워크 타임아웃 테스트 중..."
  payment = client.get_payment(timeout_payment_key)
  puts "✅ 성공: #{payment}"
rescue StandardError => e
  puts "✅ 예상된 타임아웃 오류: #{e.class}: #{e.message}"
end

# WebMock 비활성화
WebMock.disable!

puts "\n🎉 모든 Mock 테스트 완료!"
puts "네트워크 연결 없이 TossPayments API 동작 검증 완료"
