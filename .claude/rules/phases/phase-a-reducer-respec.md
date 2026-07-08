# Phase A′ — Reducer 테스트 재작성 (명세-우선)

> 이 문서는 **Phase A′ 진입 시점에만** 읽는다. 미리 전체를 읽지 않는다.

## 목적
이미 구현된 TCA Feature의 동작을 **명세(GitHub 이슈)로 고정**하고, 그 명세에서 도출한 **TC(테스트 케이스)** 를 기준으로 기존 Reducer/Client 테스트를 **재작성·복원**한다.
정통 forward TDD(테스트 먼저 → 구현)가 아니다. 구현은 이미 존재하며, "명세 → TC → 테스트 재작성, 그 과정에서 구현 검증·수정"이 핵심이다.

## 진입 전제조건 (모두 충족)
- 대상 이슈에 기능 명세 + 정책 결정 + Action/Dependency 매핑이 작성됨.
- `docs/specs/issue-{이슈번호}/` 에 **TC 매트릭스**가 도출됨 (TODO 0개).
- 대상 테스트 파일이 식별됨.

미충족 시: 이슈/TC 매트릭스 작성으로 돌아간다.

## TC 매트릭스 (단일 진실 소스)
각 행 = `given State` + `send Action` → `expected State 변화` + `received Actions`.

| tc id | given (initial State) | when (Action) | then (State 변화) | then (received) | 비고 |
|---|---|---|---|---|---|
| `<feature>-<action>-<variant>` | … | `.appleSignInTapped` | `isLoading=true` | `.signInResponse.success` → `.delegate.signedIn` | 성공 경로 |

표준 커버리지 체크리스트:
- ✓ 액션별 정상 경로
- ✓ 실패/에러 경로 (서버 에러, 디코딩 실패 등)
- ✓ 사용자 취소 등 도메인 특수 분기
- ✓ 낙관적 업데이트 → 실패 시 롤백
- ✓ delegate / dismiss / 자식 Feature 통합
- ✓ computed property
- ✓ 사용자 노출 에러 메시지 정확성

## 재작성 작업 흐름 (RED 역할 = 주석 해제 후 불일치)
대상 테스트 파일 단위로:

1. **전체 주석화** — 파일 내 모든 `@Test` 케이스를 주석 처리한다(빌드 가능 상태 유지).
2. TC 하나당 사이클:
   1. TC 매트릭스의 해당 행을 `@Test` 케이스로 (재)작성.
   2. 해당 케이스 **주석 해제**.
   3. `xcodebuild test`(또는 Xcode) 실행.
   4. **불일치(RED)** → 의도된 명세가 옳으면 **구현(Reducer/Client/Mapper) 수정**, 명세/TC가 틀렸으면 **이슈·TC 매트릭스 재검토**.
   5. **GREEN** → 다음 TC로.
3. 모든 TC 복원 완료까지 반복.

## 테스트 컨벤션 (`.claude/rules/testing-convention.md` 준수)
- 한국어 `@Test("…")` 설명.
- `TestStore`/SUT 생성은 `make*` private 헬퍼로 캡슐화.
- 기대값은 단언 전에 상수로 선언.
- Dependency mock은 `withDependencies`로 주입.
- 함수명 `trigger_result` snake_case.
- Given-When-Then 주석.
- `await store.send(...)` / `await store.receive(...)` 사용. 비결정적 effect는 `exhaustivity = .off` + `skipReceivedActions()`.

## 종료 조건 (Phase B 진입 전)
- 파일 내 모든 기존 케이스가 TC 근거로 복원됨.
- 전부 GREEN.
- **주석 잔여 0** (주석화했던 테스트가 모두 복원/삭제됨).
- Swift strict concurrency 경고 0 (`SWIFT_STRICT_CONCURRENCY: complete`).
- 이슈 명세의 모든 Action 커버.

## 안티 패턴
| 안티 패턴 | 문제점 |
|---|---|
| 주석화 없이 한 번에 전체 재작성 | 케이스별 명세-구현 대조(RED) 소실 |
| 불일치를 분석 없이 테스트를 구현에 맞춰 수정 | 잘못된 동작을 명세로 고착 |
| private 상태 직접 검증 | 공개 State/`@ObservableState`만 관찰 |
| async에서 sleep 대기 | 플레이키. `await receive` 활용 |
| 명세 없이 TC 작성 | "TC 기반"이 무력화 |

## 다음 단계
종료 조건 충족 → `phase-b-ui-cases.md` 개시 (UI 화면이 있는 경우).
