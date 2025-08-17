# frozen_string_literal: true

module Tosspayments
  module Rails
    module ViewHelpers
      # 토스페이먼츠 결제위젯 SDK 스크립트 태그
      def tosspayments_script_tag
        content_tag :script, "", src: "https://js.tosspayments.com/v2/standard"
      end

      # 토스페이먼츠 결제위젯 초기화 스크립트
      def tosspayments_widget_script(client_key: nil, options: {})
        client_key ||= Tosspayments::Rails.configuration.client_key
        
        raise Tosspayments::Rails::ConfigurationError, "Client key is required" if client_key.blank?

        script_content = <<~JAVASCRIPT
          const tossPayments = TossPayments('#{client_key}');
          
          // 결제위젯 초기화
          const widgets = tossPayments.widgets({
            customerKey: '#{options[:customer_key] || "ANONYMOUS"}'
          });
          
          // 결제 UI 렌더링
          const paymentWidget = widgets.renderPaymentMethods({
            selector: '#{options[:payment_selector] || "#payment-widget"}',
            variantKey: '#{options[:variant_key] || "DEFAULT"}'
          });
          
          // 이용약관 UI 렌더링
          widgets.renderAgreement({
            selector: '#{options[:agreement_selector] || "#agreement"}'
          });
        JAVASCRIPT

        content_tag :script, script_content.html_safe
      end

      # 결제 요청 함수 생성
      def tosspayments_payment_script(order_id:, amount:, order_name:, success_url:, fail_url:, options: {})
        script_content = <<~JAVASCRIPT
          async function requestTossPayment() {
            try {
              await widgets.requestPayment({
                orderId: '#{order_id}',
                orderName: '#{order_name}',
                successUrl: '#{success_url}',
                failUrl: '#{fail_url}',
                customerEmail: '#{options[:customer_email]}',
                customerName: '#{options[:customer_name]}',
                customerMobilePhone: '#{options[:customer_mobile_phone]}'
              });
            } catch (error) {
              console.error('결제 요청 실패:', error);
              alert('결제 요청에 실패했습니다.');
            }
          }
        JAVASCRIPT

        content_tag :script, script_content.html_safe
      end

      # 토스페이먼츠 브랜드페이 스크립트
      def tosspayments_brandpay_script(customer_key:, redirect_url:, options: {})
        client_key = Tosspayments::Rails.configuration.client_key
        
        script_content = <<~JAVASCRIPT
          const tossPayments = TossPayments('#{client_key}');
          
          // 브랜드페이 초기화
          const brandpay = tossPayments.brandpay({
            customerKey: '#{customer_key}',
            redirectUrl: '#{redirect_url}'
          });
          
          // 브랜드페이 결제수단 추가
          function addBrandpayMethod() {
            brandpay.addPaymentMethod();
          }
          
          // 브랜드페이 설정창 열기
          function openBrandpaySettings() {
            brandpay.openSettings();
          }
        JAVASCRIPT

        content_tag :script, script_content.html_safe
      end

      # 결제 폼을 위한 기본 HTML 구조
      def tosspayments_payment_form(order_id:, amount:, order_name:, options: {})
        content_tag :div, class: "tosspayments-payment-wrapper" do
          concat content_tag(:div, "", id: (options[:payment_selector] || "#payment-widget").delete("#"))
          concat content_tag(:div, "", id: (options[:agreement_selector] || "#agreement").delete("#"))
          concat content_tag(:button, "결제하기", 
                   onclick: "requestTossPayment()", 
                   class: "btn btn-primary tosspayments-payment-button",
                   style: "width: 100%; margin-top: 20px; padding: 15px; font-size: 16px; border: none; border-radius: 6px; background-color: #3282f6; color: white; cursor: pointer;"
                 )
        end
      end
    end
  end
end