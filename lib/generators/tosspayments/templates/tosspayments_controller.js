// 토스페이먼츠 결제 위젯을 초기화하고 결제 요청을 처리하는 Stimulus 컨트롤러
// 설치 후 importmap 또는 번들러(webpack/esbuild 등)에 의해 자동 로드되도록
// controllers/index.js 에 등록되어야 합니다. (Rails 기본 stimulus:install 구조 가정)

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["payButton"]
  static values = {
    clientKey: String,
    customerKey: String,
    orderId: String,
    orderName: String,
    successUrl: { type: String, default: "/payments/success" },
    failUrl: { type: String, default: "/payments/fail" },
    prefix: { type: String, default: "tosspayments" }
  }

  connect() {
    this.setLoading(true, '위젯 초기화 중...')
    this.ensureSdk()
      .then(() => this.initWidgets())
      .catch((e) => {
        console.error("TossPayments SDK 초기화 실패", e)
        this.dispatchEvent('error', { error: e })
        this.setLoading(false)
      })
  }

  ensureSdk() {
    if (window.TossPayments) return Promise.resolve()
    return new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = "https://js.tosspayments.com/v2/standard"
      script.async = true
      script.onload = () => resolve()
      script.onerror = () => reject(new Error("Failed to load TossPayments SDK"))
      document.head.appendChild(script)
    })
  }

  async initWidgets() {
    try {
      this.tossPayments = window.TossPayments(this.clientKeyValue)
      this.widgets = this.tossPayments.widgets({
        customerKey: this.customerKeyValue || "ANONYMOUS"
      })

      await this.widgets.renderPaymentMethods({
        selector: `#${this.paymentWidgetElement.id}`,
        variantKey: "DEFAULT"
      })

      await this.widgets.renderAgreement({
        selector: `#${this.agreementElement.id}`
      })
      this.dispatchEvent('ready')
    } catch (e) {
      console.error("결제 위젯 초기화 실패", e)
      this.dispatchEvent('error', { error: e })
    } finally {
      this.setLoading(false)
    }
  }

  async requestPayment(event) {
    if (event) event.preventDefault()
    if (!this.widgets) {
      this.alertUser("결제 위젯이 아직 초기화되지 않았습니다. 잠시 후 다시 시도하세요.")
      return
    }
    this.setLoading(true, '결제 요청 중...')
    this.dispatchEvent('request:start')
    try {
      await this.widgets.requestPayment({
        orderId: this.orderIdValue,
        orderName: this.orderNameValue,
        successUrl: this.successUrlValue,
        failUrl: this.failUrlValue
      })
      this.dispatchEvent('request:submitted')
    } catch (error) {
      console.error("결제 요청 실패:", error)
      this.dispatchEvent('error', { error })
      this.alertUser("결제 요청에 실패했습니다.")
    } finally {
      this.setLoading(false)
    }
  }

  get paymentWidgetElement() {
    return this.element.querySelector('[data-role="payment-widget"]')
  }

  get agreementElement() {
    return this.element.querySelector('[data-role="agreement"]')
  }

  // UI Helpers
  setLoading(loading, text) {
    if (!this.hasPayButtonTarget) return
    const btn = this.payButtonTarget
    if (loading) {
      btn.dataset.originalText = btn.innerText
      btn.innerText = text || '처리 중...'
      btn.disabled = true
      btn.classList.add(`${this.prefixValue}-loading`)
    } else {
      if (btn.dataset.originalText) btn.innerText = btn.dataset.originalText
      btn.disabled = false
      btn.classList.remove(`${this.prefixValue}-loading`)
    }
  }

  alertUser(message) {
    // 추후 사용자 정의 alert hook 가능
    alert(message)
  }

  dispatchEvent(name, detail = {}) {
    this.element.dispatchEvent(new CustomEvent(`${this.prefixValue}:${name}`, { detail, bubbles: true }))
  }
}
