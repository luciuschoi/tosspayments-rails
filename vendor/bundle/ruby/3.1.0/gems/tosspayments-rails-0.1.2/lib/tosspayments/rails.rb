# frozen_string_literal: true

require "faraday"

# Rails는 필요할 때만 로드
rails_available = false
begin
  require "rails"
  rails_available = defined?(::Rails) && defined?(::Rails::Railtie)
rescue LoadError
  # Rails가 없어도 기본 기능은 동작하도록 함
  rails_available = false
end

# 필요한 파일들을 명시적으로 require
require_relative "rails/client"
require_relative "rails/webhook_verifier"
require_relative "rails/controller_helpers"
require_relative "rails/view_helpers"
require_relative "rails/test_helpers"

module Tosspayments
  module Rails
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class PaymentError < Error; end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end

    class Configuration
      attr_accessor :client_key, :secret_key, :sandbox

      def initialize
        @sandbox = true
      end

      def base_url
        sandbox ? "https://api.tosspayments.com" : "https://api.tosspayments.com"
      end
    end
  end
end

# Rails integration - Rails 환경에서만 railtie 로드
if defined?(::Rails) && defined?(::Rails::Railtie)
  begin
    require "tosspayments/rails/railtie"
  rescue LoadError => e
    # Rails 환경이 완전하지 않은 경우 무시
    warn "Warning: Could not load railtie: #{e.message}" if $VERBOSE
  end
end
