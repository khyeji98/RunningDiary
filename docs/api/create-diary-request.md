# 다이어리 생성 API 요청 스키마 협의안

> 대상: 백엔드 개발자
> 목적: HealthKit 데이터 확장에 맞춰 다이어리 생성 API의 요청 계약을 확정한다.
> 상태: 클라이언트 결정사항 반영 완료, 일부 서버 확인 필요

이 문서는 앱 내부 `Diary`나 화면 표시용 엔티티를 그대로 직렬화하는 명세가 아니다. HealthKit에서 조회한 원본 값과 통계값을 JSON 기본 타입 및 합의된 단위로 변환한 API 요청 DTO를 정의한다.

클라이언트 구현 범위와 수용 기준은 [다이어리 생성 API 클라이언트 구현 명세](./create-diary-client-implementation-spec.md)를 참고한다.

## 클라이언트 결정사항

| 항목 | 결정 |
|---|---|
| 신발 | 신발 API에서 받은 Mongo ObjectId를 `shoeId`로 전송한다. 현재 UX에서 신발 선택은 필수다. |
| 운동 식별자 | HealthKit DB의 `HKWorkout.uuid`를 `workoutId`로 전송한다. 동일 운동은 항상 같은 값을 사용한다. |
| 시간 | `startTime`, `endTime`은 UTC ISO 8601 `Z` 형식으로 보내고, 기기의 IANA timezone identifier를 `timeZone`으로 함께 보낸다. |
| 운동 시간 | `HKWorkout.duration`을 반올림한 정수 초로 보낸다. 이 값은 HealthKit의 일시정지 구간을 제외한 기록 시간이다. |
| 미측정 지표 | 클라이언트는 미측정 HealthKit 스칼라 지표에 `0`을 기본값으로 사용한다. 서버는 해당 필드의 `0`을 미측정으로 해석해야 한다. |
| 페이스 | 화면 표시용 `averagePace` 문자열을 요청 데이터의 기준으로 사용하지 않는다. 숫자형 페이스는 HealthKit 원본 거리와 운동시간 또는 `runningSpeed` 샘플로 계산한다. |
| route | 경로가 없으면 `null`로 보낸다. 50,000점을 초과하면 클라이언트 다운샘플링을 적용한다. |
| splits | 데이터가 없으면 `[]`로 보내고, `index`는 1부터 순차 증가한다. |
| series | 수집할 수 없으면 `null`로 보낸다. 수집 시 지표당 최대 2,000점을 넘지 않는다. |
| 사용자 입력 | 통증이 없으면 `painAreas: []`, 메모가 없으면 `memo: null`로 보낸다. |
| 날씨 | 원시 수치와 사용자가 최종 확정한 카테고리를 모두 보내고, 수정 여부를 `categoryAdjusted`로 보낸다. |

## 요청 헤더

| 헤더 | 필수 | 설명 |
|---|---|---|
| `Authorization` | ✅ | Bearer access token |
| `Content-Type` | ✅ | `application/json` |
| `Idempotency-Key` | ✅ | 다이어리 생성 시 발급한 UUID. 동일 요청의 재시도에서는 같은 값을 유지한다. |

`Idempotency-Key`는 논리적인 생성 요청 단위로 관리한다.

- 네트워크 오류나 401 갱신 후 같은 body를 재전송하면 기존 키를 유지한다.
- 사용자가 입력값을 변경해 새로운 생성 요청을 시작하면 새 키를 발급한다.
- 같은 키에 다른 body가 전달되는 경우의 오류 코드는 서버 정책 확인이 필요하다.

## 요청 바디 예시

```json
{
  "workout": {
    "workoutId": "9f29b8d7-6a63-4f24-a1ac-62257c519f94",
    "startTime": "2026-07-12T06:30:00Z",
    "endTime": "2026-07-12T07:12:30Z",
    "timeZone": "Asia/Seoul",
    "distance": 7.42,
    "duration": 2550,
    "paceSecondsPerKm": 344,
    "averageHeartRate": 152,
    "averageCadence": 174,
    "activeEnergyBurned": 512.3,
    "runningVerticalOscillation": 8.4,
    "runningGroundContactTime": 236.0,
    "walkingStepLength": 1.12,
    "restingHeartRate": 58.0,
    "runningPower": 310.0,
    "runningStrideLength": 1.35,
    "heartRateRecoveryOneMinute": 32.0,
    "route": [
      { "lat": 37.5665, "lng": 126.9780 },
      { "lat": 37.5668, "lng": 126.9783 }
    ],
    "routeOriginalPointCount": 4520,
    "routeSamplingMethod": "none",
    "splits": [
      {
        "index": 1,
        "distanceKm": 1.0,
        "durationSec": 330,
        "paceSecondsPerKm": 330,
        "avgHeartRate": 148,
        "avgCadence": 172,
        "elevationGainM": 4.2
      }
    ],
    "series": {
      "sampleIntervalSec": 5,
      "originalSampleCount": {
        "heartRate": 1800,
        "paceSecondsPerKm": 1720,
        "cadence": 1760,
        "elevation": 4520
      },
      "samplingMethod": {
        "heartRate": "fixedIntervalAverage",
        "paceSecondsPerKm": "fixedIntervalAverage",
        "cadence": "fixedIntervalAverage",
        "elevation": "uniform"
      },
      "heartRate": [
        { "t": 0, "v": 132 },
        { "t": 5, "v": 138 }
      ],
      "paceSecondsPerKm": [
        { "t": 0, "v": 360 },
        { "t": 5, "v": 352 }
      ],
      "cadence": [
        { "t": 0, "v": 168 },
        { "t": 5, "v": 170 }
      ],
      "elevation": [
        { "distanceM": 0, "altitude": 12.4 },
        { "distanceM": 50, "altitude": 13.1 }
      ]
    }
  },
  "weather": {
    "temperature": 24.6,
    "humidity": 68,
    "windSpeed": 2.3,
    "skyCondition": "sunny",
    "windLevel": "moderate",
    "feelsLike": "hot",
    "humidityLevel": "dry",
    "categoryAdjusted": false
  },
  "diary": {
    "painAreas": ["knee", "achilles"],
    "runningStyle": "midfoot",
    "difficultyLevel": 3,
    "memo": "컨디션 좋았음",
    "shoeId": "66a1b2c3d4e5f67890123456"
  }
}
```

## `workout` 필드

| 필드 | 타입 | 단위/형식 | 규칙 |
|---|---|---|---|
| `workoutId` | String | UUID | `HKWorkout.uuid`. 동일 운동에서 불변 |
| `startTime` | String | ISO 8601 UTC | timezone을 포함한 `Z` 형식 |
| `endTime` | String | ISO 8601 UTC | timezone을 포함한 `Z` 형식 |
| `timeZone` | String | IANA identifier | 요청 생성 당시 기기 timezone. 예: `Asia/Seoul` |
| `distance` | Number | km | HealthKit `totalDistance`를 km로 변환 |
| `duration` | Integer | sec | `HKWorkout.duration`을 반올림 |
| `paceSecondsPerKm` | Integer | sec/km | 거리와 운동시간으로 계산. 계산 불가 시 서버 계산 정책 확인 필요 |
| `averageHeartRate` | Integer | bpm | 미측정 시 `0` |
| `averageCadence` | Integer | spm | 미측정 시 `0` |
| `activeEnergyBurned` | Number | kcal | 미측정 시 `0` |
| `runningVerticalOscillation` | Number | cm | 미측정 시 `0` |
| `runningGroundContactTime` | Number | ms | 미측정 시 `0` |
| `walkingStepLength` | Number | m | 미측정 시 `0` |
| `restingHeartRate` | Number | bpm | 미측정 시 `0` |
| `runningPower` | Number | watts | 미측정 시 `0` |
| `runningStrideLength` | Number | m | 미측정 시 `0` |
| `heartRateRecoveryOneMinute` | Number | bpm | 미측정 시 `0` |
| `route` | Array\<{lat, lng}\> \| null | 위경도 | 경로가 없으면 명시적 `null` |
| `routeOriginalPointCount` | Integer \| null | count | 경로 조회 전 원본 좌표 개수. 경로가 없으면 `null` |
| `routeSamplingMethod` | String \| null | enum | `none` 또는 합의된 다운샘플링 알고리즘명 |
| `splits` | Array | - | 데이터가 없으면 `[]` |
| `series` | Object \| null | - | 지원하지 않거나 데이터가 없으면 명시적 `null` |

HealthKit 객체 자체는 JSON으로 직렬화하지 않는다. 위 필드는 HealthKit 값의 의미를 유지하면서 네트워크 전송이 가능한 기본 타입으로 변환한 결과다. 화면 표시용 문자열인 `averagePace`는 요청 계약에 포함하지 않는다.

## `workout.route`

`route` 원소는 위도와 경도만 포함한다.

```json
{ "lat": 37.5665, "lng": 126.9780 }
```

- 경로가 없으면 `route: null`이다.
- 경로가 있으면 빈 배열이 아닌 좌표 배열이다.
- 원본 좌표가 50,000개 이하이면 `routeSamplingMethod: "none"`이다.
- 50,000개를 초과하면 첫 지점과 마지막 지점을 보존하는 다운샘플링을 적용한다.
- `routeOriginalPointCount`는 HealthKit route count 또는 실제 조회한 원본 좌표 배열의 개수로 계산한다.
- 다운샘플링 알고리즘명은 HealthKit이 제공하는 메타데이터가 아니라 클라이언트가 적용한 방식을 기록한다.

## `workout.splits`

| 필드 | 타입 | 단위 | 규칙 |
|---|---|---|---|
| `index` | Integer | - | 1부터 순차 증가 |
| `distanceKm` | Number | km | 마지막 구간은 1km 미만 가능 |
| `durationSec` | Number | sec | 구간 운동시간 |
| `paceSecondsPerKm` | Integer | sec/km | 구간 페이스 |
| `avgHeartRate` | Integer \| null | bpm | 구간 샘플이 없으면 `null` |
| `avgCadence` | Integer \| null | spm | 구간 샘플이 없으면 `null` |
| `elevationGainM` | Number \| null | m | 고도 샘플이 없으면 `null` |

구간 데이터가 없으면 `splits: []`로 보낸다.

## `workout.series`

| 필드 | 타입 | 설명 |
|---|---|---|
| `sampleIntervalSec` | Integer \| null | 고정 간격 리샘플링의 기준 간격 |
| `originalSampleCount` | Object | 지표별 다운샘플링 전 개수 |
| `samplingMethod` | Object | 지표별 샘플링 방식 |
| `heartRate` | Array\<{t, v}\> | `t`: 시작 후 초, `v`: bpm |
| `paceSecondsPerKm` | Array\<{t, v}\> | `t`: 시작 후 초, `v`: sec/km |
| `cadence` | Array\<{t, v}\> | `t`: 시작 후 초, `v`: spm |
| `elevation` | Array\<{distanceM, altitude}\> | 거리축 고도 프로파일 |

- 수집할 수 있는 시계열이 하나도 없으면 `series: null`이다.
- 개별 지표를 수집하지 못하면 해당 배열은 `[]`로 보낸다.
- 각 지표는 최대 2,000점을 넘지 않는다.
- `originalSampleCount`와 `samplingMethod`는 지표별 원본 개수와 처리 방식이 다르므로 객체 형태를 제안한다.

## `weather` 필드

| 필드 | 타입 | 단위/값 | 규칙 |
|---|---|---|---|
| `temperature` | Number | °C | WeatherKit 원시 수치 |
| `humidity` | Integer | % | 0~100 |
| `windSpeed` | Number | m/s | WeatherKit 원시 수치 |
| `skyCondition` | String | `sunny`, `cloudy` | 사용자 최종 확정값 |
| `windLevel` | String | `weak`, `moderate`, `strong` | 사용자 최종 확정값 |
| `feelsLike` | String | `cold`, `neutral`, `hot` | 사용자 최종 확정값 |
| `humidityLevel` | String | `dry`, `humid` | 사용자 최종 확정값 |
| `categoryAdjusted` | Boolean | - | 자동 분류값과 최종값 중 하나라도 다르면 `true` |

- 날씨 조회에 실패하면 `weather: null`이다.
- 사용자가 값을 변경한 뒤 자동 분류값으로 되돌렸다면 `categoryAdjusted: false`다.

## `diary` 필드

| 필드 | 타입 | 필수 | 규칙 |
|---|---|---|---|
| `painAreas` | Array\<String\> | ✅ | 통증이 없으면 `[]` |
| `runningStyle` | String \| null | ❌ | `forefoot`, `midfoot`, `heelfoot` |
| `difficultyLevel` | Integer \| null | ❌ | 1~5 |
| `memo` | String \| null | ❌ | 비어 있으면 `null`, 최대 2,000자 |
| `shoeId` | String | ✅ | 신발 API의 Mongo ObjectId |

`painAreas` enum은 다음 값을 사용한다.

```text
knee, sole, shin, achilles, hip, shoulder, neck, waist, chest, calf, ankle, side
```

`shoeName`은 보내지 않는다. 서버 DB의 이름을 기준으로 저장한다.

## null 및 빈 컬렉션 규칙

| 상황 | 전송값 |
|---|---|
| 미측정 HealthKit 스칼라 지표 | `0` |
| 경로 없음 | `route: null` |
| splits 없음 | `splits: []` |
| series 전체 없음 | `series: null` |
| series의 개별 지표 없음 | 해당 배열 `[]` |
| 통증 없음 | `painAreas: []` |
| 메모 없음 | `memo: null` |
| 날씨 없음 | `weather: null` |
| 신발 없음 | 현재 UX에서는 발생하지 않음 |

## 서버 확인 요청사항

다음 항목은 최종 API 계약 전에 확인이 필요하다.

1. 미측정 스칼라 값을 `null` 대신 `0`으로 보내고 서버가 `0 = 미측정`으로 해석하는 정책을 수용할 수 있는가?
2. `paceSecondsPerKm`을 클라이언트가 계산하지 못한 경우 필드 생략 또는 `null`을 허용하고 서버가 `duration / distance`로 계산하는가?
3. `series.originalSampleCount`와 `series.samplingMethod`를 지표별 객체 형태로 받을 수 있는가?
4. 같은 `Idempotency-Key`와 같은 body의 재시도는 기존 성공 응답을 반환하고, 새로운 키로 기존 `workoutId`를 전송한 경우에만 409를 반환하는가?
5. 같은 `Idempotency-Key`에 다른 body가 전달되면 어떤 상태 코드와 오류 코드를 반환하는가?
6. 현재 클라이언트 정책상 `shoeId`가 항상 존재하는 것을 전제로 필수 필드로 확정해도 되는가?

## 예상 오류 처리

| 상태 코드 | 클라이언트 해석 |
|---|---|
| `2xx` | 생성 성공 |
| `400` | 요청 스키마 또는 값 검증 실패 |
| `401` | access token 갱신 후 동일한 `Idempotency-Key`로 1회 재시도 |
| `409` | 이미 저장된 `workoutId` 또는 멱등성 충돌. 서버 오류 코드로 세부 원인 구분 필요 |
| `5xx` | 동일한 body와 `Idempotency-Key`를 유지하여 재시도 가능 |
