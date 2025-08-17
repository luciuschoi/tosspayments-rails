# frozen_string_literal: true

require_relative 'lib/tosspayments/rails/version'

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.name = 'tosspayments-rails'
  spec.version = Tosspayments::Rails::VERSION
  spec.authors = ['Lucius Choi']
  spec.email = ['lucius.choi@gmail.com']

  spec.summary = '토스페이먼츠 온라인 결제 서비스를 위한 Rails gem'
  spec.description = '토스페이먼츠 API를 사용하여 Rails 애플리케이션에서 온라인 결제 기능을 쉽게 구현할 수 있는 gem입니다. Rails 7+ (및 Rails 8) 버전을 지원하며 Rails credentials를 통한 안전한 설정 관리를 제공합니다.' # rubocop:disable Layout/LineLength
  spec.homepage = 'https://github.com/luciuschoi/tosspayments-rails'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.2'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/luciuschoi/tosspayments-rails'
  spec.metadata['changelog_uri'] = 'https://github.com/luciuschoi/tosspayments-rails/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        # 불필요하거나 외부 의존 디렉터리는 제외하여 빌드 에러를 방지합니다.
        f.start_with?(*%w[
          bin/
          Gemfile
          .git
          .github/
          .gitignore
          .bundle/
          vendor/
          pkg/
          tmp/
          log/
          .ruby-lsp/
        ]) ||
        f.end_with?('.gem')
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'faraday-net_http', '~> 3.0'
  # Rails 7.x 및 8.x 지원 (9.0 미만)
  spec.add_dependency 'rails', '>= 7.0', '< 9.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
