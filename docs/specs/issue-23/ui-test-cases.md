# UI Test Cases — LoginView

> 이슈: #23 / 대상: `RunDiary/Sources/Features/Login/Views/LoginView.swift`
> Phase C(스냅샷) 진입 시 이 표를 1:1 가이드로 사용. (현재 스냅샷 의존성 미도입 — 도입 후 채움)

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| `login-idle-light` | LoginView | `session=nil, isLoading=false, errorMessage=nil` | — | ko_KR / .large | Light | iPhone 15 | "달림일기" 타이틀 중앙, 하단 Apple 로그인 버튼(높이 50, 가로 꽉) | `login-idle-light.png` |
| `login-idle-dark` | LoginView | 위와 동일 | — | ko_KR / .large | Dark | iPhone 15 | 동일 구성, 다크 배경 | `login-idle-dark.png` |
| `login-loading-light` | LoginView | `isLoading=true` | — | ko_KR / .large | Light | iPhone 15 | 버튼 위 ProgressView, Apple 버튼 disabled(흐림) | `login-loading-light.png` |
| `login-loading-dark` | LoginView | `isLoading=true` | — | ko_KR / .large | Dark | iPhone 15 | 동일, 다크 | `login-loading-dark.png` |
| `login-error-light` | LoginView | `errorMessage="로그인에 실패했어요"` | — | ko_KR / .large | Light | iPhone 15 | 버튼 위 빨간 footnote 에러 텍스트(중앙 정렬) | `login-error-light.png` |
| `login-error-dark` | LoginView | 위와 동일 | — | ko_KR / .large | Dark | iPhone 15 | 동일, 다크 | `login-error-dark.png` |
| `login-error-a11y` | LoginView | `errorMessage` 동일 | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 15 | 확대 텍스트에서도 잘림/겹침 없음 | `login-error-a11y.png` |
| `login-success-light` | LoginView | `session=AuthSession(.apple, name, email)` | — | ko_KR / .large | Light | iPhone 15 | "로그인 성공" headline + 이름 + 보조색 이메일 | `login-success-light.png` |
| `login-success-dark` | LoginView | 위와 동일 | — | ko_KR / .large | Dark | iPhone 15 | 동일, 다크 | `login-success-dark.png` |

## 최소 커버리지 자가 점검
- [x] 상태 분기: idle / loading / error / success
- [x] Light/Dark 쌍 분리
- [x] 접근성 DynamicType (error)
- [ ] 에셋 매트릭스(컬러/타이포 토큰) — 스냅샷 도입 시 확정
