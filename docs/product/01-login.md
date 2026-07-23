# 01. 로그인 (Apple Sign In)

> 대상: `RunDiary/Sources/Features/Login/Core/LoginFeature.swift`, `Views/LoginView.swift`, `Views/AppleSignInButton.swift`

## 목적
앱 진입 시 세션이 없을 때 표시되는 첫 화면. Apple 계정으로 로그인하고, 발급된 토큰을 키체인에 저장한 뒤 메인으로 진입시킨다. 서비스는 소셜 로그인 단일 방식(현재 Apple만 노출)을 지향한다.

## 진입 / 이탈
- **진입**: 앱 시작 시 `AppFeature.onAppear` → `tokenClient.hasValidSession()`이 false면 `.login` 라우트로 표시. (`AppFeature.swift:56-58`)
- **이탈**: 로그인 성공 → 토큰 키체인 저장 성공 시 `delegate(.signedIn)` 전송 → `AppFeature`가 `.main`으로 전환. (`LoginFeature.swift:66-69`, `AppFeature.swift:60-62`)

## 화면 구성 (UI)
`LoginView`는 세로 스택(VStack) 단일 화면. 위→아래로:

### 1) 타이틀 "달림일기"
- [목적] 브랜드 각인. 로그인 화면의 유일한 아이덴티티 요소.
- [정보 위계] 1차. 화면 상단 중앙.
- [현재 구현] 텍스트 타이틀. 별도 로고/일러스트 없음.
- [UX 의도] 감성적 러닝 기록 앱의 첫인상. Claude Design 재해석 시 로고·서브카피·배경 무드 제안 여지 큼.

### 2) 성공 정보 블록 (`successInfo`)
- [목적] 로그인 성공 직후 이름/이메일을 잠깐 확인시키는 피드백.
- [정보 위계] 2차. 성공 상태에서만 노출.
- [현재 구현] `state.session`이 존재할 때 이름·이메일 텍스트. (전환 직전 짧게 노출)
- [UX 의도] 전환 애니메이션 중 신뢰 피드백. 생략 가능/토스트화 후보.

### 3) 로딩 인디케이터
- [목적] 인증 진행 중임을 표시.
- [현재 구현] `state.isLoading`일 때 `ProgressView`.

### 4) 에러 텍스트
- [목적] 로그인 실패 사유 전달.
- [현재 구현] `state.errorMessage`가 있을 때 빨간 텍스트. **단, 사용자가 직접 취소한 경우(`AuthError.cancelled`)는 표시하지 않음.** (`LoginFeature.swift:79-84`)
- [UX 의도] 사용자 취소는 실패가 아니므로 침묵. 에러 스타일 토큰화 필요.

### 5) Apple 로그인 버튼 (`AppleSignInButton`)
- [목적] 인증 트리거.
- [정보 위계] 1차 액션. 하단.
- [현재 구현] Apple HIG 준수 `UIViewRepresentable`(`ASAuthorizationAppleIDButton`). 커스텀 스타일 불가 영역.
- [UX 의도] Apple 정책상 버튼 형태는 제약. 주변 여백·문구만 디자인 여지.

## 기능 / 인터랙션

| 동작 | Action | 결과 |
|------|--------|------|
| Apple 로그인 버튼 탭 | `appleSignInTapped` | `isLoading = true`, `authClient.signInWithApple()` 실행 (`:48-59`) |
| 인증 성공 | `signInResponse(.success)` | 세션 저장, `tokenClient.saveSession` 성공 시 `delegate(.signedIn)` (`:61-74`) |
| 토큰 저장 실패 | `signInResponse(.success)` 내부 catch | 세션 폐기, `errorMessage` 노출 (`:70-73`) |
| 인증 실패(취소 외) | `signInResponse(.failure)` | `errorMessage` 노출 (`:82-84`) |
| 사용자 취소 | `signInResponse(.failure)` + `AuthError.cancelled` | 에러 미표시 (`:80-81`) |

## 데이터
- **모델**: `AuthSession`(세션), `AuthError`(취소 등 인증 에러). (`Models`/`AuthService`)
- **의존성**: `authClient`(Apple 로그인 수행), `tokenClient`(키체인 세션 저장·유효성 판정).
- **인증 네트워크 스택**: CoreNetwork가 아닌 `SimpleNetwork`(외부 SPM) 기반 `AuthService`. baseURL은 `AppConfig.baseURL`(Info.plist `API_BASE_URL`).

## 구현 상태
- ✅ Apple 로그인 → 토큰 저장 → 메인 전환
- ✅ 사용자 취소 시 에러 침묵 처리
- ✅ 토큰 저장 실패 시 에러 노출
- ❌ 로그아웃/세션 만료 후 로그인 화면 복귀(=`AppFeature`의 `.signedOut` 처리 미구현, [backlog](./backlog.md) 참조)
- ❌ Apple 외 소셜 로그인 UI(코드상 `AuthProvider.google` 모델은 존재하나 화면 미노출)
