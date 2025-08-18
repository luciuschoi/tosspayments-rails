# frozen_string_literal: true

class Payment < ApplicationRecord
  # 결제 상태 정의
  STATUSES = %w[
    pending ready waiting_for_deposit in_progress done canceled
    partial_canceled aborted expired
  ].freeze

  # 결제 수단 정의
  METHODS = %w[
    card virtual_account transfer mobile_phone gift_certificate
    easy_pay culture_gift_certificate book_culture_gift_certificate
    game_culture_gift_certificate
  ].freeze

  # Validations
  validates :order_id, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :method, inclusion: { in: METHODS }, allow_blank: true
  validates :payment_key, uniqueness: true, allow_blank: true
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Scopes
  scope :successful, -> { where(status: 'done') }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: %w[canceled aborted expired]) }
  scope :by_customer_email, ->(email) { where(customer_email: email) }

  # Callbacks
  before_validation :set_default_status, on: :create
  after_update :update_timestamps

  # 결제 성공 여부 확인
  def successful?
    status == 'done'
  end

  # 결제 실패 여부 확인
  def failed?
    %w[canceled aborted expired].include?(status)
  end

  # 결제 진행 중 여부 확인
  def in_progress?
    %w[ready waiting_for_deposit in_progress].include?(status)
  end

  # 결제 취소 가능 여부 확인
  def cancelable?
    %w[done partial_canceled].include?(status)
  end

  # TossPayments 웹훅 데이터로 결제 정보 업데이트
  def update_from_toss_webhook!(webhook_data)
    transaction do
      update!(
        payment_key: webhook_data['paymentKey'],
        status: webhook_data['status'],
        method: webhook_data['method'],
        paid_at: webhook_data['approvedAt'] ? Time.parse(webhook_data['approvedAt']) : nil,
        failed_at: failed? ? Time.current : nil,
        failure_code: webhook_data['failure']&.dig('code'),
        failure_reason: webhook_data['failure']&.dig('message'),
        raw_data: webhook_data.to_json
      )
    end
  end

  # 결제 승인 처리
  def approve!(toss_response)
    transaction do
      update!(
        payment_key: toss_response['paymentKey'],
        status: 'done',
        method: toss_response['method'],
        paid_at: Time.parse(toss_response['approvedAt']),
        raw_data: toss_response.to_json
      )
    end
  end

  # 결제 실패 처리
  def fail!(error_code, error_message)
    transaction do
      update!(
        status: 'aborted',
        failed_at: Time.current,
        failure_code: error_code,
        failure_reason: error_message
      )
    end
  end

  # 결제 취소 처리
  def cancel!(reason = nil)
    return false unless cancelable?

    transaction do
      update!(
        status: 'canceled',
        failed_at: Time.current,
        failure_reason: reason
      )
    end
  end

  # 원화 표시용 금액 포맷
  def formatted_amount
    "#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end

  def update_timestamps
    if status_changed?
      case status
      when 'done'
        self.paid_at ||= Time.current
      when 'canceled', 'aborted', 'expired'
        self.failed_at ||= Time.current
      end
    end
  end
end
