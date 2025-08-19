# frozen_string_literal: true

require "test_helper"

class Tosspayments::Rails::ClientTest < Minitest::Test
  def setup
    @client = Tosspayments::Rails::Client.new(
      secret_key: 'test_secret_key'
    )
  end

  def test_client_initialization
    assert_equal 'test_secret_key', @client.instance_variable_get(:@secret_key)
  end

  def test_client_responds_to_payment_methods
    assert_respond_to @client, :confirm_payment
    assert_respond_to @client, :get_payment
    assert_respond_to @client, :cancel_payment
  end

  def test_configuration_error_without_keys
    # 설정을 비워서 secret_key가 없는 상태로 만듦
    original_secret_key = Tosspayments::Rails.configuration.secret_key
    Tosspayments::Rails.configuration.secret_key = nil
    
    assert_raises Tosspayments::Rails::ConfigurationError do
      Tosspayments::Rails::Client.new
    end
  ensure
    # 원래 설정 복원
    Tosspayments::Rails.configuration.secret_key = original_secret_key
  end
end