# frozen_string_literal: true

class PaymentDetailsController < ApplicationController
  before_action :set_payment_detail, only: [:show]
  
  # GET /payment_details
  def index
    @payment_details = PaymentDetail.recent
                                   .includes(:payable)
                                   .page(params[:page])
                                   .per(20)
    
    # 필터링
    @payment_details = @payment_details.by_status(params[:status]) if params[:status].present?
    @payment_details = @payment_details.by_method(params[:method]) if params[:method].present?
    
    # 날짜 필터
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @payment_details = @payment_details.by_date_range(start_date.beginning_of_day, end_date.end_of_day)
    end
    
    # 통계 정보
    @statistics = PaymentDetail.statistics(
      start_date: params[:start_date].present? ? Date.parse(params[:start_date]) : nil,
      end_date: params[:end_date].present? ? Date.parse(params[:end_date]) : nil
    )
  end
  
  # GET /payment_details/:id
  def show
    # 추가 결제 정보가 필요한 경우 토스페이먼츠 API에서 조회
    if @payment_detail.payment_key.present?
      client = Tosspayments::Rails::Client.new
      @latest_payment_info = client.get_payment(@payment_detail.payment_key)
    rescue => e
      Rails.logger.error "결제 정보 조회 실패: #{e.message}"
      @latest_payment_info = nil
    end
  end
  
  # GET /payment_details/statistics
  def statistics
    @statistics = PaymentDetail.statistics(
      start_date: params[:start_date].present? ? Date.parse(params[:start_date]) : nil,
      end_date: params[:end_date].present? ? Date.parse(params[:end_date]) : nil
    )
    
    respond_to do |format|
      format.html
      format.json { render json: @statistics }
    end
  end
  
  # POST /payment_details/:id/refresh
  def refresh
    @payment_detail = PaymentDetail.find(params[:id])
    
    if @payment_detail.payment_key.present?
      client = Tosspayments::Rails::Client.new
      payment_info = client.get_payment(@payment_detail.payment_key)
      
      # 결제 정보 업데이트
      @payment_detail.update!(
        status: payment_info[:status],
        method: payment_info[:method],
        total_amount: payment_info[:totalAmount],
        balance_amount: payment_info[:balanceAmount],
        supplied_amount: payment_info[:suppliedAmount],
        vat: payment_info[:vat],
        tax_free_amount: payment_info[:taxFreeAmount],
        approved_at: payment_info[:approvedAt],
        card: payment_info[:card],
        virtual_account: payment_info[:virtualAccount],
        transfer: payment_info[:transfer],
        mobile_phone: payment_info[:mobilePhone],
        gift_certificate: payment_info[:giftCertificate],
        foreign_easy_pay: payment_info[:foreignEasyPay],
        cash_receipt: payment_info[:cashReceipt],
        discount: payment_info[:discount],
        cancels: payment_info[:cancels],
        secret: payment_info[:secret],
        type: payment_info[:type],
        easy_pay: payment_info[:easyPay],
        country: payment_info[:country],
        failure: payment_info[:failure],
        currency: payment_info[:currency],
        receipt_url: payment_info[:receiptUrl]
      )
      
      redirect_to @payment_detail, notice: '결제 정보가 업데이트되었습니다.'
    else
      redirect_to @payment_detail, alert: '결제 키가 없습니다.'
    end
  rescue => e
    redirect_to @payment_detail, alert: "결제 정보 업데이트 실패: #{e.message}"
  end
  
  private
  
  def set_payment_detail
    @payment_detail = PaymentDetail.find(params[:id])
  end
end 