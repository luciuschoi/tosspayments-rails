# Tosspayments Rails 통합 순차 가이드 (Walkthrough)

Rails 애플리케이션에 `tosspayments-rails` 젬을 추가하여 실제 결제를 구현하기 위한 end-to-end 절차를 정리했습니다. (README 기반 + 소스 코드 참조)

---
## 1. Gem 추가
Gemfile:
```ruby
gem 'tosspayments-rails', git: 'git@github.com:luciuschoi/tosspayments-rails.git'
```
설치:
```bash
bundle install
```

(버전이 Rubygems 에 배포되었다면 `git:` 옵션 없이 버전 지정 가능.)

---
## 2. 기본 리소스 설치 제너레이터 실행
```bash
rails generate tosspayments:install
rails db:migrate
```
생성물:
- Payments 관련 마이그레이션 / 모델 / 컨트롤러 / 뷰
- 초기화 파일 (`config/initializers/tosspayments.rb`)
- Stimulus 컨트롤러/자바스크립트 & CSS 자산 (등록 로직은 Railtie 참고)

소스 참조: `lib/generators/tosspayments/install_generator.rb`

---
## 3. (선택) PaymentDetail 확장 설치
상세 결제 이력/금액 통계 등을 활용하려면:
```bash
rails generate tosspayments:payment_detail
rails db:migrate
```
소스: `lib/generators/tosspayments/payment_detail_generator.rb`

---
## 4. 자격 증명 (Credentials) 설정
```bash
rails credentials:edit
```
예시:
```yaml
tosspayments:
  client_key: test_ck_XXXXXXXX
  secret_key: test_sk_YYYYYYYY
  sandbox: true
```
로딩 경로: `Tosspayments::Rails::Railtie` 에서 credentials / ENV fallback.

Fallback ENV (개발 편의):
- `TOSSPAY_CLIENT_KEY`
- `TOSSPAY_SECRET_KEY`
- `TOSSPAY_SANDBOX` ("true" / "false")

---
## 5. 초기화 및 설정 객체 확인
이니셜라이저 템플릿: `lib/generators/tosspayments/templates/initializer.rb`
런타임 접근:
```ruby
Tosspayments::Rails.configuration.client_key
```

---
## 6. 결제 페이지(Checkout) 구성
생성된 `PaymentsController#new` 에서 주문 관련 값 세팅.
뷰에서 제공 헬퍼 사용 (소스: `lib/tosspayments/rails/view_helpers.rb`):
```erb
<%= tosspayments_script_tag %>
<%= tosspayments_payment_form(order_id: @order_id, order_name: @order_name, amount: @amount) %>
<%= tosspayments_widget_script(customer_key: @customer_key) %>
<%= tosspayments_payment_script(
      order_id: @order_id,
      order_name: @order_name,
      success_url: "#{request.base_url}/payments/success",
      fail_url:    "#{request.base_url}/payments/fail"
) %>
```
- `order_id` 는 **고유**해야 하며 서버 DB 에 Pending 상태로 미리 저장하는 패턴 권장.
- 금액 조작 방지를 위해 서버 측에서 amount 재검증.

---
## 7. Stimulus 컨트롤러 연동
제너레이터가 `tosspayments_controller.js` 및 스타일(`tosspayments.css`) 추가.
- 파일 템플릿: `lib/generators/tosspayments/templates/tosspayments_controller.js`
- 폼 data-* 속성은 `tosspayments_payment_form` 헬퍼가 자동 부여.

Webpacker / Importmap / JS 번들러 설정에 따라 빌드 파이프라인 내 컨트롤러 등록 확인.

---
## 8. 결제 승인 흐름 (Confirm)
프론트(스크립트)에서 결제 인터랙션 후 Toss가 `paymentKey`, `orderId`, `amount` 를 success URL 로 리다이렉트.
`PaymentsController#success` 또는 별도 `create/confirm` 액션에서 헬퍼 사용:
```ruby
result = confirm_tosspayments_payment(payment_key: params[:paymentKey], order_id: params[:orderId], amount: params[:amount])
```
내부 동작 (`Tosspayments::Rails::Client#confirm_payment`):
- API 호출 성공 시 Payment 레코드 갱신 (및 PaymentDetail 옵션 설치 시 상세 저장)
- 실패 시 예외 → 컨트롤러 헬퍼 rescue 후 구조화된 해시 반환

---
## 9. 실패 처리
`fail` 액션에서 `errorCode`, `errorMessage` 파라미터 표시/로그.
보안상 원문 메시지 전부 노출 하지 말고 사용자 친화적 메시지 변환 고려.

---
## 10. Webhook (선택) 처리
Webhook 엔드포인트 예: `POST /payments/webhook`.
```ruby
before_action :verify_tosspayments_webhook, only: :webhook
```
`verify_tosspayments_webhook` (소스: `controller_helpers.rb`) 가 시그니처 검증.
검증 성공 후 상태/정산 정보 동기화.
TIP: Webhook 은 idempotent 하게 구현 (paymentKey + eventType Unique Index 등).

---
## 11. Payment / PaymentDetail 모델
- 기본 `Payment` 템플릿: `lib/generators/tosspayments/templates/payment.rb`
- 확장 `PaymentDetail`: `lib/tosspayments/rails/payment_detail.rb`
활용:
```ruby
payment = Payment.find_by(order_id: params[:orderId])
payment.status # e.g. 'DONE'
```
상세 금액 포맷 / 부가정보는 detail 테이블에서.

---
## 12. 통계 / 조회 API
```ruby
client = Tosspayments::Rails::Client.new
stats = client.get_payment_statistics(start_date: 1.month.ago, end_date: Date.today)
```
(메서드: `client.rb` 내부)

---
## 13. 결제 취소 (Refund / Cancel)
```ruby
cancel_tosspayments_payment(payment_key: payment.payment_key, cancel_reason: "사용자 요청")
```
내부: `Tosspayments::Rails::Client#cancel_payment` 호출 후 DB 상태 갱신.
부분취소 필요 시 해당 메서드 파라미터(금액, 세금 등) 확장 고려.

---
## 14. BrandPay (옵션)
브랜드페이 스크립트 헬퍼:
```erb
<%= tosspayments_brandpay_script %>
```
브랜드페이 적용 시 위젯 초기화 파라미터에 customer_key 일관성 유지.

---
## 15. 금액 / 포맷 유틸
뷰 헬퍼:
```erb
<%= tosPayments_format_amount(123456) %>
```
(정확한 메서드명은 `view_helpers.rb` 확인; 예: `tosspayments_format_amount`).
로케일별 포맷이 필요하면 I18n 래핑 확장.

---
## 16. 에러 처리 전략
Client 레벨 예외 → `Tosspayments::Rails::PaymentError`.
컨트롤러 헬퍼들이 rescue 하여 `{ success: false, error: message }` 형태 반환.
권장 패턴:
```ruby
result = confirm_tosspayments_payment(...)
if result[:success]
  redirect_to payment_path(result[:payment])
else
  Rails.logger.warn(result[:error])
  render :fail, status: :unprocessable_entity
end
```

---
## 17. 테스트 및 로컬 시나리오
결제 플로우 수동 점검:
```
http://localhost:3000/payments/new
```
자동화 예시(미구현 시 추가 권장):
- 모델: Payment status 전이 테스트
- 클라이언트: confirm/cancel 시 WebMock 이용해 API 응답 스텁

---
## 18. 운영(Production) 준비 체크리스트
| 항목 | 내용 |
|------|------|
| 키 관리 | production credentials 에만 실제 secret_key 저장 |
| 도메인/Redirect | Toss 개발자센터 Success/Fail URL & Webhook URL 등록 |
| HTTPS | Webhook 및 리다이렉트 모두 TLS 사용 |
| 로그 마스킹 | secret_key, 카드번호 등 PII 노출 제거 |
| 중복 처리 | order_id Unique + webhook 멱등성 보장 |
| 모니터링 | 실패 빈도, 승인 소요 시간, 취소율 Metrics 수집 |

---
## 19. 확장 아이디어
- 부분취소(amount 일부) 파라미터 지원
- 재시도 가능한 Pending 타임아웃 처리(Job)
- Admin 대시보드: 최근 결제 / 매출 차트
- 서명 검증 강화 (타임스탬프 리플레이 방지)

---
## 20. 최소 샘플 컨트롤러 구조 (요약)
```ruby
class PaymentsController < ApplicationController
  include Tosspayments::Rails::ControllerHelpers

  def new
    @order = Order.create!(status: :pending, amount: params.fetch(:amount, 1000))
    @order_id    = @order.order_id
    @order_name  = "샘플 주문"
    @amount      = @order.amount
    @customer_key = current_user&.id || SecureRandom.uuid
  end

  def success
    result = confirm_tosspayments_payment(payment_key: params[:paymentKey], order_id: params[:orderId], amount: params[:amount])
    if result[:success]
      redirect_to payment_path(result[:payment]), notice: '결제가 완료되었습니다.'
    else
      redirect_to fail_payments_path(error: result[:error])
    end
  end

  def fail
    @error = params[:error] || params[:errorMessage]
  end

  # (선택) Webhook
  protect_from_forgery except: :webhook
  before_action :verify_tosspayments_webhook, only: :webhook
  def webhook
    # payload 파싱 및 상태 갱신
    head :ok
  end
end
```

---
## 21. 보안 주의 사항
- 금액/주문명은 서버 재검증; 클라이언트 hidden field 신뢰 금지
- Webhook 서명 헤더 검증 실패 시 즉시 401 반환
- OrderId 예측 불가 (UUID 권장)
- 예외 메시지를 그대로 사용자에게 노출 금지

---
## 22. 문제 해결 FAQ
| 증상 | 점검 포인트 |
|------|-------------|
| 401 Unauthorized | secret_key / endpoint / sandbox 설정 오타 |
| 금액 불일치 오류 | 서버 DB amount vs Toss confirm 요청 파라미터 비교 |
| Webhook 미도착 | 방화벽/URL 설정, HTTP 2xx 응답 여부 |
| JS 위젯 미로딩 | `<%= tosspayments_script_tag %>` 삽입 여부, CSP 정책 |
| 중복 결제 | order_id 재사용 여부, 멱등 처리 누락 |

---
## 23. 빠른 점검 스크립트 (콘솔)
```ruby
client = Tosspayments::Rails::Client.new
client.configuration.client_key # 기대: test_ck_...
```

---
## 24. 마이그레이션 / 스키마 변경 시
- 기존 Payment 레코드에 NULL 방지 위한 default / backfill 작업
- 금액 컬럼 integer (KRW) 유지, 다중 통화 필요 시 currency 컬럼 추가 고려

---
## 25. 요약 플로우 다이어그램 (텍스트)
```
[사용자] --(new)--> /payments/new --(JS 위젯)--> Toss 결제창
   |<-- success redirect (paymentKey, orderId, amount) --|
[서버] confirm_tosspayments_payment -> Toss API -> DB 업데이트
   |--> 사용자 결제 완료 페이지
[Toss] --(이벤트)--> Webhook -> 서버 상태 동기화 (보강)
```

---
## 26. 다음 단계 권장
- 통계 대시보드 / 지표 (매출, 실패율)
- Background Job 으로 오래 지속되는 PENDING 자동 취소
- SLA / 장애 알림 (Webhook 실패 재시도 감지)

---

문의/개선 아이디어는 이 저장소 이슈로 등록하세요.
