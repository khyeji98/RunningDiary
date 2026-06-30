# TC 매트릭스 — Apple 로그인 (LoginFeature)

> 이슈: #23
> 대상 Feature: `RunDiary/Sources/Features/Login/Core/LoginFeature.swift`
> 대상 테스트: `RunDiaryTests/LoginFeatureTests.swift`, `RunDiaryTests/AuthClientTests.swift`

## Reducer-level TC (LoginFeature)

각 행 = given State + send Action → expected State 변화 + received Actions.

| tc id | given | when | then (State 변화) | then (received) | 비고 |
|---|---|---|---|---|---|
| `login-appleSignIn-success` | `State()`, authClient→success(session), tokenClient.saveSession 성공 | `.appleSignInTapped` | `isLoading=true`, `errorMessage=nil` | `.signInResponse.success`(`isLoading=false`, `session=expected`) → `.delegate.signedIn` | 성공: saveSession 1회 호출 |
| `login-appleSignIn-serverError` | `State()`, authClient→failure(`.serverError`) | `.appleSignInTapped` | `isLoading=true` | `.signInResponse.failure`(`isLoading=false`, `errorMessage=serverError.localizedDescription`) | 서버 에러 메시지 노출 |
| `login-appleSignIn-cancelled` | `State()`, authClient→failure(`.cancelled`) | `.appleSignInTapped` | `isLoading=true` | `.signInResponse.failure`(`isLoading=false`, `errorMessage=nil`) | 사용자 취소: 메시지 미노출 |
| `login-signInResponse-tokenSaveFailure` | `State()`, authClient→success(session), tokenClient.saveSession→throw | `.appleSignInTapped` | `isLoading=true` | `.signInResponse.success`(`isLoading=false`, `session=nil`(롤백), `errorMessage=error.localizedDescription`), **`.delegate.signedIn` 미수신** | ⚠️ 기존 테스트 공백 — 신규 케이스 |

> 토큰 저장 실패 경로는 `LoginFeature` 구현(`signInResponse(.success)`의 catch)에 존재하나 기존 `LoginFeatureTests`에 없음. 명세화로 드러난 커버리지 공백 → 재작성 시 추가.

## Client-level TC (AuthClient)

| tc id | given (mock) | when | then | 비고 |
|---|---|---|---|---|
| `authclient-apple-returnsSession` | signInWithApple→session(.apple) | `signInWithApple()` | `== expectedSession` | |
| `authclient-google-returnsSession` | signInWithGoogle→session(.google) | `signInWithGoogle()` | `== expectedSession` | |
| `authclient-apple-throws` | signInWithApple→throw `.cancelled` | `signInWithApple()` | `throws AuthError.cancelled` | |

## 관련 커버리지 (파일럿 범위 밖, 확인만)
- `AppFeature`: `.login(.delegate(.signedIn))` → `route=.main` (AppFeatureTests).
- `AppFeature`: `.onAppear` → `tokenClient.hasValidSession()` 기반 `.main`/`.login`.

## 재작성 진행 체크리스트
- [ ] `LoginFeatureTests`·`AuthClientTests` 전체 주석화
- [ ] TC 단위 복원(작성→해제→실행→구현 검증)
- [ ] `login-signInResponse-tokenSaveFailure` 신규 추가
- [ ] 전부 GREEN, 주석 잔여 0, strict concurrency 경고 0
