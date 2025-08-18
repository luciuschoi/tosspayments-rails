# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module Tosspayments
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    # install 전용 템플릿 디렉터리
    source_root File.expand_path('templates', __dir__)

    # Migration 번호 생성을 위한 클래스 메서드
    def self.next_migration_number(dirname)
      next_migration_number = current_migration_number(dirname) + 1
      ActiveRecord::Migration.next_migration_number(next_migration_number)
    end

    # 옵션 추가
    class_option :skip_assets, type: :boolean, default: false, desc: '스타일시트(tosspayments.css) 및 자동 등록을 건너뜁니다.'
    class_option :skip_stimulus, type: :boolean, default: false, desc: 'Stimulus 컨트롤러 파일 및 자동 등록을 건너뜁니다.'

    desc '토스페이먼츠 Rails gem을 설치하고 기본 설정을 생성합니다.'

    def create_initializer
      template 'initializer.rb', 'config/initializers/tosspayments.rb'
    end

    def create_payments_migration
      # 기존 create_payments.rb 마이그레이션 파일이 존재하는 경우 제거
      existing_migrations = Dir["db/migrate/*create_payments.rb"]
      existing_migrations.each do |migration_file|
        remove_file migration_file
        say "기존 마이그레이션 파일 제거: #{migration_file}", :yellow
      end

      # Rails::Generators::Migration#migration_template requires source and destination (2..3 args)
      # Always write to db/migrate/create_payments.rb so Rails 8에서도 정상 동작
      migration_template 'create_payments.rb', 'db/migrate/create_payments.rb'
      say "새로운 마이그레이션 파일 생성: db/migrate/create_payments.rb", :green
    end

    def create_model
      template 'payment.rb', 'app/models/payment.rb'
    end

    def create_controller
      template 'payments_controller.rb', 'app/controllers/payments_controller.rb'
    end

    def create_views
      empty_directory 'app/views/payments'
      %w[new success fail].each do |view|
        template "#{view}.html.erb", "app/views/payments/#{view}.html.erb"
      end
    end

    def create_stimulus_controller
      return if options[:skip_stimulus]

      empty_directory 'app/javascript/controllers'
      template 'tosspayments_controller.js', 'app/javascript/controllers/tosspayments_controller.js'

      say '[tosspayments] Stimulus controller 추가: app/javascript/controllers/tosspayments_controller.js', :green
      say "controllers/index.js 에 'application.register(\"tosspayments\", TosspaymentsController)' 를 추가했는지 확인하세요.",
          :yellow
    rescue StandardError => e
      say "Stimulus controller 생성 중 오류: #{e.message}", :red
    end

    def create_stylesheet
      return if options[:skip_assets]

      empty_directory 'app/assets/stylesheets'
      copy_file 'tosspayments.css', 'app/assets/stylesheets/tosspayments.css'
      say '[tosspayments] Stylesheet 추가: app/assets/stylesheets/tosspayments.css', :green
      say 'application.css (또는 application.(scss|sass)) 에서 require 또는 @import 하세요.', :yellow
    rescue StandardError => e
      say "Stylesheet 생성 중 오류: #{e.message}", :red
    end

    # Stimulus index 파일에 tosspayments 컨트롤러 등록 (필요 시)
    def register_stimulus
      return if options[:skip_stimulus]

      index_path = 'app/javascript/controllers/index.js'
      controller_import = 'import TosspaymentsController from "./tosspayments_controller"'
      register_line = 'application.register("tosspayments", TosspaymentsController)'

      return unless File.exist?(index_path)

      content = File.read(index_path)

      # eagerLoadControllersFrom 사용 시 _controller.js 네이밍으로 자동로드되므로 안내만 출력
      if content.include?('eagerLoadControllersFrom(')
        say '[tosspayments] Stimulus: eagerLoadControllersFrom 감지되어 자동 로드됩니다.', :blue
        return
      end

      # 이미 등록된 경우 (application.register("tosspayments", ...)) import 누락만 추가
      if content.match(/application\.register\(\s*"tosspayments"/)
        if content.include?(controller_import)
          say '[tosspayments] Stimulus index.js 이미 tosspayments 등록됨', :blue
        else
          content = "#{controller_import}\n#{content}"
          File.write(index_path, content)
          say '[tosspayments] 기존 등록 발견 – import 추가 완료', :green
        end
        return
      end

      changed = false
      unless content.include?(controller_import)
        content = "#{controller_import}\n#{content}"
        changed = true
      end
      unless content.include?(register_line)
        content << "\n#{register_line}\n"
        changed = true
      end

      if changed
        File.write(index_path, content)
        say '[tosspayments] Stimulus index.js 에 tosspayments 컨트롤러 등록 완료', :green
      else
        say '[tosspayments] Stimulus index.js 이미 등록됨', :blue
      end
    rescue StandardError => e
      say "Stimulus 등록 중 오류: #{e.message}", :red
    end

    # application stylesheet 에 tosspayments.css 포함 시도 (idempotent)
    def register_stylesheet
      return if options[:skip_assets]

      candidates = %w[
        app/assets/stylesheets/application.scss
        app/assets/stylesheets/application.sass
        app/assets/stylesheets/application.css
      ]

      target = candidates.find { |p| File.exist?(p) }
      unless target
        say '[tosspayments] application.(s)css 파일을 찾지 못해 자동 등록을 건너뜁니다.', :yellow
        return
      end

      content = File.read(target)

      if target.end_with?('.scss', '.sass')
        if content.include?('@import "tosspayments"') || content.include?('@use "tosspayments"')
          say '[tosspayments] Stylesheet 이미 import 됨', :blue
          return
        end
        File.open(target, 'a') do |f|
          f.puts ''
          f.puts '@import "tosspayments";'
        end
        say "[tosspayments] #{File.basename(target)} 에 @import 추가", :green
      else
        # .css (Sprockets manifest) – require 구문 또는 require_tree 검사
        if content =~ /require_tree/ || content.include?('require_self')
          say '[tosspayments] require_tree 사용중 - tosspayments.css 자동 포함 예상', :blue
          return
        end
        if content.include?('require tosspayments')
          say '[tosspayments] Stylesheet 이미 require 됨', :blue
          return
        end

        # /* ... */ 블록 안에 삽입 시도
        if content =~ %r{/\*.*\*/\s*$}m
          new_content = content.sub(%r{(/\*[^*]*\*+(?:[^/*][^*]*\*+)*)(\*/)}m) do |m|
            header = Regexp.last_match(1)
            closing = Regexp.last_match(2)
            if header.include?('require tosspayments')
              m
            else
              "#{header}\n *= require tosspayments\n#{closing}"
            end
          end
          unless new_content == content
            File.write(target, new_content)
            say "[tosspayments] #{File.basename(target)} manifest 에 require 추가", :green
            return
          end
        end

        # Fallback append
        File.open(target, 'a') do |f|
          f.puts ''
          f.puts '/*= require tosspayments */'
        end
        say "[tosspayments] #{File.basename(target)} 끝에 require 추가", :green
      end
    rescue StandardError => e
      say "Stylesheet 자동 등록 중 오류: #{e.message}", :red
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
      readme 'README' if behavior == :invoke
    rescue StandardError
      # README 템플릿 미존재시 조용히 무시
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

    def client_key_placeholder
      'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq'
    end

    def secret_key_placeholder
      'test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R'
    end
  end
end
