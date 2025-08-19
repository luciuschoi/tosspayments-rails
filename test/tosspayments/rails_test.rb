# frozen_string_literal: true

require "test_helper"

class Tosspayments::RailsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Tosspayments::Rails::VERSION
  end

  def test_configuration
    assert_respond_to Tosspayments::Rails, :configuration
    assert_respond_to Tosspayments::Rails, :configure
  end

  def test_default_configuration
    config = Tosspayments::Rails::Configuration.new
    assert config.sandbox
    assert_equal 'https://api.tosspayments.com', config.base_url
  end

  def test_error_classes_exist
    assert defined?(Tosspayments::Rails::Error)
    assert defined?(Tosspayments::Rails::ConfigurationError)
    assert defined?(Tosspayments::Rails::PaymentError)
  end
end