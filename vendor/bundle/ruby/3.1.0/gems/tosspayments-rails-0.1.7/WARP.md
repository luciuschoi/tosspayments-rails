# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

- 이 저장소는 Rails 애플리케이션에서 토스페이먼츠 결제 서비스를 쉽게 통합하기 위한 Ruby gem입니다.
- 사용자는 rbenv와 Bundler를 선호합니다. 모든 Ruby 명령은 Bundler 컨텍스트에서 실행하세요.

1) 자주 쓰는 명령어(빌드/설치/개발/테스트)

- 의존성 설치
  - bundle install
  - 초깃값: bin/setup

- 콘솔
  - bundle exec bin/console

- 빌드/설치/릴리스 (Bundler의 gem_tasks 사용)
  - 빌드: bundle exec rake build
  - 로컬 설치: bundle exec rake install
  - 릴리스: bundle exec rake release

- 예제/개발용 실행 (DEVELOPMENT.md 권고: 항상 bundle exec 사용)
  - 예제: bundle exec ruby examples/basic_usage.rb
  - Rails 통합 가이드: examples/rails_integration_example.md 참조(문서)

- 테스트(스크립트 기반)
  - 전체(샘플): bundle exec ruby test_gem.rb
  - 단일 테스트 파일: bundle exec ruby simple_test.rb
  - 특정 스크립트만 실행하고자 할 때: bundle exec ruby <path/to/script>.rb

- Rails 앱 통합 제너레이터
  - 설치(초기 설정/컨트롤러/뷰/라우트): rails generate tosspayments:install
  - 상세 결제정보 기능 추가: rails generate tosspayments:payment_detail

2) 아키텍처 개요(큰 그림)

- 진입점 및 설정
  - lib/tosspayments/rails.rb: 라이브러리 진입점과 설정 로딩.
  - lib/tosspayments/rails/version.rb: 버전 관리.
  - Railtie: lib/tosspayments/rails/railtie.rb에서 Rails 환경에 훅을 연결(뷰/컨트롤러 헬퍼 등록 등 조건부 로딩).
  - 구성(Configure): Tosspayments::Rails.configure 블록으로 client_key/secret_key/sandbox 등을 설정. Rails credentials 또는 환경변수에서 값을 주입하여 사용하도록 설계.

- 핵심 기능 모듈
  - Client: lib/tosspayments/rails/client.rb
    - Faraday 2.x + faraday-net_http로 토스페이먼츠 API 호출 래핑.
    - 결제 승인(confirm), 조회(get), 취소(cancel) 등 고수준 메서드 제공.
  - ControllerHelpers: lib/tosspayments/rails/controller_helpers.rb
    - 컨트롤러에서 결제 승인/취소/조회 흐름을 단순화하는 헬퍼 메서드 제공.
  - ViewHelpers: lib/tosspayments/rails/view_helpers.rb
    - SDK 로드 스니펫, 결제위젯 초기화/요청 스크립트, 기본 결제 폼 등 View 단 헬퍼 제공.
  - WebhookVerifier: lib/tosspayments/rails/webhook_verifier.rb
    - 웹훅 요청을 검증하기 위한 유틸리티 제공.
  - TestHelpers: lib/tosspayments/rails/test_helpers.rb
    - 개발/테스트 중에 사용할 수 있는 헬퍼들 제공.

- Rails 통합(제너레이터 기반)
  - 설치 제너레이터: lib/generators/tosspayments/install_generator.rb
    - config/initializers/tosspayments.rb, PaymentsController, 뷰, 라우팅 템플릿을 앱에 추가.
  - 상세 결제정보 제너레이터: lib/tosspayments/rails/generators/payment_detail_generator.rb 및 templates
    - PaymentDetail 마이그레이션/모델/컨트롤러/뷰 템플릿 제공.
    - PaymentDetail 모델은 상태/결제수단별 스코프, 통계 조회 등 고급 쿼리/유틸리티를 제공(README 참고).

- 의존성 및 호환성
  - gemspec: rails >= 7.0, faraday ~> 2.0, faraday-net_http ~> 3.0 의존.
  - Ruby >= 3.1.2. DEVELOPMENT.md에 따라 RubyGems/Bundler 호환 이슈를 피하기 위해 항상 bundle exec로 실행.

- 예제 및 문서
  - README.md: 설치/설정(rails credentials, 제너레이터), 컨트롤러/뷰/브랜드페이/헬퍼 사용법, PaymentDetail 스코프/메서드 요약.
  - examples/rails_integration_example.md: 실제 Rails 앱에서의 엔드투엔드 통합 예시(컨트롤러/뷰/라우트/웹훅/모델/마이그레이션 샘플).
  - DEVELOPMENT.md: bundle exec 강제 권장, 로컬 require 방식 등 개발 팁.

3) 작업 시 유의사항

- Ruby/Bundle 실행은 사용자의 선호에 따라 rbenv 환경에서 bundle exec로 일관되게 실행하세요.
- Rakefile은 bundler/gem_tasks만 로드합니다. 별도의 lint/테스트 Rake 태스크는 정의되어 있지 않습니다.
- 린트 설정(RuboCop 등) 파일이 포함되어 있지 않습니다. 린팅이 필요하면 프로젝트 정책에 맞춰 도입을 제안하세요(자동 실행 명령은 현재 없음).
- Rails 앱 통합 시 README의 credentials 키와 콜백/웹훅 URL 설정을 우선 확인하세요.

