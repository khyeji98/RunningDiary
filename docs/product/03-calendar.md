# 03. 월간 캘린더 시트

> 대상: `RunDiary/Sources/Features/Calendar/Core/CalendarFeature.swift`, `Views/CalendarView.swift`, `CalendarContentView.swift`, `Components/*`(`TodayButton`, `MonthHeaderView`, `DayView`, `DiarySwitchButton`)

## 목적
월간 달력에서 러닝 기록 분포를 한눈에 보고, 특정 날짜로 점프하기 위한 화면. HorizonCalendar 기반 수직 무한 스크롤로 여러 달을 훑고, 날짜별 총 거리·월별 총 거리를 시각화한다. 날짜를 선택하면 메인(주간 기록)의 해당 날짜로 이동한다.

## 진입 / 이탈
- **진입**: `DailyDetailFeature.calendarButtonTapped` → `calendar` sheet present. 초기 `selectedDate`는 메인의 현재 선택 날짜. (`DailyDetailFeature.swift:208-210`)
- **이탈**:
  - 날짜 선택 후 "일기 보기" → `navigateToDiary` delegate → 상위가 해당 주로 전환하고 시트 닫음. (`CalendarFeature.swift:160-162`, `DailyDetailFeature.swift:216-233`)
  - 시트 드래그 다운/닫기 → `calendar(.dismiss)` (`DailyDetailFeature.swift:212-214`)

## 화면 구성 (UI)
`CalendarView`는 VStack. 위→아래로: 오늘 버튼 → 달력 본문 → 하단 이동 버튼.

### 1) 오늘 버튼 (`TodayButton`)
- [목적] 스크롤로 멀어졌을 때 오늘로 즉시 복귀.
- [정보 위계] 2차. 우상단 캡슐.
- [현재 구현] "오늘" 텍스트 + `arrow.clockwise` 아이콘. `isEnabledTodayButton`이 true일 때만 활성(오늘이 화면 밖이거나 오늘이 미선택일 때). (`CalendarFeature.swift:26-30`)
- [UX 의도] 무한 스크롤에서 길 잃음 방지. 비활성 상태 시각 구분 필요.

### 2) 달력 본문 (`CalendarContentView`)
- [목적] 월별·날짜별 러닝 분포 표시.
- [정보 위계] 1차. 화면 대부분.
- [현재 구현] `CalendarViewRepresentable`(HorizonCalendar) 수직 레이아웃, 요일 헤더 고정.
  - **`MonthHeaderView`**: "YYYY년 M월" + 그 달 총 거리(km).
  - **`DayView`**: 일자 + 그 날 총 거리 + 상태 색상(오늘/일요일/선택) + 미저장 워크아웃이 있으면 `coral` 점.
  - 스크롤 시 과거 데이터 로드 트리거(`checkIfNeedsToLoadOlderData`), 마지막 보인 달 저장(`checkIfNeedsToSaveLastMonth`).
- [UX 의도] 총 거리 = 러닝량의 한눈 파악. 색상·점으로 "기록 있음/미작성" 구분.

### 3) 일기 이동 버튼 (`DiarySwitchButton`)
- [목적] 선택 날짜의 일기로 점프.
- [정보 위계] 1차 액션. 하단.
- [현재 구현] 노란(`yellow_100`) "M월 D일 일기 보기" 버튼 → `navigateToDiary`.
- [UX 의도] 선택 → 이동의 명확한 종결 액션. 선택 날짜를 문구에 반영.

## 기능 / 인터랙션

| 동작 | Action | 결과 |
|------|--------|------|
| 화면 표시 | `onAppear` | 초기 범위(±6개월, 미래는 today 제한) 조회 (`:82-85`) |
| 기록 조회 | `fetchRecords(startDate:endDate:)` | `runningRecordClient.fetchData` 범위 조회. 범위 역전 시 실패 (`:87-107`) |
| 조회 완료 | `recordsFetched` | 병합 + `monthlyTotals`(월별 총 거리) 계산 (`:109-121`) |
| 과거 달 도달 | `oldestMonthBecameVisible` → `fetchOlderRecords` | startDate 6개월 추가 확장 후 재조회 (`:128-149`) |
| 마지막 보인 달 저장 | `saveLastVisibleMonth` | 오늘 버튼 활성 판단용 (`:151-153`) |
| 날짜 선택 | `selectDate` | `selectedDate` 변경 (`:155-158`) |
| 일기 보기 | `navigateToDiary` | 상위(DailyDetail)가 수신해 주 전환 + 시트 닫기 (`:160-162`) |

- **초기 범위 계산**: `selectedDate` 기준 -6개월 ~ +6개월, 단 today까지 6개월 미만이면 endDate=today. (`:36-55`)

## 데이터
- **모델**: `DailyRecord`(날짜별 워크아웃+저장일기 병합 뷰 모델), `YearMonthDay`, `YearMonth`, `monthlyTotals: [YearMonth: Double]`.
- **조회**: `runningRecordClient.fetchData(from:to:)` — 내부에서 HealthKit 원본 + SwiftData 저장분을 `startTime` 기준 병합. `persistencesClient`도 주입돼 있음.

## 구현 상태
- ✅ 수직 무한 스크롤 월간 캘린더, 요일 헤더 고정
- ✅ 날짜별 총 거리 / 월별 총 거리 / 미저장 워크아웃 coral 점
- ✅ 과거 6개월 무한 확장 로드
- ✅ 오늘 버튼(조건부 활성), 날짜 선택 → 일기 이동
- 🚧 시트 detents 미적용(부모 화면 버그로 [02](./02-daily-detail.md) 참조)
