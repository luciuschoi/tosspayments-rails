class CreatePaymentDetails < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :payment_details do |t|
      t.string :payment_key, null: false, index: { unique: true }
      t.string :order_id, null: false, index: true
      t.string :order_name
  t.string :payment_method, index: true
      t.string :status, index: true
      t.integer :total_amount, null: false
      t.integer :balance_amount
      t.integer :supplied_amount
      t.integer :vat
      t.string :currency, default: 'KRW'
      t.json :card
      t.json :virtual_account
      t.json :transfer
      t.json :cancels
      t.string :receipt_url
      t.datetime :approved_at, index: true
      t.boolean :use_escrow, default: false
      t.boolean :culture_expense, default: false
      t.integer :tax_free_amount, default: 0
      t.integer :tax_exemption_amount, default: 0
      
      # 추가 결제 정보
      t.string :requested_at
      t.json :mobile_phone
      t.json :gift_certificate
      t.json :foreign_easy_pay
      t.json :cash_receipt
      t.json :discount
      t.string :secret
  t.string :payment_type
      t.json :easy_pay
      t.string :country
      t.json :failure
      
      # Polymorphic association
      t.references :payable, polymorphic: true, index: true

      t.timestamps
    end

    add_index :payment_details, [:status, :created_at]
  add_index :payment_details, [:payment_method, :created_at]
    add_index :payment_details, [:approved_at, :status]
  end
end 