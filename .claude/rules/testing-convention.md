# Testing Convention

## Framework
Swift Testing (`@Test`, `#expect`) + TCA TestStore

## Strict Rules

1. **한국어 설명**: `@Test` 매크로에 반드시 한국어 설명을 작성한다. (e.g., `@Test("버튼 클릭 시 카운트 증가")`)
2. **`make*` 헬퍼**: `TestStore` 또는 SUT 생성은 반드시 `private` 헬퍼 함수로 캡슐화한다. (e.g., `makeTestStore`)
3. **기대값 상수**: 단언(assertion) 전에 기대값을 상수로 선언한다. (e.g., `let expectedCount = 3`)
4. **TCA 패턴**: Dependency mock은 `withDependencies`를 사용한다.
5. **네이밍**: 함수명은 `trigger_result` snake_case 패턴을 따른다.
6. **Given-When-Then**: 주석으로 구조를 명시한다.

## Template

```swift
@Test("테스트 시나리오 설명(한글)")
func trigger_result() async {
    // Given
    let expectedVal = ...
    let store = makeTestStore(initialState: ...)

    // When
    await store.send(.action) {
        // Then
        $0.property = expectedVal
    }
}

// Helper (private extension)
private extension {FeatureName}Tests {
    func makeTestStore(
        initialState: {FeatureName}.State = .init()
    ) -> TestStore<{FeatureName}.State, {FeatureName}.Action> {
        TestStore(initialState: initialState) {
            {FeatureName}()
        } withDependencies: {
            $0.{dependency} = .mock
        }
    }
}
```

## Dependency Mock 패턴

```swift
// Dependency mock은 withDependencies로 주입
TestStore(initialState: .init()) {
    MyFeature()
} withDependencies: {
    $0.myClient.fetch = { _ in .mock }
}
```

## 작업 흐름: 명세-우선 테스트 재작성

이 프로젝트의 테스트는 **forward TDD(테스트 먼저 → 구현)가 아니다.** 기능은 이미 구현돼 있으며, 테스트는 다음 흐름으로 작성·재작성한다.

1. **명세화**: 구현된 동작을 GitHub 이슈로 명세(현재 동작 = 의도된 동작인지 확정).
2. **TC 도출**: 명세 → TC 매트릭스(`docs/specs/issue-{이슈번호}/`). 각 행 = given State + Action → State 변화 + received.
3. **재작성**: 대상 테스트 파일의 모든 `@Test`를 **전체 주석화** → TC 하나씩 (작성 → 주석 해제 → 실행 → 명세 불일치 시 구현 수정) 복원.
4. **종료조건**: 전부 GREEN + 주석 잔여 0 + strict concurrency 경고 0.

> **스펙 디렉토리 네이밍 (표준)**: 폴더명은 이슈 타입과 무관하게 `issue-{이슈번호}`로 통일한다(예: 이슈 #23 → `docs/specs/issue-23/`). `#`는 경로명에 쓰지 않는다. 권위 출처는 `feature-respec-tc` 스킬.

진입 시점에만 리프 문서를 읽는다: `.claude/rules/phases/phase-a-reducer-respec.md` → `phase-b-ui-cases.md` → `phase-c-snapshot.md`.
스킬 `feature-respec-tc`로 1~3단계를 시작한다.

## 스냅샷 테스트 (swift-snapshot-testing)

- UI 화면은 `pointfreeco/swift-snapshot-testing`으로 시각 회귀를 보호한다(`__Snapshots__/` git 추적).
- 케이스는 `docs/specs/issue-{이슈번호}/ui-test-cases.md`(9컬럼 매트릭스)와 1:1 대응.
- **record 1회성 운용**: 신규 케이스만 1회 record 후 즉시 OFF. 코드에 record 상태를 남긴 채 머지 금지(회귀 보호 무력화).
- 고정 파라미터(디바이스 iPhone 15 / ko_KR / DynamicType / 명·암 별도 케이스 / 시간·UUID mock).
