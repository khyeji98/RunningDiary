# 다이어리 생성 서버 저장 API — 요청 데이터 명세

> 백엔드 API 명세 작성을 위한 **클라이언트 요청 바디 명세서**. RunDiary 앱의 실제 도메인 모델
> (`Diary` / `HealthKitWorkout` / `WeatherData` + 유저 입력)을 근거로 작성됨.

## 개요

다이어리(러닝 일지) 생성 시 서버 저장 API로 전송하는 데이터는 3개 출처로 구성된다.

- **HealthKit**: 러닝 상세 측정 지표 (거리/시간/심박/케이던스/러닝 다이나믹스/경로)
- **WeatherKit**: 날씨 원시 수치 + 자동 분류 카테고리(유저 재조정 가능)
- **User 입력**: 통증 부위, 주법, 난이도, 메모, 신발

### 설계 결정
1. **route** → `[{lat, lng}]` 좌표 배열(JSON)로 전송 (base64 blob 아님).
2. **shoe** → `shoeId`(String) 기본 전송, `shoeName`은 optional로 함께 전송.
3. **weather** → 원시 수치(temperature/humidity/windSpeed) + 최종 카테고리 4종(유저 재조정 반영) 모두 전송.

---

## 요청 바디 JSON (예시)

```json
{
  "workout": {
    "startTime": "2026-07-12T06:30:00Z",
    "endTime": "2026-07-12T07:12:30Z",
    "distance": 7.42,
    "duration": 2550,
    "averagePace": "5'44\"",
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
    "splits": [
      {
        "index": 1,
        "distanceKm": 1.0,
        "durationSec": 330,
        "paceSecondsPerKm": 330,
        "avgHeartRate": 148,
        "avgCadence": 172,
        "elevationGainM": 4.2
      },
      {
        "index": 2,
        "distanceKm": 1.0,
        "durationSec": 342,
        "paceSecondsPerKm": 342,
        "avgHeartRate": 152,
        "avgCadence": 170,
        "elevationGainM": 1.8
      }
    ],
    "series": {
      "sampleIntervalSec": 5,
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
    "humidityLevel": "dry"
  },

  "diary": {
    "painAreas": ["knee", "achilles"],
    "runningStyle": "midfoot",
    "difficultyLevel": 3,
    "memo": "컨디션 좋았음",
    "shoeId": "nike-pegasus-41",
    "shoeName": "Nike Pegasus 41"
  }
}
```

---

## 필드 명세

### 최상위
| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `workout` | Object | ✅ | HealthKit 측정 데이터 |
| `weather` | Object \| null | ❌ | 날씨 데이터. 위치/조회 실패 시 `null` |
| `diary` | Object | ✅ | 유저 입력 데이터 |

### `workout` (출처: HealthKit) — 모두 평균/스칼라 값
| 필드 | 타입 | 단위 | 비고 |
|---|---|---|---|
| `startTime` | String (ISO 8601) | — | 러닝 시작 시각. 다이어리 날짜는 이 값에서 파생 |
| `endTime` | String (ISO 8601) | — | 러닝 종료 시각 |
| `distance` | Number | **km** | 미터 아님 |
| `duration` | Number | **초(sec)** | |
| `averagePace` | String | min/km | `"5'44\""` (분'초") 포맷 문자열. ※ 아래 주의 참고 |
| `averageHeartRate` | Integer | bpm | 평균만 (최대/시계열 없음) |
| `averageCadence` | Integer | spm (steps/min) | |
| `activeEnergyBurned` | Number | **kcal** | |
| `runningVerticalOscillation` | Number | cm | 수직 진폭 |
| `runningGroundContactTime` | Number | ms | 지면 접촉 시간 |
| `walkingStepLength` | Number | m | 보폭 |
| `restingHeartRate` | Number | bpm | 휴식 심박수 |
| `runningPower` | Number | watts | 러닝 파워 |
| `runningStrideLength` | Number | m | 러닝 보폭 |
| `heartRateRecoveryOneMinute` | Number | bpm | 1분 심박 회복 |
| `route` | Array\<{lat, lng}\> \| null | 위경도(도) | GPS 경로 폴리라인. 없으면 `null` 또는 `[]` |

`route[]` 원소: `{ "lat": Number, "lng": Number }` — **altitude/timestamp/speed 없음** (앱이 위경도만 저장).

> **주의 — 값이 없는 지표**: 상세(detailed) 데이터에서도 HealthKit 권한/기기(예: Apple Watch 미착용)에 따라 러닝 다이나믹스 필드(`runningVerticalOscillation`, `runningGroundContactTime`, `runningPower`, `runningStrideLength`, `heartRateRecoveryOneMinute`, `restingHeartRate` 등)가 **0.0**으로 들어올 수 있다. 서버는 "0 = 측정 없음"으로 해석하거나, 클라이언트에서 0을 null로 치환할지 백엔드와 합의 필요.

> **주의 — pace 포맷**: `averagePace`는 앱이 `"5'44\""` 형태의 **표시용 문자열**로 보관한다. 서버에서 정렬·집계가 필요하면 `paceSecondsPerKm`(Integer, 초/km) 같은 수치 필드 추가를 백엔드와 협의 권장(현재 앱은 문자열만 보유). ※ 아래 `splits`/`series`는 수치 페이스(`paceSecondsPerKm`)를 사용한다.

### `workout.splits` (구간 요약 테이블) — 러닝 앱 랩 기록
거리를 1km(마지막 구간은 1.0 미만 가능)씩 잘라 구간별 대표값 한 줄. 러닝당 수~수십 행. 데이터 없으면 생략 또는 `[]`.

| 필드 | 타입 | 단위 | 설명 |
|---|---|---|---|
| `index` | Integer | — | 구간 순번(1부터) |
| `distanceKm` | Number | km | 구간 거리. 마지막 구간은 1.0 미만 가능 |
| `durationSec` | Number | 초 | 구간 소요 시간 |
| `paceSecondsPerKm` | Integer | 초/km | 구간 페이스(수치) |
| `avgHeartRate` | Integer \| null | bpm | 구간 평균 심박 |
| `avgCadence` | Integer \| null | spm | 구간 평균 케이던스 |
| `elevationGainM` | Number \| null | m | 구간 누적 상승(선택) |

### `workout.series` (시계열 곡선) — 그래프용
지표별 `{t, v}` 포인트 배열. `t` = 워크아웃 시작 후 경과 **초**(Integer). `elevation`만 거리축(`distanceM`). 원본 샘플이 수백~수천 개일 수 있어 **다운샘플링**(고정 간격 리샘플 또는 지표당 상한)된 값을 보낸다. `series` 자체가 없으면 `null`, 개별 지표 배열이 없으면 생략 또는 `[]`.

| 필드 | 타입 | 설명 |
|---|---|---|
| `sampleIntervalSec` | Integer | 리샘플 간격(초). 불규칙 간격이면 생략 |
| `heartRate[]` | `{ "t": Int(초), "v": Int(bpm) }` | 심박 곡선 |
| `paceSecondsPerKm[]` | `{ "t": Int(초), "v": Int(초/km) }` | 페이스 곡선 |
| `cadence[]` | `{ "t": Int(초), "v": Int(spm) }` | 케이던스 곡선 |
| `elevation[]` | `{ "distanceM": Number, "altitude": Number(m) }` | 고도 프로파일(거리축) |

> **⚠ 구현 상태**: `splits`/`series`는 **현재 앱이 아직 추출하지 않는다.** 앱은 HealthKit 지표를 평균값으로만 뽑고, 경로의 timestamp·고도도 버린다. 이 두 필드를 실제로 채워 보내려면 `HealthKitManager`에 시계열 샘플 쿼리·구간 버킷팅·경로 고도 보존 추출을 추가하는 작업(별도 진행)이 필요하다. 이 명세는 그 **목표 스키마**다.

### `weather` (출처: WeatherKit 수치 + 유저 재조정 카테고리)
| 필드 | 타입 | 단위 | 값/설명 |
|---|---|---|---|
| `temperature` | Number | **°C** | WeatherKit 원시 |
| `humidity` | Integer | **%** | 0~100 (WeatherKit 0~1 → %) |
| `windSpeed` | Number | **m/s** | WeatherKit 원시 |
| `skyCondition` | String enum | — | `sunny` \| `cloudy` |
| `windLevel` | String enum | — | `weak` \| `moderate` \| `strong` |
| `feelsLike` | String enum | — | `cold` \| `neutral` \| `hot` |
| `humidityLevel` | String enum | — | `dry` \| `humid` |

카테고리 4종은 WeatherKit 수치로 자동 분류된 뒤 유저가 재조정할 수 있으므로, 전송 값은 **유저 최종 확정값**이다(수치와 불일치할 수 있음 — 정상).

### `diary` (출처: User 입력)
| 필드 | 타입 | 필수 | 값/설명 |
|---|---|---|---|
| `painAreas` | Array\<String enum\> | ✅ (빈 배열 허용) | 다중 선택. `knee, sole, shin, achilles, hip, shoulder, neck, waist, chest, calf, ankle, side` |
| `runningStyle` | String enum \| null | ❌ | `forefoot` \| `midfoot` \| `heelfoot` |
| `difficultyLevel` | Integer \| null | ❌ | 난이도 1~5 (`1=veryEasy, 2=easy, 3=medium, 4=hard, 5=veryHard`) |
| `memo` | String \| null | ❌ | 빈 문자열이면 `null`로 전송 |
| `shoeId` | String \| null | ❌ | `Shoe.id` |
| `shoeName` | String \| null | ❌ (optional) | 표시용 신발 이름 (서버 신발 DB 없거나 스냅샷 용도) |

---

## 백엔드와 사전 합의가 필요한 열린 항목
- 측정 없음 지표의 표현: `0.0` vs `null`
- `averagePace` 문자열 외 수치 pace 필드 추가 여부
- `route`가 비었을 때 `null` vs `[]`
- 날짜/시각 타임존: ISO 8601 UTC(`Z`) 고정 vs 로컬 오프셋 포함
- `series` 다운샘플 간격/상한 (예: 5초 / 지표당 500점) — 저장·전송 비용
- `splits` 구간 단위: km 고정 vs 유저 설정(마일 등)
- `splits`/`series` 서버 저장 방식: 별도 테이블 vs blob(JSON)
