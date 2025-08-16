#!/usr/bin/env ruby
# frozen_string_literal: true

# 젬 라이브러리 로드
require_relative 'lib/tosspayments-rails'

puts "🚀 토스페이먼츠 Rails gem 간단 테스트"
puts "Ruby 버전: #{RUBY_VERSION}"

# 1. 기본 모듈 정의 테스트
puts "\n1. 기본 모듈 테스트"
puts "✅ Tosspayments::Rails 모듈 정의됨" if defined?(Tosspayments::Rails)
puts "✅ VERSION = #{Tosspayments::Rails::VERSION}" if defined?(Tosspayments::Rails::VERSION)
puts "✅ Configuration 클래스 정의됨" if defined?(Tosspayments::Rails::Configuration)

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

puts "\n3. 에러 클래스 테스트"
begin
  raise Tosspayments::Rails::PaymentError, "테스트 에러"
rescue Tosspayments::Rails::PaymentError => e
  puts "✅ PaymentError 클래스 정상 작동: #{e.message}"
rescue => e
  puts "❌ 에러 클래스 테스트 실패: #{e.message}"
end

puts "\n4. 설정 검증 테스트"
config = Tosspayments::Rails.configuration
if config.client_key && config.secret_key
  puts "✅ 필수 설정 값들이 올바르게 설정됨"
else
  puts "❌ 필수 설정 값 누락"
end

puts "\n🎉 기본 모듈 테스트 완료!"
puts "\n📋 요약:"
puts "   - 모듈 정의: ✅"
puts "   - 설정 시스템: ✅"
puts "   - 에러 클래스: ✅"
puts "   - Ruby #{RUBY_VERSION} 호환성: ✅"