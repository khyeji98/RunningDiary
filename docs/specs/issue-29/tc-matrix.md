# TC 매트릭스 — HealthKitClient delegation

> 이슈: #29
> 대상 Client: `RunDiary/Sources/Clients/HealthKitClient/HealthKitClient.swift`
> 대상 테스트: `RunDiaryTests/HealthKitClientTests.swift`
> 주입 프로토콜: `Dependencies/HealthKitService/Sources/HealthKitService/HealthKitManagerProtocol.swift`

## 배경

`HealthKitClient`는 각 클로저가 대응 매니저 메서드로 위임하는 **순수 passthrough**다. 입력 검증/변환을 하지 않는다.
기존 테스트는 하드코딩 클로저를 직접 주입해 "넣은 값이 그대로 나오는지"만 확인했다(무의미). 본 재작성은
`HealthKitClient.live(manager:)` seam에 `StubHealthKitManager`를 주입해 **실제 배선(delegation)** 을 검증한다.

Reducer가 아닌 Client이므로 UI/스냅샷(phase B/C)은 대상이 아니다.

## Client-level TC (HealthKitClient)

각 행 = given(StubHealthKitManager 구성) + when(Client 클로저 호출) → then(반환/에러/위임).

| tc id | given (StubHealthKitManager) | when | then | 비고 |
|---|---|---|---|---|
| `hkclient-weekly-returnsData` | `weeklyResult=.success([w1,w2,w3])` | `fetchRunningDataBetweenDates(from,to)` | 동일 배열 반환(count==3, 각 값 일치) | 정상 위임 |
| `hkclient-weekly-empty` | `weeklyResult=.success([])` | `fetchRunningDataBetweenDates(from,to)` | `[]` 반환 | 빈 결과 |
| `hkclient-weekly-throws` | `weeklyResult=.failure(.dataNotFound)` | `fetchRunningDataBetweenDates(from,to)` | `HealthKitError.dataNotFound` 재전파 | 에러 전파 |
| `hkclient-weekly-forwardsDates` | 인자 기록 stub, `from>to`(역순) | `fetchRunningDataBetweenDates(from,to)` | `capturedWeeklyDates == (from,to)` (역순도 검증 없이 전달) | 인자 전달 + 무검증 문서화 |
| `hkclient-weekly-callsCorrectMethod` | weekly/detailed 서로 다른 값 | `fetchRunningDataBetweenDates(from,to)` | `didCallWeekly==true`, `didCallDetailed==false` | 교차 오호출 방지 |
| `hkclient-detailed-returnsData` | `detailedResult=.success(w)` | `fetchDetailedRunningData(from,to)` | `w` 반환 | 정상 위임 |
| `hkclient-detailed-returnsNil` | `detailedResult=.success(nil)` | `fetchDetailedRunningData(from,to)` | `nil` 반환 | 데이터 없음 |
| `hkclient-detailed-throws` | `detailedResult=.failure(.notAvailable)` | `fetchDetailedRunningData(from,to)` | `HealthKitError.notAvailable` 재전파 | 에러 전파 |
| `hkclient-detailed-forwardsDates` | 인자 기록 stub | `fetchDetailedRunningData(from,to)` | `capturedDetailedDates == (from,to)` | 인자 전달 |
| `hkclient-detailed-callsCorrectMethod` | weekly/detailed 서로 다른 값 | `fetchDetailedRunningData(from,to)` | `didCallDetailed==true`, `didCallWeekly==false` | 교차 오호출 방지 |

## 표준 커버리지 자가 점검
- ✓ 액션별 정상 경로 (`returnsData` × 2)
- ✓ 실패/에러 경로 (`throws` × 2, 서로 다른 에러 케이스)
- ✓ 도메인 특수 분기 (`returnsNil`, `empty`)
- ✓ 인자 전달 정확성 (`forwardsDates` × 2, 역순 포함)
- ✓ 위임 대상 정확성 (`callsCorrectMethod` × 2)
- ✓ 사용자 노출 에러 타입 정확성 (`HealthKitError` 재전파)

## 명세-우선 재작성 흐름 (phase-a-reducer-respec.md)
1. `HealthKitClientTests.swift` 기존 `@Test` **전체 주석화**(빌드 가능 유지).
2. TC 하나씩: 작성 → 주석 해제 → `xcodebuild test` → 불일치(RED) 시 구현(seam) 수정, 명세 틀리면 이슈/TC 재검토 → GREEN.
3. 반복.

## 종료 조건
- [ ] `HealthKitClient.live(manager:)` seam 도입, `liveValue = .live()`.
- [ ] 위 TC 10건 전부 GREEN.
- [ ] 주석 잔여 0 (기존 passthrough 테스트 모두 대체·삭제).
- [ ] Swift strict concurrency 경고 0 (`SWIFT_STRICT_CONCURRENCY: complete`).
- [ ] `healthKitClient` 소비처(`RunningRecordClient`/`DailyDetailFeature`/`CreateDiaryFeature`) 회귀 없음.
