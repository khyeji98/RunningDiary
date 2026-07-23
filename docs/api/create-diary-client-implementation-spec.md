# 다이어리 생성 API 클라이언트 구현 명세

> 대상: RunDiary iOS 개발자
> 관련 계약: [다이어리 생성 API 요청 스키마 협의안](./create-diary-request.md)
> 목적: 현재 앱 상태와 목표 API 계약의 차이를 정의하고 구현·테스트 범위를 명확히 한다.

## 목표

HealthKit, WeatherKit, 사용자 입력으로 구성한 다이어리를 서버 생성 API에 안전하게 전송한다.

- HealthKit 원본 UUID를 운동 식별자로 보존한다.
- 화면 표시용 엔티티가 아닌 전용 API DTO를 사용한다.
- 동일 요청 재시도에서 중복 다이어리가 생성되지 않도록 멱등성을 보장한다.
- 대용량 route와 series를 서버 상한에 맞춰 결정적으로 다운샘플링한다.
- 날씨 자동 분류 수정 여부를 서버에 전달한다.

## 현재 상태와 차이

| 영역 | 현재 상태 | 필요한 작업 |
|---|---|---|
| 서버 생성 API | `RunningRecordClient.saveRecord`는 SwiftData에만 저장 | POST RequestAPI, 응답 DTO, 네트워크 Client 추가 |
| `workoutId` | `HealthKitWorkout.id`가 매번 새 UUID를 생성 | `HKWorkout.uuid` 보존 및 요청·로컬 저장 모델에 연결 |
| 시간 | `Date`와 `TimeInterval`만 보유 | UTC ISO 8601 문자열, IANA timezone, 정수 duration 매핑 |
| 미측정 지표 | 상세 조회 실패값을 `0`으로 치환 | 현재 정책 유지. 서버와 `0 = 미측정` 합의 및 DTO 테스트 |
| 페이스 | 표시용 `averagePace` 문자열 보유 | 숫자형 `paceSecondsPerKm`을 원본 거리·시간에서 계산하는 요청 매퍼 추가 |
| route | 전체 좌표를 저장하고 상한 없음 | 50,000점 제한, 원본 개수, 샘플링 방식 추가 |
| splits | 1km 구간 계산 및 1-based index 구현됨 | DTO 매핑 및 빈 배열 인코딩 검증 |
| series | 5초 버킷, HR/pace/cadence 최대 500점 | 원본 개수·방식 메타데이터, elevation 상한, DTO 매핑 추가 |
| 신발 | 서버 신발 API의 `Shoe.id` 선택, UI에서 필수 | Mongo ObjectId 검증 및 필수 `shoeId` 매핑 |
| 메모 | 빈 문자열만 `nil` 처리, 길이 제한 없음 | 공백 처리 정책 및 2,000자 제한 추가 |
| 날씨 수정 상태 | 자동값과 최종값은 상태에 존재하지만 수정 여부 필드 없음 | `categoryAdjusted` 계산·보존·전송 |
| 멱등성 | 생성 요청 및 키 상태 없음 | UUID 생성, 재시도 간 키 유지, payload 변경 시 키 갱신 |

## 구현 범위

### 1. HealthKit 운동 식별자 보존

`HKWorkout.uuid`를 별도의 명시적인 프로퍼티로 보존한다. 화면용 `Identifiable.id`와 서버 중복 방지용 `workoutId`를 혼용하지 않는다.

필요 작업:

1. `HealthKitWorkout`에 HealthKit 원본 UUID를 추가한다.
2. 경량 조회와 상세 조회 모두 동일한 `HKWorkout.uuid`를 매핑한다.
3. 상세 재조회는 가능하면 시작 시각이 아니라 UUID를 기준으로 대상을 식별한다.
4. SwiftData 모델에 `workoutId`를 저장한다.
5. 기존 로컬 데이터에는 UUID가 없으므로 optional migration 또는 기존 기록 업로드 제외 정책을 적용한다.

### 2. 서버 요청 DTO와 매퍼

앱 도메인 모델을 직접 `Encodable`로 만들지 않고 서버 계약 전용 타입을 추가한다.

권장 구조:

```text
CreateDiaryRequest
├── WorkoutRequest
│   ├── RoutePointRequest
│   ├── WorkoutSplitRequest
│   └── WorkoutSeriesRequest
├── WeatherRequest
└── DiaryInputRequest
```

DTO 매퍼의 책임:

- `HKWorkout.uuid`를 `workoutId` 문자열로 변환
- `Date`를 UTC ISO 8601 `Z` 문자열로 변환
- `TimeZone.current.identifier`를 `timeZone`으로 설정
- `duration`을 반올림한 정수 초로 변환
- 거리와 운동시간을 기준으로 `paceSecondsPerKm` 계산
- HealthKit 값의 단위를 API 계약 단위로 변환
- 화면 표시용 `averagePace` 문자열은 사용하지 않음
- `route`, `series`, `memo`, `weather`가 없을 때 명시적 JSON `null` 인코딩
- `splits`, `painAreas`, 개별 series가 없을 때 빈 배열 인코딩

Swift 합성 `Encodable`은 optional `nil` 키를 생략하므로, 서버가 명시적 `null`을 요구하는 필드는 커스텀 `encode(to:)` 또는 동등한 인코딩 전략이 필요하다.

### 3. 다이어리 생성 네트워크 Client

필요 구성:

- POST용 `CreateDiaryRequestAPI`
- 인증 헤더 구성
- 성공 응답 DTO
- 서버 오류 body 및 오류 코드 디코딩
- `409`를 중복 workout과 멱등성 충돌로 구분하는 도메인 오류
- 로컬 저장과 서버 저장의 실행 순서 및 실패 복구 정책

저장 순서는 별도 결정이 필요하다.

| 방식 | 장점 | 위험 |
|---|---|---|
| 서버 성공 후 로컬 저장 | 서버와 로컬의 성공 상태가 명확함 | 서버 성공 후 로컬 저장 실패 복구 필요 |
| 로컬 저장 후 서버 전송 | 오프라인 작성에 유리함 | 동기화 상태와 재전송 큐 필요 |

오프라인 생성이 요구사항이 아니라면 초기 구현은 서버 성공 후 로컬 저장을 기본안으로 검토한다.

### 4. Idempotency-Key 생명주기

`Idempotency-Key`는 헤더 계산 시마다 생성하면 안 된다. 하나의 논리적 요청과 함께 저장해야 한다.

권장 상태:

```text
payload + idempotencyKey + submissionState
```

규칙:

- 최초 저장 탭에서 UUID 생성
- 타임아웃, 401 token refresh, 5xx 재시도에서 같은 키 유지
- 사용자가 입력을 수정하면 이전 제출을 취소하고 새 키 생성
- 성공 또는 취소 후 키 폐기
- 앱 재실행 후 자동 재시도를 지원한다면 payload와 키를 함께 영속화

### 5. route 제한 및 메타데이터

현재 경로 조회 배열을 기준으로 `routeOriginalPointCount`를 계산한다.

다운샘플링 요구사항:

- 원본이 50,000점 이하이면 그대로 사용
- 50,000점 초과 시 최대 50,000점으로 축소
- 첫 지점과 마지막 지점 보존
- 같은 입력에 항상 같은 출력이 나오는 결정적 알고리즘 사용
- 위도·경도 순서 및 시간 순서 보존

초기 후보는 균등 인덱스 샘플링이다. 경로 형태 보존 품질이 부족하면 Douglas-Peucker 같은 공간 기반 단순화를 별도로 비교한다.

메타데이터:

- 미적용: `routeSamplingMethod = "none"`
- 균등 샘플링: `routeSamplingMethod = "uniform"`
- `routeOriginalPointCount`는 다운샘플링 전 좌표 개수

현재 구현은 첫 번째 `HKWorkoutRoute`만 사용한다. HealthKit이 여러 route sample을 반환하는 경우 결합할지 첫 항목만 사용할지 정책과 테스트가 필요하다.

### 6. series 메타데이터와 상한

현재 HR, pace, cadence는 5초 버킷 평균 후 최대 500점으로 축소하므로 서버 상한 2,000점을 충족한다.

추가 작업:

- 각 지표의 다운샘플링 전 `originalSampleCount` 수집
- 적용한 `samplingMethod` 기록
- elevation에도 최대 2,000점 상한 적용
- 모든 지표가 비면 `series: null`
- 개별 지표가 비면 해당 배열 `[]`
- 지표별 메타데이터 DTO 추가

제안 sampling method 값:

| 값 | 의미 |
|---|---|
| `none` | 원본 배열 사용 |
| `fixedIntervalAverage` | 고정 시간 버킷의 평균값 사용 |
| `uniform` | 최대 개수에 맞춘 균등 인덱스 선택 |

### 7. 사용자 입력 검증

- `shoeId`는 필수이며 Mongo ObjectId 형식의 24자리 hexadecimal 문자열인지 검증한다.
- `painAreas`가 비어 있으면 `[]`로 보낸다.
- 메모가 비어 있으면 `null`로 보낸다.
- 메모는 최대 2,000자로 제한한다.
- 공백만 있는 메모를 `null`로 볼지 서버와 동일한 trim 정책을 사용한다.

현재 화면은 신발 선택을 필수로 검증하므로 `shoeId: null` 경로는 구현하지 않는다.

### 8. 날씨 수정 상태

`categoryAdjusted`는 다음 네 카테고리 중 하나라도 자동 분류값과 최종 확정값이 다를 때 `true`다.

- `skyCondition`
- `windLevel`
- `feelsLike`
- `humidityLevel`

사용자가 값을 변경했다가 자동 분류값으로 되돌리면 `false`다. 이를 계산하려면 자동 분류 원본과 최종 선택값을 요청 생성 시점까지 모두 보존해야 한다.

날씨 조회 실패 시 `weather: null`이며 `categoryAdjusted`만 단독으로 보내지 않는다.

## TDD 구현 순서

코드 구현 시 프로젝트 규칙에 따라 테스트를 먼저 추가한다.

1. HealthKit UUID 매핑 및 보존 테스트
2. 날짜·timezone·duration·단위 변환 DTO 매퍼 테스트
3. 0 기본값과 null/빈 배열 JSON 인코딩 테스트
4. route 0점, 50,000점, 50,001점 및 결정성 테스트
5. series 원본 개수·메서드·2,000점 상한 테스트
6. `categoryAdjusted` 상태 전이 테스트
7. memo 2,000자 및 필수 shoe 검증 테스트
8. 동일 payload 재시도에서 Idempotency-Key 유지 테스트
9. 401, 409, 5xx 오류 매핑과 재시도 테스트
10. 서버 성공과 로컬 저장 연계 테스트

프로젝트 테스트 규칙을 따른다.

- Swift Testing의 `@Test`에 한국어 설명 사용
- TestStore 또는 SUT 생성은 private `make*` 헬퍼로 캡슐화
- 기대값을 action/assertion 전에 상수로 선언
- TCA reducer는 `await store.send`, `await store.receive` 패턴 사용

## 핵심 테스트 케이스

| ID | 시나리오 | 기대 결과 |
|---|---|---|
| `DTO-01` | 동일 HKWorkout을 두 번 매핑 | 동일한 `workoutId` |
| `DTO-02` | 미측정 스칼라 지표 | 해당 값 `0` |
| `DTO-03` | 경로 없음 | JSON에 `"route": null` 포함 |
| `DTO-04` | splits 없음 | JSON에 `"splits": []` 포함 |
| `DTO-05` | series 없음 | JSON에 `"series": null` 포함 |
| `DTO-06` | 통증 및 메모 없음 | `painAreas: []`, `memo: null` |
| `ROUTE-01` | route 50,000점 | 원본 유지, method `none` |
| `ROUTE-02` | route 50,001점 | 최대 50,000점, 양 끝 보존, method `uniform` |
| `SERIES-01` | 원본 3,000점 | 결과 2,000점 이하, 원본 개수 보존 |
| `WEATHER-01` | 자동값과 최종값 동일 | `categoryAdjusted: false` |
| `WEATHER-02` | 한 카테고리 변경 | `categoryAdjusted: true` |
| `IDEM-01` | 같은 요청 재시도 | 같은 `Idempotency-Key` |
| `IDEM-02` | 입력 변경 후 새 요청 | 새로운 `Idempotency-Key` |
| `ERROR-01` | 기존 workoutId로 새 요청 | duplicate workout 도메인 오류 |

## 수용 기준

- 서버 생성 요청에 HealthKit 원본 UUID가 포함된다.
- 동일 운동과 동일 요청 재시도로 중복 레코드가 생성되지 않는다.
- 요청의 날짜, timezone, 단위, null 및 빈 배열 표현이 서버 계약과 일치한다.
- route는 50,000점, series 각 지표는 2,000점을 초과하지 않는다.
- 모든 다운샘플링은 결정적이며 원본 개수와 적용 방식을 함께 보낸다.
- 신발은 Mongo ObjectId 형식의 필수값이다.
- 날씨 수정 여부가 자동 분류값과 최종값 비교로 정확히 계산된다.
- 409 응답 원인을 사용자 또는 재시도 정책이 구분할 수 있다.
- 관련 단위 테스트와 reducer 테스트가 통과한다.

## 구현 전 확인이 필요한 항목

1. 서버가 미측정 스칼라 값 `0` 정책을 수용하는지
2. POST endpoint, 인증 방식, 성공 response body
3. idempotency replay 및 충돌 응답 정책
4. series 메타데이터의 최종 JSON 형태
5. 기존 로컬 다이어리를 서버에 동기화할지 여부
6. 서버 저장과 로컬 저장의 순서 및 오프라인 지원 여부
7. 여러 `HKWorkoutRoute`가 존재할 때 결합 정책

위 항목이 확정되기 전에는 네트워크 요청 DTO의 공개 계약과 재시도 로직을 최종 구현하지 않는다.
