# frozen_string_literal: true

if defined?(Rails)
  require "rails/generators"

  module Tosspayments
    class PaymentDetailGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_migration
        generate "migration", "CreatePaymentDetails"
      end

      def create_model
        template "payment_detail.rb", "app/models/payment_detail.rb"
      end

      def create_controller
        template "payment_details_controller.rb", "app/controllers/payment_details_controller.rb"
      end

      def create_views
        template "index.html.erb", "app/views/payment_details/index.html.erb"
        template "show.html.erb", "app/views/payment_details/show.html.erb"
      end

      def add_routes
        route "resources :payment_details, only: [:index, :show]"
      end
    end
  end
end
