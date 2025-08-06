#!/usr/bin/env ruby
# frozen_string_literal: true

# Gem 기본 로딩 테스트

require_relative 'lib/tosspayments/rails'

puts "🚀 토스페이먼츠 Rails gem 테스트 시작"
puts "Ruby 버전: #{RUBY_VERSION}"

# 1. 기본 모듈 로딩 테스트
puts "\n1. 모듈 로딩 테스트"
puts "✅ Tosspayments::Rails 모듈 로드됨" if defined?(Tosspayments::Rails)
puts "✅ Configuration 클래스 로드됨" if defined?(Tosspayments::Rails::Configuration)
puts "✅ Client 클래스 로드됨" if defined?(Tosspayments::Rails::Client)

# 2. 설정 테스트
puts "\n2. 설정 테스트"
begin
  Tosspayments::Rails.configure do |config|
    config.client_key = "test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq"
    config.secret_key = "test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R"
    config.sandbox = true
  end
  
  config = Tosspayments::Rails.configuration
  puts "✅ 설정 완료"
  puts "   - Client Key: #{config.client_key[0..20]}..."
  puts "   - Secret Key: #{config.secret_key[0..20]}..."
  puts "   - Sandbox: #{config.sandbox}"
  puts "   - Base URL: #{config.base_url}"
rescue => e
  puts "❌ 설정 실패: #{e.message}"
end

# 3. 클라이언트 초기화 테스트
puts "\n3. 클라이언트 초기화 테스트"
begin
  client = Tosspayments::Rails::Client.new
  puts "✅ 클라이언트 초기화 성공"
rescue => e
  puts "❌ 클라이언트 초기화 실패: #{e.message}"
end

# 4. 헬퍼 모듈 로딩 테스트
puts "\n4. 헬퍼 모듈 로딩 테스트"
puts "✅ ControllerHelpers 로드됨" if defined?(Tosspayments::Rails::ControllerHelpers)
puts "✅ ViewHelpers 로드됨" if defined?(Tosspayments::Rails::ViewHelpers)
puts "✅ WebhookVerifier 로드됨" if defined?(Tosspayments::Rails::WebhookVerifier)
puts "✅ TestHelpers 로드됨" if defined?(Tosspayments::Rails::TestHelpers)

# 5. 에러 클래스 테스트
puts "\n5. 에러 클래스 테스트"
puts "✅ Error 클래스 로드됨" if defined?(Tosspayments::Rails::Error)
puts "✅ ConfigurationError 클래스 로드됨" if defined?(Tosspayments::Rails::ConfigurationError)
puts "✅ PaymentError 클래스 로드됨" if defined?(Tosspayments::Rails::PaymentError)

puts "\n🎉 모든 테스트 완료!"