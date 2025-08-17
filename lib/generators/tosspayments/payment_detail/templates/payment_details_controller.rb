# frozen_string_literal: true

class PaymentDetailsController < ApplicationController
  include Pagy::Backend
  before_action :set_payment_detail, only: [:show]

  def index
    @payment_details = PaymentDetail.recent

    # 필터링
    @payment_details = @payment_details.by_status(params[:status]) if params[:status].present?
    @payment_details = @payment_details.by_method(params[:method]) if params[:method].present?

    return unless params[:start_date].present? && params[:end_date].present?

    @payment_details = @payment_details.by_date_range(
      Date.parse(params[:start_date]),
      Date.parse(params[:end_date])
    )

    @pagy, @payment_details = pagy @payment_details, items: 10, page: params[:page]
  end

  def show
    # 결제 상세 정보는 이미 set_payment_detail에서 로드됨
  end

  def statistics
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 1.month.ago
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current

    @statistics = PaymentDetail.statistics(
      start_date: start_date,
      end_date: end_date,
      status: params[:status],
      method: params[:method]
    )

    respond_to do |format|
      format.html
      format.json { render json: @statistics }
    end
  end

  private

  def set_payment_detail
    @payment_detail = PaymentDetail.find_by!(payment_key: params[:id])
  end
end
