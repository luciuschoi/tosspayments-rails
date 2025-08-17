# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module Tosspayments
  # Generates PaymentDetail model, migration, controller, views & routes.
  class PaymentDetailGenerator < ::Rails::Generators::Base
    include Rails::Generators::Migration

    # Template directory ONLY for PaymentDetail artifacts (model, controller, views, migration, README)
    # Install generator templates live in lib/generators/tosspayments/templates
    source_root File.expand_path('templates', __dir__)

    class_option :statistics, type: :boolean, default: true, desc: 'statistics 라우트 및 액션 안내 포함'

    desc '토스페이먼츠 결제 상세 정보 저장을 위한 PaymentDetail 모델/마이그레이션/뷰를 생성합니다.'

    # Simplified unique migration number
    def self.next_migration_number(dirname)
      if ::ActiveRecord::Base.timestamped_migrations
        Time.now.utc.strftime('%Y%m%d%H%M%S')
      else
        format('%03d', current_migration_number(dirname) + 1)
      end
    end

    def create_migration
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
        template "#{view}.html.erb", "app/views/payment_details/#{view}.html.erb"
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
  end
end
