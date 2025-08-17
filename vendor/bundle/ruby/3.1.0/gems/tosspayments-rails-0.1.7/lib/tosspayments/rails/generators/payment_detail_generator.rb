# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Tosspayments
  module Rails
    module Generators
      class PaymentDetailGenerator < ActiveRecord::Generators::Base
        source_root File.expand_path("templates", __dir__)

        argument :name, type: :string, default: "payment_detail"

        def create_migration
          migration_template "create_payment_details.rb", "db/migrate/create_payment_details.rb"
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
end 