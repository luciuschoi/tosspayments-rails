# frozen_string_literal: true

# 간단한 사용 예제: gem이 정상적으로 로드되는지와 기본 객체 초기화를 확인합니다.
# 실행: bundle exec ruby examples/basic_usage.rb

require 'bundler/setup'
require 'tosspayments-rails'

puts "[tosspayments-rails] VERSION => #{Tosspayments::Rails::VERSION}"

# 환경변수로 설정을 주입할 수 있습니다. (실서비스 키는 절대 출력/로그하지 마세요)
# - TOSSPAY_CLIENT_KEY
# - TOSSPAY_SECRET_KEY
# - TOSSPAY_SANDBOX (기본: true)
client_key = ENV.fetch('TOSSPAY_CLIENT_KEY', nil)
secret_key = ENV.fetch('TOSSPAY_SECRET_KEY', nil)
sandbox    = (ENV['TOSSPAY_SANDBOX'] || 'true') == 'true'

# 설정 블록 (키가 없더라도 블록 실행은 안전합니다)
Tosspayments::Rails.configure do |config|
  config.client_key = client_key if client_key && !client_key.empty?
  config.secret_key = secret_key if secret_key && !secret_key.empty?
  config.sandbox    = sandbox
end

puts "Configured (sandbox=#{sandbox})"

# 비밀키가 없으면 네트워크 초기화를 건너뜁니다(기본 실행을 안전하게 유지)
if secret_key.nil? || secret_key.empty?
  warn 'SECRET KEY가 없어 클라이언트 초기화를 건너뜁니다. 실행 전 환경변수 TOSSPAY_SECRET_KEY를 설정하세요.'
  puts 'Done.'
  exit 0
end

# 네트워크 호출 없이 클라이언트를 초기화만 합니다.
client = Tosspayments::Rails::Client.new
puts "Client initialized => #{client.class}"

# 선택적으로 실제 API를 호출하거나 모킹 테스트를 실행할 수 있습니다.
# RUN_API=1: 실제 API 호출 (DUMMY_PAYMENT_KEY 필요)
# RUN_MOCK=1: 모킹 테스트 (네트워크 불필요)
if ENV['RUN_API'] == '1'
  payment_key = ENV.fetch('DUMMY_PAYMENT_KEY', nil)
  if payment_key.nil? || payment_key.empty?
    warn 'RUN_API=1 이지만 DUMMY_PAYMENT_KEY가 지정되지 않아 API 호출을 건너뜁니다.'
  else
    begin
      puts "Calling get_payment(#{'*' * 8}) ..."
      payment = client.get_payment(payment_key)
      puts "Payment fetched: #{payment.respond_to?(:keys) ? payment.keys : payment.class}"
    rescue StandardError => e
      warn "API call failed (expected in demo without valid keys): #{e.class}: #{e.message}"
    end
  end
elsif ENV['RUN_MOCK'] == '1'
  puts "\n=== 모킹 테스트 모드 ==="
  puts "네트워크 없이 API 테스트를 실행합니다."
  puts "상세한 모킹 테스트는 다음 명령어로 실행하세요:"
  puts "bundle exec ruby examples/mock_test.rb"
  
  begin
    require 'webmock'
    WebMock.enable!
    
    # 간단한 모킹 테스트
    test_payment_key = 'test_payment_key_demo'
    mock_response = {
      paymentKey: test_payment_key,
      orderId: 'ORDER_DEMO',
      orderName: '테스트 상품',
      method: '카드',
      totalAmount: 15000,
      status: 'DONE'
    }
    
    WebMock.stub_request(:get, "https://api.tosspayments.com/v1/payments/#{test_payment_key}")
           .to_return(
             status: 200,
             body: mock_response.to_json,
             headers: { 'Content-Type' => 'application/json' }
           )
    
    puts "Mock API 호출 중..."
    payment = client.get_payment(test_payment_key)
    puts "✅ Mock 테스트 성공: #{payment[:orderName]}"
    puts "   상태: #{payment[:status]}"
    puts "   금액: #{payment[:totalAmount]}원"
    
    WebMock.disable!
  rescue LoadError
    warn "webmock gem이 필요합니다. 설치: bundle install"
  rescue StandardError => e
    warn "Mock 테스트 실패: #{e.class}: #{e.message}"
  end
end

puts 'Done.'
