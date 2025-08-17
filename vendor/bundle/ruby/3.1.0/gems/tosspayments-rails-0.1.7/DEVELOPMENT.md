# 개발 환경에서의 LoadError 해결 방법

## 문제 상황

Ruby 3.1.2 환경에서 RubyGems와 Bundler 간의 호환성 문제로 인해 다음과 같은 에러가 발생할 수 있습니다:

```
uninitialized constant Gem::BundlerVersionFinder (NameError)
CRITICAL: RUBYGEMS_ACTIVATION_MONITOR.owned?
```

## 해결 방법

### 1. Bundler 사용 (권장)

개발 환경에서는 항상 `bundle exec`를 사용하여 실행하세요:

```bash
# 올바른 방법
bundle exec ruby examples/basic_usage.rb
bundle exec ruby test_gem.rb

# 직접 실행 시 에러 발생 가능
ruby examples/basic_usage.rb  # 에러 발생 가능
```

### 2. 로컬 개발 환경 설정

예제 파일들은 로컬 라이브러리를 직접 require하도록 구성되어 있습니다:

```ruby
# examples/basic_usage.rb
require_relative "../lib/tosspayments/rails"  # 로컬 파일 사용
```

### 3. 실제 프로덕션 사용

실제 Rails 애플리케이션에서는 Gemfile에 추가하여 사용:

```ruby
# Gemfile
gem 'tosspayments-rails'

# 그 후
bundle install

# 코드에서 사용
require 'tosspayments/rails'
```

## 기술적 원인

이 문제는 다음과 같은 이유로 발생합니다:

1. **RubyGems 3.3.7과 Bundler 2.6.9 간의 호환성 문제**
2. **`Gem::BundlerVersionFinder` 클래스가 정의되지 않는 환경 이슈**
3. **Faraday gem 로딩 시 발생하는 의존성 충돌**

## 해결 과정에서 적용된 수정사항

1. **Zeitwerk 의존성 제거**: 자동 로딩 대신 수동 require 방식으로 변경
2. **ActiveSupport 메서드 의존성 제거**: `blank?`, `present?` 등을 표준 Ruby 메서드로 대체
3. **Rails 환경 체크 개선**: Rails가 없는 환경에서도 안전하게 동작
4. **조건부 railtie 로딩**: Rails 환경에서만 railtie 로드

## 권장사항

- **개발 중**: 항상 `bundle exec` 사용
- **테스트**: `bundle exec ruby test_gem.rb`
- **예제 실행**: `bundle exec ruby examples/basic_usage.rb`
- **프로덕션**: Bundler가 자동으로 의존성 관리
