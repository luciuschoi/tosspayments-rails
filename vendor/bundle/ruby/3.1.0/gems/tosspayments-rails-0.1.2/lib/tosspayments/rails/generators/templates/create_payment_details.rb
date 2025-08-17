class CreatePaymentDetails < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_details do |t|
      t.string :payment_key, null: false, index: { unique: true }
      t.string :order_id, null: false
      t.string :order_name
      t.string :method
      t.string :status, default: 'PENDING'
      t.datetime :requested_at
      t.datetime :approved_at
      t.boolean :use_escrow, default: false
      
      # 카드 결제 정보
      t.json :card
      
      # 가상계좌 정보
      t.json :virtual_account
      
      # 계좌이체 정보
      t.json :transfer
      
      # 휴대폰 결제 정보
      t.json :mobile_phone
      
      # 상품권 정보
      t.json :gift_certificate
      
      # 해외 간편결제 정보
      t.json :foreign_easy_pay
      
      # 현금영수증 정보
      t.json :cash_receipt
      
      # 할인 정보
      t.json :discount
      
      # 취소 정보
      t.json :cancels
      
      # 시크릿 정보
      t.json :secret
      
      # 결제 타입
      t.string :type
      
      # 간편결제 정보
      t.json :easy_pay
      
      # 국가 정보
      t.string :country
      
      # 실패 정보
      t.json :failure
      
      # 금액 정보
      t.integer :total_amount
      t.integer :balance_amount
      t.integer :supplied_amount
      t.integer :vat
      t.integer :tax_free_amount
      t.string :currency, default: 'KRW'
      
      # 영수증 URL
      t.string :receipt_url
      
      # 연관 모델 참조
      t.references :payable, polymorphic: true, null: true
      
      t.timestamps
    end
    
    add_index :payment_details, :order_id
    add_index :payment_details, :status
    add_index :payment_details, :method
    add_index :payment_details, :created_at
  end
end 