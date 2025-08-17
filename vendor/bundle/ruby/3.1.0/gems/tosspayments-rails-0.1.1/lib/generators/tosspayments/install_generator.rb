# frozen_string_literal: true

if defined?(Rails)
  require "rails/generators"

  module Tosspayments
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      
      desc "토스페이먼츠 Rails gem을 설치하고 기본 설정을 생성합니다."

      def create_initializer
        template "initializer.rb", "config/initializers/tosspayments.rb"
      end

      def create_controller
        template "payments_controller.rb", "app/controllers/payments_controller.rb"
      end

      def create_views
        empty_directory "app/views/payments"
        template "new.html.erb", "app/views/payments/new.html.erb"
        template "success.html.erb", "app/views/payments/success.html.erb"
        template "fail.html.erb", "app/views/payments/fail.html.erb"
      end

      def add_routes
        route <<~RUBY
          # 토스페이먼츠 결제 관련 라우트
          resources :payments, only: [:new, :create] do
            collection do
              get :success
              get :fail
              post :webhook
            end
          end
        RUBY
      end

      def show_readme
        readme "README" if behavior == :invoke
      end

      private

      def client_key_placeholder
        "test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq"
      end

      def secret_key_placeholder  
        "test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R"
      end
    end
  end
end
