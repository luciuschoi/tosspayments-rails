# frozen_string_literal: true

# 토스페이먼츠 설정
# Rails credentials를 사용하여 안전하게 키를 관리합니다.
#
# 설정 방법:
# 1. rails credentials:edit 명령으로 credentials 파일을 엽니다
# 2. 다음과 같이 토스페이먼츠 설정을 추가합니다:
#
# tosspayments:
#   client_key: test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq  # 결제위젯 연동 키 > 클라이언트 키
#   secret_key: test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R  # 결제위젯 연동 키 > 시크릿 키
#   sandbox: true  # 개발환경에서는 true, 운영환경에서는 false

Tosspayments::Rails.configure do |config|
  # Rails credentials에서 자동으로 로드됩니다
  # 수동으로 설정하려면 아래 주석을 해제하세요 (보안상 권장하지 않음)

  # config.client_key = "<%= client_key_placeholder %>"
  # config.secret_key = "<%= secret_key_placeholder %>"
  # config.sandbox = true
end
