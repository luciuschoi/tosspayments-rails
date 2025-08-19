# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "tosspayments/rails"
require "minitest/autorun"

# Mock Rails environment for testing
module MockRails
  def self.env
    @env ||= ActiveSupport::StringInquirer.new("test")
  end

  def self.application
    @application ||= Struct.new(:credentials).new(
      Struct.new(:tosspayments).new(
        { client_key: 'test_client_key', secret_key: 'test_secret_key' }
      )
    )
  end
end

# Configure test environment
Tosspayments::Rails.configure do |config|
  config.client_key = 'test_client_key'
  config.secret_key = 'test_secret_key'
  config.sandbox = true
end