## [Unreleased]

### Added

- PaymentDetail 모델 및 자동 저장 기능 추가
- 결제 상세 정보 저장을 위한 제너레이터 (`rails generate tosspayments:payment_detail`)
- 결제 내역 조회 및 통계 기능
- 결제 방법별, 상태별 필터링 기능
- 상세한 결제 정보 관리 (카드, 가상계좌, 취소 정보 등)

### Changed

- Ruby 버전 요구사항을 3.1.2+로 변경하여 더 넓은 호환성 제공
- Rails 8 (8.x) 버전 지원 범위 추가 (의존성: '>= 7.0', '< 9.0')

## [0.1.0] - 2025-01-21

### Added

- 토스페이먼츠 결제 API 클라이언트 구현
- Rails 7+ 통합 지원
- Rails credentials를 통한 안전한 설정 관리
- 결제위젯 뷰 헬퍼 제공
- 컨트롤러 헬퍼로 결제 승인, 취소, 조회 기능 제공
- 브랜드페이 연동 지원
- 웹훅 처리 지원
- Rails 제너레이터로 빠른 설정
- Zeitwerk 기반 자동 로딩
- Faraday를 사용한 HTTP 클라이언트
- 상세한 사용 예제 및 문서 제공
