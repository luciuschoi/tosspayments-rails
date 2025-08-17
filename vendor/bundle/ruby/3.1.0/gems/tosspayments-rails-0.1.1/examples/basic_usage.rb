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
client_key = ENV['TOSSPAY_CLIENT_KEY']
secret_key = ENV['TOSSPAY_SECRET_KEY']
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

# 선택적으로 실제 API를 호출할 수 있습니다. (RUN_API=1, DUMMY_PAYMENT_KEY 필요)
# 주의: 실제 호출 시 네트워크가 필요하며, 유효한 키가 없으면 당연히 실패합니다.
if ENV['RUN_API'] == '1'
  payment_key = ENV['DUMMY_PAYMENT_KEY']
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
end

puts 'Done.'

