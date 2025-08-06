# frozen_string_literal: true

require "rails/generators"

module Tosspayments
  class PaymentDetailGenerator < ::Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)
    
    desc "토스페이먼츠 결제 상세 정보 저장을 위한 PaymentDetail 모델을 생성합니다."

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
      empty_directory "app/views/payment_details"
      template "index.html.erb", "app/views/payment_details/index.html.erb"
      template "show.html.erb", "app/views/payment_details/show.html.erb"
    end

    def add_routes
      route <<~RUBY
        # 토스페이먼츠 결제 상세 정보 라우트
        resources :payment_details, only: [:index, :show] do
          collection do
            get :statistics
          end
        end
      RUBY
    end

    def show_readme
      readme "PAYMENT_DETAIL_README" if behavior == :invoke
    end
  end
end 