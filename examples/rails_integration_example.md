# Rails 통합 사용 예제

토스페이먼츠 Rails gem을 실제 Rails 애플리케이션에서 사용하는 방법을 설명합니다.

## 1. Gem 설치 및 설정

### Gemfile에 추가

```ruby
gem 'tosspayments-rails'
```

### Rails credentials 설정

```bash
$ rails credentials:edit
```

```yaml
tosspayments:
  client_key: test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq
  secret_key: test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R
  sandbox: true
```

### 제너레이터 실행

```bash
$ rails generate tosspayments:install
```

## 2. 컨트롤러 구현

```ruby
# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  include Tosspayments::Rails::ControllerHelpers

  def show
    @order = Order.find(params[:id])
    @order_id = "ORDER_#{@order.id}_#{Time.current.to_i}"
    @customer_key = current_user&.id || "GUEST_#{SecureRandom.hex(8)}"
  end

  def payment_confirm
    result = confirm_tosspayments_payment(
      payment_key: params[:paymentKey],
      order_id: params[:orderId],
      amount: params[:amount].to_i
    )

    if result[:success] != false
      # 주문 상태 업데이트
      order = Order.find_by(order_id: params[:orderId])
      order&.update(status: 'paid', payment_key: params[:paymentKey])

      redirect_to success_order_path(order), notice: '결제가 완료되었습니다.'
    else
      redirect_to fail_order_path, alert: "결제 실패: #{result[:error]}"
    end
  end

  def payment_cancel
    order = Order.find(params[:id])

    result = cancel_tosspayments_payment(
      payment_key: order.payment_key,
      cancel_reason: "고객 요청 취소"
    )

    if result[:success] != false
      order.update(status: 'cancelled')
      redirect_to order, notice: '결제가 취소되었습니다.'
    else
      redirect_to order, alert: "취소 실패: #{result[:error]}"
    end
  end
end
```

## 3. 뷰 구현

### 주문 상세 페이지 (결제 폼)

```erb
<%# app/views/orders/show.html.erb %>
<div class="container mx-auto p-6">
  <h1 class="text-2xl font-bold mb-6">주문 결제</h1>

  <div class="bg-gray-50 p-4 rounded-lg mb-6">
    <h2 class="font-semibold mb-2">주문 정보</h2>
    <p>상품명: <%= @order.product_name %></p>
    <p>주문번호: <%= @order_id %></p>
    <p>결제금액: <%= number_to_currency(@order.amount, unit: "원", precision: 0) %></p>
  </div>

  <%# 토스페이먼츠 SDK 로드 %>
  <%= tosspayments_script_tag %>

  <%# 결제 UI %>
  <%= tosspayments_payment_form(
    order_id: @order_id,
    amount: @order.amount,
    order_name: @order.product_name
  ) %>

  <%# 결제위젯 초기화 %>
  <%= tosspayments_widget_script(customer_key: @customer_key) %>

  <%# 결제 요청 스크립트 %>
  <%= tosspayments_payment_script(
    order_id: @order_id,
    amount: @order.amount,
    order_name: @order.product_name,
    success_url: payment_confirm_order_url(@order),
    fail_url: payment_fail_orders_url
  ) %>
</div>
```

### 결제 성공 페이지

```erb
<%# app/views/orders/success.html.erb %>
<div class="container mx-auto p-6 text-center">
  <div class="text-green-500 text-6xl mb-4">✅</div>
  <h1 class="text-2xl font-bold mb-4">결제가 완료되었습니다!</h1>
  <p class="mb-6">주문해 주셔서 감사합니다.</p>

  <div class="bg-gray-50 p-4 rounded-lg mb-6 text-left max-w-md mx-auto">
    <h2 class="font-semibold mb-2">주문 정보</h2>
    <p>주문번호: <%= @order.order_id %></p>
    <p>상품명: <%= @order.product_name %></p>
    <p>결제금액: <%= number_to_currency(@order.amount, unit: "원", precision: 0) %></p>
  </div>

  <%= link_to "주문 목록으로", orders_path,
      class: "bg-blue-500 text-white px-6 py-2 rounded hover:bg-blue-600" %>
</div>
```

## 4. 라우팅 설정

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :orders do
    member do
      get :payment_confirm
      post :payment_cancel
      get :success
    end

    collection do
      get :payment_fail
    end
  end

  # 토스페이먼츠 웹훅
  post '/webhooks/tosspayments', to: 'webhooks#tosspayments'
end
```

## 5. 웹훅 처리

```ruby
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  include Tosspayments::Rails::ControllerHelpers

  skip_before_action :verify_authenticity_token, only: [:tosspayments]

  def tosspayments
    payment_key = params.dig(:data, :paymentKey)

    return head :bad_request unless payment_key

    payment = get_tosspayments_payment(payment_key)

    if payment[:success] != false
      order = Order.find_by(payment_key: payment_key)

      case payment[:status]
      when "DONE"
        order&.update(status: 'completed')
        Rails.logger.info "결제 완료 웹훅 처리: #{payment_key}"
      when "CANCELED"
        order&.update(status: 'cancelled')
        Rails.logger.info "결제 취소 웹훅 처리: #{payment_key}"
      end
    end

    head :ok
  end
end
```

## 6. 모델 예제

```ruby
# app/models/order.rb
class Order < ApplicationRecord
  enum status: {
    pending: 0,     # 결제 대기
    paid: 1,        # 결제 완료
    completed: 2,   # 주문 완료
    cancelled: 3    # 취소됨
  }

  validates :product_name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :order_id, uniqueness: true, allow_blank: true

  before_create :generate_order_id

  private

  def generate_order_id
    self.order_id = "ORDER_#{id}_#{Time.current.to_i}" if order_id.blank?
  end
end
```

## 7. 마이그레이션

```ruby
# db/migrate/xxx_create_orders.rb
class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.string :product_name, null: false
      t.integer :amount, null: false
      t.string :order_id
      t.string :payment_key
      t.integer :status, default: 0
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :orders, :order_id, unique: true
    add_index :orders, :payment_key
  end
end
```

이와 같이 토스페이먼츠 Rails gem을 사용하여 완전한 결제 시스템을 구축할 수 있습니다.
