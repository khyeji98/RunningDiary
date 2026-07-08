# Login UI Test Cases (스냅샷 매트릭스)

대상 화면: `LoginView` (`RunDiary/Sources/Features/Login/Views/LoginView.swift`)
상태 소스: `LoginFeature.State { isLoading: Bool, session: AuthSession?, errorMessage: String? }`

고정 파라미터(전 케이스 공통): 디바이스 iPhone 15 / 지역 ko_KR / 시간·UUID 의존 없음. Light·Dark는 독립 행. 기본 DynamicType `.large`, 접근성 케이스만 `.accessibilityExtraLarge`.

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| login-screen-idle-light | LoginView | `isLoading=false`, `session=nil`, `errorMessage=nil` | — | ko_KR / .large | Light | iPhone 15 | 상단 중앙 "달림일기" 라지타이틀, 하단 검정 Apple 로그인 버튼(높이 50, 가로 꽉참). 로딩·에러·성공 정보 없음 | idle_light.login-screen-idle-light.png |
| login-screen-idle-dark | LoginView | `isLoading=false`, `session=nil`, `errorMessage=nil` | — | ko_KR / .large | Dark | iPhone 15 | idle-light와 동일 레이아웃, 다크 배경·흰색 타이틀. Apple 버튼은 `.black` 고정 스타일이라 검은 배경에 묻혀 로고·텍스트만 보임 | idle_dark.login-screen-idle-dark.png |
| login-screen-loading-light | LoginView | `isLoading=true`, `session=nil`, `errorMessage=nil` | — | ko_KR / .large | Light | iPhone 15 | 타이틀 아래 원형 ProgressView 표시, Apple 버튼 disabled(흐릿) | loading_light.login-screen-loading-light.png |
| login-screen-loading-dark | LoginView | `isLoading=true`, `session=nil`, `errorMessage=nil` | — | ko_KR / .large | Dark | iPhone 15 | loading-light와 동일, 다크 테마 | loading_dark.login-screen-loading-dark.png |
| login-screen-error-light | LoginView | `isLoading=false`, `session=nil`, `errorMessage="로그인에 실패했어요. 잠시 후 다시 시도해 주세요."` | — | ko_KR / .large | Light | iPhone 15 | 타이틀 아래 빨간색 footnote 에러 메시지(중앙 정렬, 멀티라인), 그 아래 Apple 버튼 | error_light.login-screen-error-light.png |
| login-screen-error-dark | LoginView | 위와 동일 `errorMessage` | — | ko_KR / .large | Dark | iPhone 15 | error-light와 동일, 다크 테마. 빨간 텍스트 대비 확인 | error_dark.login-screen-error-dark.png |
| login-screen-success-light | LoginView | `isLoading=false`, `session=<고정 AuthSession: name="러너", email="runner@example.com">`, `errorMessage=nil` | — | ko_KR / .large | Light | iPhone 15 | 타이틀 아래 "로그인 성공"(headline) + 이름 "러너" + 회색 이메일, 그 아래 Apple 버튼 | success_light.login-screen-success-light.png |
| login-screen-success-dark | LoginView | 위와 동일 session | — | ko_KR / .large | Dark | iPhone 15 | success-light와 동일, 다크 테마 | success_dark.login-screen-success-dark.png |
| login-screen-error-a11yXL | LoginView | `isLoading=false`, `session=nil`, `errorMessage="로그인에 실패했어요. 잠시 후 다시 시도해 주세요."` | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 15 | 접근성 초대형 텍스트에서 타이틀·에러 메시지가 확대되어도 잘림/겹침 없이 배치, 멀티라인 에러 2줄 래핑 | error_accessibilityExtraLarge.login-screen-error-a11yXL.png |

## 커버리지 자가 점검
1. 상태 분기: idle / loading / error / success 전부 커버 ✓
2. 테마 분기: 도메인 테마 분기 없음(—) ✓
3. 선택 필드 분기: `session` nil/존재(idle vs success), `errorMessage` nil/존재(idle vs error) ✓
4. Light/Dark 쌍: idle·loading·error·success 각 2행 ✓
5. 접근성 DynamicType: 텍스트 비중 큰 error 상태 1행(`.accessibilityExtraLarge`) ✓
