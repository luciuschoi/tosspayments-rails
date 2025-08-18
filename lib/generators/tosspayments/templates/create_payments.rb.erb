# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[<%= migration_version %>]
  def change
    create_table :payments do |t|
      t.string :order_id, null: false, comment: '주문 ID'
      t.string :payment_key, comment: '토스페이먼츠 결제 키'
      t.integer :amount, null: false, comment: '결제 금액'
      t.string :status, default: 'pending', comment: '결제 상태'
      t.string :method, comment: '결제 수단'
      t.string :customer_email, comment: '고객 이메일'
      t.string :customer_name, comment: '고객 이름'
      t.string :order_name, comment: '주문명'
      t.string :failure_code, comment: '실패 코드'
      t.string :failure_reason, comment: '실패 사유'
      t.text :raw_data, comment: '원본 응답 데이터 (JSON)'
      t.datetime :paid_at, comment: '결제 완료 시각'
      t.datetime :failed_at, comment: '결제 실패 시각'

      t.timestamps

      t.index :order_id, unique: true
      t.index :payment_key
      t.index :status
      t.index :customer_email
    end
  end
end
