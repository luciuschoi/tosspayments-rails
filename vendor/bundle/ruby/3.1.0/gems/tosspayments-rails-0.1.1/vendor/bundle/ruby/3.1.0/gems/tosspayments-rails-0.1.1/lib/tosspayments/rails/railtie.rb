# frozen_string_literal: true

module Tosspayments
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "tosspayments.configure" do |app|
        Tosspayments::Rails.configure do |config|
          rails_credentials = app.credentials
          
          if rails_credentials.tosspayments.present?
            config.client_key = rails_credentials.tosspayments[:client_key]
            config.secret_key = rails_credentials.tosspayments[:secret_key]
            config.sandbox = rails_credentials.tosspayments[:sandbox] != false
          end
        end
      end

      config.to_prepare do
        # Load helpers and other components safely
        begin
          if defined?(ActionController::Base) && defined?(Tosspayments::Rails::ControllerHelpers)
            ActionController::Base.include Tosspayments::Rails::ControllerHelpers
          end
          
          if defined?(ActionView::Base) && defined?(Tosspayments::Rails::ViewHelpers)
            ActionView::Base.include Tosspayments::Rails::ViewHelpers
          end
        rescue NameError => e
          Rails.logger.warn "토스페이먼츠 헬퍼 로딩 실패: #{e.message}"
        end
      end

    end
  end
end