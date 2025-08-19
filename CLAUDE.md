# CLAUDE.md

이 파일은 Claude Code (claude.ai/code)가 이 저장소의 코드를 작업할 때 필요한 가이드를 제공합니다.

## 개발 명령어

### 빌드 및 테스트
```bash
# gem 빌드
bundle exec rake build

# 로컬에 빌드된 gem 설치
bundle exec rake install

# 기본 기능 테스트
bundle exec ruby examples/basic_usage.rb

# API 호출 테스트 (유효한 자격 증명 필요)
export TOSSPAY_SECRET_KEY=your_test_secret_key
export RUN_API=1
export DUMMY_PAYMENT_KEY=dummy_payment_key
bundle exec ruby examples/basic_usage.rb

# Mock 테스트 (네트워크 연결 불필요)
export RUN_MOCK=1
bundle exec ruby examples/basic_usage.rb

# 상세 Mock 테스트 (모든 시나리오)
bundle exec ruby examples/mock_test.rb
```

### Mock 테스트 기능
네트워크 연결 없이 TossPayments API 동작을 검증할 수 있는 모킹 테스트 기능을 제공합니다.

**장점**:
- 네트워크 연결 불필요
- 빠른 실행 속도
- 다양한 시나리오 테스트 (성공/실패/네트워크 오류)
- 실제 API 응답 형식 사용
- CI/CD 환경에서 안정적 테스트

**테스트 시나리오**:
- 결제 조회 성공/실패
- 결제 승인 처리
- 결제 취소 처리
- 네트워크 타임아웃 처리
- 404 에러 처리

**의존성**: `webmock` gem (개발/테스트 환경)

### 환경 요구사항
- 개발 환경에서 명령어 실행 시 항상 `bundle exec` 사용
- Ruby 3.1.2+ 필요
- Rails 7.0+ 호환 (Rails 8.x 지원)

### 개발 환경 이슈
코드베이스는 Ruby 3.1.2/Bundler 호환성 이슈에 대한 특별한 처리가 되어 있습니다. gem 로딩 충돌을 피하려면 항상 `bundle exec`로 명령어를 실행하세요.

## 코드 아키텍처

### 핵심 구조
토스페이먼츠(한국 결제 서비스)를 Rails 애플리케이션과 통합하는 Rails gem입니다. Rails 통합을 포함한 표준 Ruby gem 패턴을 따릅니다.

### 주요 구성요소

**메인 모듈**: `Tosspayments::Rails`
- 진입점: `lib/tosspayments/rails.rb`
- Rails가 사용 가능할 때만 Rails 구성요소를 조건부로 로드
- 비Rails 환경에서의 우아한 성능 저하 처리

**클라이언트 계층**: `Tosspayments::Rails::Client`
- TossPayments REST API 클라이언트
- 결제 승인, 취소, 조회 처리
- PaymentDetail 모델 사용 가능 시 자동 통합
- 한국어/영어 결제 상태 정규화

**Rails 통합**:
- **컨트롤러 헬퍼**: `controller_helpers.rb` - 결제 처리 메서드
- **뷰 헬퍼**: `view_helpers.rb` - 프론트엔드 위젯 생성, Pagy 페이지네이션 통합
- **모델**: 상세 결제 정보 저장을 위한 PaymentDetail 모델
- **제너레이터**: 설정을 위한 install 및 payment_detail 제너레이터

**데이터 계층**: PaymentDetail 모델 (선택사항)
- 기본 거래를 넘어선 포괄적인 결제 정보 저장
- 결제 통계 및 필터링 기능 제공
- 비즈니스 객체 연결을 위한 다형성 `payable` 연관관계

### 제너레이터 시스템

**Install 제너레이터** (`rails generate tosspayments:install`):
- 기본 결제 인프라 생성
- 컨트롤러, 뷰, 마이그레이션, 라우트 생성
- 버전별 마이그레이션 템플릿으로 Rails 7.x 및 8.x 지원
- 선택적 Stimulus 컨트롤러 및 CSS 에셋

**Payment Detail 제너레이터** (`rails generate tosspayments:payment_detail`):
- 상세 결제 추적 기능 추가
- PaymentDetail 모델 및 관련 뷰 생성
- 결제 분석 및 리포팅 기능 제공

### 설정 관리
- 보안 키 저장을 위한 Rails credentials 사용
- 개발을 위한 환경 변수 지원
- 샌드박스/프로덕션 모드 전환
- 클라이언트 및 시크릿 키 관리

### 프론트엔드 통합
- TossPayments Widget SDK v2 통합
- 최신 Rails 앱을 위한 Stimulus 컨트롤러
- Brandpay (토스페이먼츠 자체 결제 방식) 지원
- 커스터마이즈 가능한 결제 폼 및 스타일링

### 에러 처리 전략
- 커스텀 예외 계층구조 (ConfigurationError, PaymentError)
- Rails 구성요소 사용 불가 시 우아한 성능 저하
- 한국어 지원을 포함한 포괄적 에러 로깅
- 의미 있는 에러 메시지를 통한 네트워크 실패 처리

## 중요한 구현 참고사항

### Rails 환경 감지
gem은 Rails 가용성을 확인하고 구성요소를 조건부로 로드합니다. 이를 통해 Rails가 사용 가능할 때는 완전한 Rails 통합을 제공하면서 비Rails 환경에서도 핵심 기능이 작동할 수 있게 합니다.

### 마이그레이션 버전 관리
마이그레이션 템플릿은 Rails 7.x 및 8.x 호환성을 위한 Rails 버전별 주석을 포함합니다. install 제너레이터는 `migration_version` 메서드를 사용하여 적절한 마이그레이션 구문을 생성합니다.

### 한국 결제 방식 정규화
클라이언트는 한국어 결제 방식 이름을 영어 열거형 값으로 매핑하는 함수를 포함하여 다양한 API 응답 형식 간의 데이터 일관성을 보장합니다.

### PaymentDetail 통합
PaymentDetail 모델이 사용 가능할 때, 클라이언트는 영수증 URL, 카드 정보, 가상계좌 세부사항, 실패 사유를 포함한 상세 결제 정보를 자동으로 저장합니다.

### Bundler 호환성
Ruby 3.1.2/Bundler 버전 충돌로 인해, gem은 `bundle exec`와 안전하게 작동하도록 설계되었으며 DEVELOPMENT.md에 문서화된 gem 로딩 이슈에 대한 특별한 에러 처리를 포함합니다.