# UI Test Cases — LoginView

> 이슈: #23 / 대상: `RunDiary/Sources/Features/Login/Views/LoginView.swift`
> Phase C(스냅샷) 진입 시 이 표를 1:1 가이드로 사용. (현재 스냅샷 의존성 미도입 — 도입 후 채움)

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| `login-idle-light` | LoginView | `session=nil, isLoading=false, errorMessage=nil` | — | ko_KR / .large | Light | iPhone 15 | "달림일기" 타이틀 중앙, 하단 Apple 로그인 버튼(높이 50, 가로 꽉) | `login-idle-light.png` |
| `login-loading-light` | LoginView | `isLoading=true` | — | ko_KR / .large | Light | iPhone 15 | 버튼 위 ProgressView, Apple 버튼 disabled(흐림) | `login-loading-light.png` |
| `login-error-light` | LoginView | `errorMessage="로그인에 실패했어요"` | — | ko_KR / .large | Light | iPhone 15 | 버튼 위 빨간 footnote 에러 텍스트(중앙 정렬) | `login-error-light.png` |
| `login-error-a11y` | LoginView | `errorMessage` 동일 | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 15 | 확대 텍스트에서도 잘림/겹침 없음 | `login-error-a11y.png` |
| `login-success-light` | LoginView | `session=AuthSession(.apple, name, email)` | — | ko_KR / .large | Light | iPhone 15 | "로그인 성공" headline + 이름 + 보조색 이메일 | `login-success-light.png` |

## Dark 미포함 사유
앱은 Info.plist `UIUserInterfaceStyle=Light`로 라이트 고정이라 Dark는 실사용상 도달 불가 상태다. 또한 네이티브 `ASAuthorizationAppleIDButton`이 오프스크린 스냅샷에서 비결정적으로 렌더돼 로컬 record 레퍼런스가 CI 렌더와 픽셀 불일치(플레이키)를 유발하므로, Dark 케이스는 제외한다.

## 최소 커버리지 자가 점검
- [x] 상태 분기: idle / loading / error / success
- [x] Light 전용 (앱 라이트 고정 — Dark 미지원)
- [x] 접근성 DynamicType (error)
- [ ] 에셋 매트릭스(컬러/타이포 토큰) — 스냅샷 도입 시 확정
