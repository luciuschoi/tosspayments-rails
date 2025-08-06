# frozen_string_literal: true

require "zeitwerk"
require "faraday"

begin
  require "rails"
rescue LoadError
  # Rails가 없어도 기본 기능은 동작하도록 함
end

loader = Zeitwerk::Loader.for_gem
loader.setup

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

# Rails integration
if defined?(::Rails::Railtie)
  require "tosspayments/rails/railtie"
end
