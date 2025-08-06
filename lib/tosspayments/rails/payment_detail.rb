# frozen_string_literal: true

module Tosspayments
  module Rails
    class PaymentDetail < ApplicationRecord
      # 결제 방법별 상수
      PAYMENT_METHODS = {
        'card' => '카드',
        'transfer' => '계좌이체',
        'virtual_account' => '가상계좌',
        'phone' => '휴대폰',
        'gift_certificate' => '상품권',
        'culture_gift_certificate' => '문화상품권',
        'book_gift_certificate' => '도서문화상품권',
        'game_gift_certificate' => '게임문화상품권'
      }.freeze

      # 결제 상태별 상수
      PAYMENT_STATUSES = {
        'ready' => '결제 대기',
        'in_progress' => '결제 진행 중',
        'done' => '결제 완료',
        'canceled' => '결제 취소',
        'partial_canceled' => '부분 취소',
        'aborted' => '결제 중단',
        'failed' => '결제 실패'
      }.freeze

      validates :payment_key, presence: true, uniqueness: true
      validates :order_id, presence: true
      validates :total_amount, presence: true, numericality: { greater_than: 0 }

      # 스코프 메서드들
      scope :recent, -> { order(approved_at: :desc) }
      scope :by_status, ->(status) { where(status: status) }
      scope :by_method, ->(method) { where(method: method) }
      scope :successful, -> { where(status: 'done') }
      scope :failed, -> { where(status: ['canceled', 'aborted', 'failed']) }
      scope :pending, -> { where(status: ['ready', 'in_progress']) }
      scope :by_date_range, ->(start_date, end_date) { 
        where(approved_at: start_date.beginning_of_day..end_date.end_of_day) 
      }

      # 인스턴스 메서드들
      def successful?
        status == 'done'
      end

      def failed?
        ['canceled', 'aborted', 'failed'].include?(status)
      end

      def pending?
        ['ready', 'in_progress'].include?(status)
      end

      def formatted_total_amount
        ActionController::Base.helpers.number_to_currency(total_amount, unit: '원', precision: 0)
      end

      def method_name
        PAYMENT_METHODS[method] || method
      end

      def status_name
        PAYMENT_STATUSES[status] || status
      end

      def card_info
        return nil unless card.present?
        
        {
          company: card['company'],
          number: card['number'],
          installment_plan_months: card['installment_plan_months'],
          is_interest_free: card['is_interest_free'],
          approve_no: card['approve_no'],
          use_card_point: card['use_card_point'],
          card_type: card['card_type'],
          owner_type: card['owner_type'],
          acquire_status: card['acquire_status'],
          amount: card['amount']
        }
      end

      def virtual_account_info
        return nil unless virtual_account.present?
        
        {
          account_type: virtual_account['account_type'],
          account_number: virtual_account['account_number'],
          due_date: virtual_account['due_date'],
          refund_status: virtual_account['refund_status'],
          expired: virtual_account['expired'],
          settlement_status: virtual_account['settlement_status']
        }
      end

      def transfer_info
        return nil unless transfer.present?
        
        {
          bank: transfer['bank'],
          settlement_status: transfer['settlement_status']
        }
      end

      def cancel_info
        return [] unless cancels.present?
        
        cancels.map do |cancel|
          {
            cancel_amount: cancel['cancel_amount'],
            cancel_reason: cancel['cancel_reason'],
            tax_free_amount: cancel['tax_free_amount'],
            tax_exemption_amount: cancel['tax_exemption_amount'],
            refundable_amount: cancel['refundable_amount'],
            easy_pay: cancel['easy_pay'],
            canceled_at: cancel['canceled_at'],
            transaction_key: cancel['transaction_key'],
            cancel_request_id: cancel['cancel_request_id'],
            acquirer_code: cancel['acquirer_code']
          }
        end
      end

      # 통계 메서드
      def self.statistics(start_date: nil, end_date: nil, status: nil, method: nil)
        scope = all
        
        scope = scope.by_date_range(start_date, end_date) if start_date && end_date
        scope = scope.by_status(status) if status
        scope = scope.by_method(method) if method
        
        {
          total_count: scope.count,
          total_amount: scope.sum(:total_amount),
          successful_count: scope.successful.count,
          failed_count: scope.failed.count,
          pending_count: scope.pending.count,
          average_amount: scope.average(:total_amount)&.round || 0
        }
      end

      # 토스페이먼츠 API 응답에서 PaymentDetail 객체 생성
      def self.from_api_response(response_data)
        new(
          payment_key: response_data['paymentKey'],
          order_id: response_data['orderId'],
          order_name: response_data['orderName'],
          method: response_data['method'],
          status: response_data['status'],
          total_amount: response_data['totalAmount'],
          balance_amount: response_data['balanceAmount'],
          supplied_amount: response_data['suppliedAmount'],
          vat: response_data['vat'],
          currency: response_data['currency'],
          card: response_data['card'],
          virtual_account: response_data['virtualAccount'],
          transfer: response_data['transfer'],
          cancels: response_data['cancels'],
          receipt_url: response_data['receiptUrl'],
          approved_at: response_data['approvedAt'] ? Time.parse(response_data['approvedAt']) : nil,
          use_escrow: response_data['useEscrow'],
          culture_expense: response_data['cultureExpense'],
          tax_free_amount: response_data['taxFreeAmount'],
          tax_exemption_amount: response_data['taxExemptionAmount']
        )
      end
    end
  end
end 