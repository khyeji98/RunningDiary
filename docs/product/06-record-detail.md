# 06. 일기 상세 화면 (확장 HealthKit) — 신규/미래 설계안

> ⚠️ **이 문서는 아직 구현되지 않은 to-be 화면의 설계안이다.** 현재 코드에는 해당 화면이 없다.
> 관련: [02-daily-detail.md](./02-daily-detail.md)(진입 부모), 데이터 근거는 `Dependencies/Models`의 `HealthKitWorkout`/`WorkoutSeries`/`WorkoutSplit`.

## 목적
주간 기록 화면([02](./02-daily-detail.md))의 카드가 요약으로 축소되는 대신, 카드 탭 시 진입하는 **일기 상세 전용 화면**. 확장된 HealthKit 정량 데이터를 **피트니스 앱(예: Apple 피트니스/Strava) 수준으로 상세하게** 시각화하고, 그 위에 감성 회고(통증/주법/난이도/메모/날씨)를 함께 보여준다.

### 왜 만드는가
- 현재 `RunningRecordCard`는 성능 그리드·통증·환경·메모·경로를 한 카드에 담아 정보 밀도가 지나치게 높다.
- HealthKit에는 이미 **시계열(심박/페이스/케이던스/고도)·구간 스플릿** 데이터가 추출·보관되고 있으나(아래 데이터 근거), 현재 화면은 이를 거의 활용하지 못한다.
- 상세를 전용 화면으로 분리하면 주간 목록은 가벼워지고, 상세는 깊이 있는 분석 뷰가 된다.

## 진입 / 이탈 (제안)
- **진입**: 주간 기록 화면의 요약 카드 탭 → 상세 화면 push. (신규 Feature 또는 `DailyDetailFeature`의 `@Presents recordDetail` 추가)
- **이탈**: 뒤로 가기. 상세 화면 내 "수정" → 기존 `CreateDiaryFeature`(수정 모드) 재사용 진입 후 저장 시 상세 갱신.

## 화면 구성 (UI) — 정보 구조 제안
스크롤 단일 화면. 위→아래로 정량에서 감성으로 흐른다.

### 1) 요약 헤더
- [목적] 이 러닝의 정체성(언제·얼마나).
- [정보 위계] 1차.
- [제안] 날짜·시각, 거리(km)·시간·평균 페이스, 난이도/만족도 힌트. 큰 타이포로 핵심 3~4지표.
- [데이터] `HealthKitWorkout.distance`, `.formattedDuration`, `.averagePace`, `Diary.difficultyLevel`.

### 2) 시계열 그래프 (핵심 신규)
- [목적] 러닝 전체 흐름을 곡선으로 회고(초반/후반 페이스 변화, 심박 드리프트 등).
- [정보 위계] 1차. 피트니스 앱 벤치마크의 심장부.
- [제안] 지표 전환 탭(심박 / 페이스 / 케이던스 / 고도). 각 지표를 시간축(경과 초) 라인 차트로. Swift Charts 활용 권장.
- [데이터] `HealthKitWorkout.series: WorkoutSeries?`
  - `heartRate: [SeriesPoint]`, `paceSecondsPerKm: [SeriesPoint]`, `cadence: [SeriesPoint]`, `elevation: [ElevationPoint]`
  - `SeriesPoint = { t: 경과초, v: 값 }`, `sampleIntervalSec`로 샘플 간격 파악.
  - series가 nil이면 그래프 섹션 숨김(구형 기록 호환).

### 3) 구간 스플릿 (핵심 신규)
- [목적] km 구간별 페이스/심박/케이던스 비교(랩 분석).
- [정보 위계] 2차.
- [제안] 구간 리스트/막대. 각 행: 구간 번호, 거리(마지막 <1km 가능), 페이스, 평균 심박/케이던스, 고도 상승. 가장 빠른/느린 구간 강조.
- [데이터] `HealthKitWorkout.splits: [WorkoutSplit]`
  - `index`(1부터), `distanceKm`, `durationSec`, `paceSecondsPerKm`, `averageHeartRate?`, `averageCadence?`, `elevationGainM?`.

### 4) 경로 지도
- [목적] 어디를 달렸는지.
- [제안] 기존 `RouteMapView`(DesignSystem) 재사용. 날씨 라벨 병기.
- [데이터] `HealthKitWorkout.routeData`(→ `decodeRouteData() -> [Location]?`), `Diary.weather`.

### 5) 상세 지표 그리드
- [목적] 평균/단발 정량 지표 모음.
- [제안] 페이스·평균 심박·케이던스·칼로리·러닝 파워·수직 진폭·지면 접촉 시간·보폭·1분 심박 회복 등. 값 0은 숨김(포맷터가 빈 문자열 반환).
- [데이터] `HealthKitWorkout`의 `average*`, `runningPower`, `runningVerticalOscillation`, `runningGroundContactTime`, `walkingStepLength`, `heartRateRecoveryOneMinute` 등. (이미 `formatted*` 계산 프로퍼티 존재)

### 6) 감성 회고 블록
- [목적] 정량 아래에 사람의 기록.
- [제안] 통증 부위(신체 하이라이트)·주법·난이도·날씨 체감·메모(세리프체). 기존 `RunningRecordCard`의 감성 요소 이관.
- [데이터] `Diary.painAreas`, `.runningStyle`, `.difficultyLevel`, `.weather`/`.userWeather`, `.memo`, `.shoes`(신발명은 `Shoe` 매칭).

## UX 의도 / 디자인 방향
- **벤치마크**: Apple 피트니스·Strava의 운동 상세. "그래프 → 스플릿 → 지도 → 지표 → 회고" 순으로 정량 몰입 후 감성 마무리.
- **정량은 시각적으로, 감성은 읽히게**: 상단은 차트 중심의 데이터 밀도, 하단 메모는 여백·세리프체로 톤 전환.
- **점진적 개시**: 접기/펼치기로 초보자에겐 요약, 매니아에겐 전체 지표.
- Claude Design 요청 포인트: 차트 색 시스템(지표별 컬러), 스플릿 표/막대 컴포넌트, 지표 타일 그리드 토큰. → [design-brief.md](./design-brief.md)

## 데이터 요약 (근거)
필요한 데이터는 **이미 도메인 모델에 존재**한다(신규 저장 스키마 불필요, UI만 신규).

| 섹션 | 소스 | 파일 |
|------|------|------|
| 시계열 그래프 | `WorkoutSeries`(heartRate/pace/cadence/elevation) | `Models/Entities/WorkoutSeries.swift`, `SeriesPoint.swift` |
| 구간 스플릿 | `[WorkoutSplit]` | `Models/Entities/WorkoutSplit.swift` |
| 경로 | `routeData` → `[Location]` | `Models/Entities/HealthKitWorkout.swift:117-121` |
| 상세 지표 | `HealthKitWorkout` 필드 다수 | `Models/Entities/HealthKitWorkout.swift:11-72` |
| 감성 회고 | `Diary` | `Models/Entities/Diary.swift` |

> 주의: 상세 지표(series/splits)는 목록 조회가 아니라 **일기 저장 시점**(`CreateDiaryFeature`의 `fetchDetailedRunningData`)에 추출·보관된다. 따라서 저장된 `Diary`에는 상세가 포함되지만, 미저장 워크아웃 카드에는 없을 수 있음을 진입 조건에서 고려.

## 구현 상태
- ❌ 화면 전체 미구현(신규 Feature 필요: State/Action/View + Swift Charts 그래프)
- ❌ 주간 카드 → 상세 진입 배선(부모 `@Presents` 추가)
- ✅ (선행 완료) 데이터 모델(series/splits/route/지표)은 이미 존재 — UI 구현만 남음
