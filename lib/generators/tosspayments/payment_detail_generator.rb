# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module Tosspayments
  # Generates PaymentDetail model, migration, controller, views & routes.
  class PaymentDetailGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    # Template directory ONLY for PaymentDetail artifacts (model, controller, views, migration, README)
    # Install generator templates live in lib/generators/tosspayments/payment_detail/templates
    source_root File.expand_path('payment_detail/templates', __dir__)

    class_option :statistics, type: :boolean, default: true, desc: 'statistics 라우트 및 액션 안내 포함'

    desc '토스페이먼츠 결제 상세 정보 저장을 위한 PaymentDetail 모델/마이그레이션/뷰를 생성합니다.'

    # Rails 8+ compatible unique migration number
    def self.next_migration_number(dirname)
      if ::ActiveRecord::Migration.respond_to?(:next_migration_number)
        ::ActiveRecord::Migration.next_migration_number(current_migration_number(dirname) + 1)
      else
        Time.now.utc.strftime('%Y%m%d%H%M%S')
      end
    end

    def create_payment_details_migration
      migration_template 'create_payment_details.rb', 'db/migrate/create_payment_details.rb'
    end

    def create_model
      template 'payment_detail.rb', 'app/models/payment_detail.rb'
    end

    def create_controller
      template 'payment_details_controller.rb', 'app/controllers/payment_details_controller.rb'
    end

    def create_views
      empty_directory 'app/views/payment_details'
      %w[index show].each do |view|
        copy_file "#{view}.html.erb", "app/views/payment_details/#{view}.html.erb"
      end
    end

    def add_routes
      if options[:statistics]
        route <<~RUBY
          # 토스페이먼츠 결제 상세 정보 라우트 (statistics 포함)
          resources :payment_details, only: [:index, :show] do
            collection { get :statistics }
          end
        RUBY
      else
        route <<~RUBY
          # 토스페이먼츠 결제 상세 정보 라우트
          resources :payment_details, only: [:index, :show]
        RUBY
      end
    end

    def show_readme
      readme 'PAYMENT_DETAIL_README'
    rescue StandardError
      # 템플릿 미존재시 실패 방지
    end

    private

    def migration_version
      if ::Rails.version.start_with?('5.')
        '[5.0]'
      elsif ::Rails.version.start_with?('6.')
        '[6.0]'
      elsif ::Rails.version.start_with?('7.')
        '[7.0]'
      elsif ::Rails.version.start_with?('8.')
        '[8.0]'
      else
        ''
      end
    end
  end
end
