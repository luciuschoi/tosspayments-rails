# frozen_string_literal: true

class PaymentDetail < ApplicationRecord
  belongs_to :payable, polymorphic: true, optional: true
  
  validates :payment_key, presence: true, uniqueness: true
  validates :order_id, presence: true
  validates :status, presence: true
  
  # 상태 열거형
  enum status: {
    pending: 'PENDING',
    waiting_for_acceptance: 'WAITING_FOR_ACCEPTANCE',
    done: 'DONE',
    canceled: 'CANCELED',
    partial_canceled: 'PARTIAL_CANCELED',
    aborted: 'ABORTED',
    failed: 'FAILED'
  }
  
  # 결제 방법 열거형
  enum method: {
    card: 'CARD',
    transfer: 'TRANSFER',
    virtual_account: 'VIRTUAL_ACCOUNT',
    mobile_phone: 'MOBILE_PHONE',
    gift_certificate: 'GIFT_CERTIFICATE',
    foreign_easy_pay: 'FOREIGN_EASY_PAY',
    easy_pay: 'EASY_PAY'
  }
  
  # 스코프
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_method, ->(method) { where(method: method) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  scope :successful, -> { where(status: 'done') }
  scope :failed, -> { where(status: ['failed', 'canceled', 'aborted']) }
  
  # 결제 성공 여부
  def successful?
    status == 'done'
  end
  
  # 결제 실패 여부
  def failed?
    %w[failed canceled aborted].include?(status)
  end
  
  # 결제 대기 중 여부
  def pending?
    %w[pending waiting_for_acceptance].include?(status)
  end
  
  # 결제 금액 포맷팅
  def formatted_total_amount
    ActionController::Base.helpers.number_to_currency(total_amount, unit: '₩', precision: 0)
  end
  
  # 결제 방법 한글명
  def method_name
    case method
    when 'card'
      '신용카드'
    when 'transfer'
      '계좌이체'
    when 'virtual_account'
      '가상계좌'
    when 'mobile_phone'
      '휴대폰'
    when 'gift_certificate'
      '상품권'
    when 'foreign_easy_pay'
      '해외 간편결제'
    when 'easy_pay'
      '간편결제'
    else
      method&.titleize
    end
  end
  
  # 상태 한글명
  def status_name
    case status
    when 'pending'
      '대기중'
    when 'waiting_for_acceptance'
      '승인 대기중'
    when 'done'
      '완료'
    when 'canceled'
      '취소됨'
    when 'partial_canceled'
      '부분 취소됨'
    when 'aborted'
      '중단됨'
    when 'failed'
      '실패'
    else
      status&.titleize
    end
  end
  
  # 카드 정보 조회
  def card_info
    return nil unless card.is_a?(Hash)
    
    {
      company: card['company'],
      number: card['number'],
      installment_plan_months: card['installmentPlanMonths'],
      is_interest_free: card['isInterestFree'],
      approve_no: card['approveNo'],
      use_card_point: card['useCardPoint'],
      card_type: card['cardType'],
      owner_type: card['ownerType'],
      acquire_status: card['acquireStatus'],
      amount: card['amount']
    }
  end
  
  # 가상계좌 정보 조회
  def virtual_account_info
    return nil unless virtual_account.is_a?(Hash)
    
    {
      account_number: virtual_account['accountNumber'],
      account_type: virtual_account['accountType'],
      bank_code: virtual_account['bankCode'],
      customer_name: virtual_account['customerName'],
      due_date: virtual_account['dueDate'],
      expired: virtual_account['expired'],
      settlement_status: virtual_account['settlementStatus']
    }
  end
  
  # 취소 정보 조회
  def cancel_info
    return [] unless cancels.is_a?(Array)
    
    cancels.map do |cancel|
      {
        cancel_amount: cancel['cancelAmount'],
        cancel_reason: cancel['cancelReason'],
        tax_free_amount: cancel['taxFreeAmount'],
        tax_exemption_amount: cancel['taxExemptionAmount'],
        refundable_amount: cancel['refundableAmount'],
        easy_pay: cancel['easyPay'],
        transaction_key: cancel['transactionKey'],
        cancel_requested_at: cancel['cancelRequestedAt'],
        canceled_at: cancel['canceledAt']
      }
    end
  end
  
  # 결제 통계 (클래스 메서드)
  def self.statistics(start_date: nil, end_date: nil)
    query = all
    query = query.by_date_range(start_date, end_date) if start_date && end_date
    
    {
      total_count: query.count,
      total_amount: query.successful.sum(:total_amount),
      by_status: query.group(:status).count,
      by_method: query.group(:method).count,
      success_rate: query.successful.count.to_f / query.count * 100
    }
  end
end 