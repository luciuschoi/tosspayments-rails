# Tosspayments Rails

토스페이먼츠 온라인 결제 서비스를 Rails 애플리케이션에 쉽게 통합할 수 있는 Ruby gem입니다.

## 주요 기능

- 토스페이먼츠 결제위젯 연동
- Rails 7.x / 8.x 완전 호환 (Ruby 3.1.2+ 지원)
- Rails credentials를 통한 안전한 키 관리
- 컨트롤러 및 뷰 헬퍼 제공
- 결제 승인, 취소, 조회 API 지원
- 브랜드페이 연동 지원
- 웹훅 처리 지원
- **상세 결제 정보 자동 저장 및 관리**
- **결제 통계 및 분석 기능**

## 설치

Gemfile에 다음을 추가하세요:

```ruby
gem 'tosspayments-rails', git: "git@github.com:luciuschoi/tosspayments-rails.git"
```

그리고 bundle install을 실행하세요:

```bash
$ bundle install
```

## 설정

### 1. 제너레이터 실행

```bash
$ rails generate tosspayments:install
```

이 명령어는 다음 파일들을 생성합니다:

- `config/initializers/tosspayments.rb` - 설정 파일
- `app/controllers/payments_controller.rb` - 결제 컨트롤러
- `app/views/payments/` - 결제 관련 뷰 파일들
- 라우트 추가

### 2. 상세 결제 정보 저장 기능 설치 (선택사항)

결제 정보를 상세하게 저장하고 관리하려면 다음 명령어를 실행하세요:

```bash
$ rails generate tosspayments:payment_detail
```

이 명령어는 다음을 생성합니다:

- `db/migrate/create_payment_details.rb` - PaymentDetail 테이블 마이그레이션
- `app/models/payment_detail.rb` - PaymentDetail 모델
- `app/controllers/payment_details_controller.rb` - PaymentDetails 컨트롤러
- `app/views/payment_details/` - 결제 상세 정보 뷰 파일들
- 라우트 추가

### 3. Rails credentials 설정

```bash
$ rails credentials:edit
```

다음과 같이 토스페이먼츠 설정을 추가하세요:

```yaml
tosspayments:
  client_key: test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq # 결제위젯 연동 키 > 클라이언트 키
  secret_key: test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R # 결제위젯 연동 키 > 시크릿 키
  sandbox: true # 개발환경에서는 true, 운영환경에서는 false
```

⚠️ **보안 주의사항**: 위의 키는 테스트용입니다. 실제 운영시에는 [토스페이먼츠 개발자센터](https://developers.tosspayments.com)에서 발급받은 실제 키를 사용하세요.

### 4. 토스페이먼츠 개발자센터 설정

[토스페이먼츠 개발자센터](https://developers.tosspayments.com)에서:

- 결제위젯 연동 키 발급
- 리다이렉트 URL 설정:
  - 성공: `http://localhost:3000/payments/success`
  - 실패: `http://localhost:3000/payments/fail`
- 웹훅 URL 설정: `http://localhost:3000/payments/webhook`

## 사용법

### 1. 기본 결제 페이지

결제 페이지에서 토스페이먼츠 결제위젯을 사용하려면:

```erb
<%# app/views/payments/new.html.erb %>

<%# 토스페이먼츠 SDK 로드 %>
<%= tosspayments_script_tag %>

<%# 결제 폼 %>
<%= tosspayments_payment_form(
  order_id: @order_id,
  amount: @amount,
  order_name: @order_name
) %>

<%# 결제위젯 초기화 %>
<%= tosspayments_widget_script(customer_key: @customer_key) %>

<%# 결제 요청 스크립트 %>
<%= tosspayments_payment_script(
  order_id: @order_id,
  amount: @amount,
  order_name: @order_name,
  success_url: "#{request.base_url}/payments/success",
  fail_url: "#{request.base_url}/payments/fail"
) %>
```

### 2. 컨트롤러에서 결제 처리

```ruby
class PaymentsController < ApplicationController
  include Tosspayments::Rails::ControllerHelpers

  def create
    result = confirm_tosspayments_payment(
      payment_key: params[:paymentKey],
      order_id: params[:orderId],
      amount: params[:amount].to_i
    )

    if result[:success] != false
      redirect_to success_payments_path(paymentKey: params[:paymentKey])
    else
      redirect_to fail_payments_path(message: result[:error])
    end
  end

  def cancel
    result = cancel_tosspayments_payment(
      payment_key: params[:payment_key],
      cancel_reason: "고객 요청"
    )

    # 결과 처리...
  end
end
```

### 3. 상세 결제 정보 관리

PaymentDetail 모델을 사용하여 결제 정보를 상세하게 관리할 수 있습니다:

```ruby
# 결제 상세 정보 조회
payment_detail = PaymentDetail.find_by(payment_key: "payment_key")

# 결제 통계 조회
statistics = PaymentDetail.statistics(
  start_date: 1.month.ago,
  end_date: Date.current
)

# 결제 방법별 통계
card_payments = PaymentDetail.by_method('card').successful

# 상태별 필터링
pending_payments = PaymentDetail.by_status('pending')
```

### 4. 브랜드페이 연동

```erb
<%# 브랜드페이 스크립트 %>
<%= tosspayments_brandpay_script(
  customer_key: current_user.id,
  redirect_url: brandpay_callback_url
) %>

<button onclick="addBrandpayMethod()">결제수단 추가</button>
<button onclick="openBrandpaySettings()">브랜드페이 설정</button>
```

### 5. API 클라이언트 직접 사용

```ruby
client = Tosspayments::Rails::Client.new

# 결제 승인 (상세 정보 자동 저장)
result = client.confirm_payment(
  payment_key: "payment_key",
  order_id: "order_id",
  amount: 15000
)

# 결제 조회
payment = client.get_payment("payment_key")

# 결제 취소
result = client.cancel_payment(
  payment_key: "payment_key",
  cancel_reason: "고객 요청"
)

# 결제 상세 정보 조회
payment_detail = client.get_payment_detail("payment_key")

# 결제 통계 조회
statistics = client.get_payment_statistics(
  start_date: 1.month.ago,
  end_date: Date.current,
  status: 'done'
)
```

## 헬퍼 메서드

### 뷰 헬퍼

- `tosspayments_script_tag` - 토스페이먼츠 SDK 스크립트 태그
- `tosspayments_widget_script(options)` - 결제위젯 초기화 스크립트
- `tosspayments_payment_script(options)` - 결제 요청 스크립트
- `tosspayments_payment_form(options)` - 기본 결제 폼 HTML
- `tosspayments_brandpay_script(options)` - 브랜드페이 스크립트

### 컨트롤러 헬퍼

- `confirm_tosspayments_payment(options)` - 결제 승인
- `cancel_tosspayments_payment(options)` - 결제 취소
- `get_tosspayments_payment(payment_key)` - 결제 조회

## PaymentDetail 모델 기능

### 필드

- `payment_key` - 토스페이먼츠 결제 키
- `order_id` - 주문 ID
- `order_name` - 주문명
- `method` - 결제 방법 (card, transfer, virtual_account 등)
- `status` - 결제 상태 (pending, done, canceled 등)
- `total_amount` - 총 결제 금액
- `balance_amount` - 잔액
- `supplied_amount` - 공급가액
- `vat` - 부가세
- `currency` - 통화
- `card` - 카드 결제 정보 (JSON)
- `virtual_account` - 가상계좌 정보 (JSON)
- `transfer` - 계좌이체 정보 (JSON)
- `cancels` - 취소 정보 (JSON)
- `receipt_url` - 영수증 URL
- `payable` - 결제 대상 모델 (polymorphic)

### 스코프

```ruby
PaymentDetail.recent                    # 최신순
PaymentDetail.by_status('done')         # 상태별 필터
PaymentDetail.by_method('card')         # 결제 방법별 필터
PaymentDetail.successful                # 성공한 결제만
PaymentDetail.failed                    # 실패한 결제만
PaymentDetail.by_date_range(start, end) # 날짜 범위 필터
```

### 인스턴스 메서드

```ruby
payment_detail.successful?              # 결제 성공 여부
payment_detail.failed?                  # 결제 실패 여부
payment_detail.pending?                 # 결제 대기 중 여부
payment_detail.formatted_total_amount   # 포맷된 금액
payment_detail.method_name              # 결제 방법 한글명
payment_detail.status_name              # 상태 한글명
payment_detail.card_info                # 카드 정보
payment_detail.virtual_account_info     # 가상계좌 정보
payment_detail.cancel_info              # 취소 정보
```

## 테스트

결제 테스트를 위해 서버를 시작하고 다음 URL에 접속하세요:

```
http://localhost:3000/payments/new
```

## 예제 실행

샘플 스크립트로 gem 로드와 기본 동작을 확인할 수 있습니다. 모든 실행은 Bundler 컨텍스트에서 권장합니다.

- 기본 실행 (비밀키 없이도 동작, 초기화는 건너뜀):

```
bundle exec ruby examples/basic_usage.rb
```

- 비밀키 설정 후 클라이언트 초기화까지 확인:

```
export TOSSPAY_SECRET_KEY={{TOSSPAY_TEST_SECRET_KEY}}
bundle exec ruby examples/basic_usage.rb
```

- 선택적으로 API 호출 테스트까지 시도 (유효한 키가 없으면 실패가 정상):

```
export TOSSPAY_SECRET_KEY={{TOSSPAY_TEST_SECRET_KEY}}
export RUN_API=1
export DUMMY_PAYMENT_KEY={{DUMMY_PAYMENT_KEY}}
# 필요 시 클라이언트 키/샌드박스도 지정 가능
# export TOSSPAY_CLIENT_KEY={{TOSSPAY_TEST_CLIENT_KEY}}
# export TOSSPAY_SANDBOX=true
bundle exec ruby examples/basic_usage.rb
```

주의: 실제 서비스 키를 평문으로 노출하지 마세요. 테스트 키는 토스페이먼츠 개발자센터에서 발급받아 사용하세요.

## 개발

저장소를 체크아웃한 후 `bin/setup`을 실행하여 의존성을 설치하세요. `bin/console`로 대화형 프롬프트를 실행할 수 있습니다.

로컬 머신에 gem을 설치하려면 `bundle exec rake install`을 실행하세요.

## 기여하기

GitHub에서 버그 리포트와 풀 리퀘스트를 환영합니다: https://github.com/luciuschoi/tosspayments-rails

## 라이선스

이 gem은 [MIT License](https://opensource.org/licenses/MIT) 하에 오픈소스로 제공됩니다.
