# 02. 주간 기록 허브 (Daily Detail)

> 대상: `RunDiary/Sources/Features/DailyDetail/Core/DailyDetailFeature.swift`, `Views/DailyDetailView.swift` 및 하위 컴포넌트(`DateCarouselView`, `RecordListView`, `RunningRecordCard`, `HealthKitWorkoutCard`, `EmptyRecordView` 등)

## 목적
로그인 후 진입하는 **메인 화면이자 허브**. 주(week) 단위로 러닝 기록을 조회·표시하고, 캘린더·설정·일기 작성 화면으로 가는 진입점을 제공한다. 선택한 날짜의 저장된 일기(`Diary`)와 아직 일기로 작성되지 않은 HealthKit 워크아웃을 함께 보여준다.

## 진입 / 이탈
- **진입**: `AppFeature.Route == .main`일 때 `RootView`가 표시. (`RootView.swift`)
- **이탈(자식 화면 present)**:
  - 일기 작성/수정 → `createRecord`/`editRecord` → `createDiary` push (`:177-193`)
  - 캘린더 → `calendarButtonTapped` → `calendar` sheet (`:208-210`)
  - 설정 → `settingsButtonTapped` → `settings` push (`:238-241`)
- **복귀**:
  - 일기 저장 완료 → `createDiary(.presented(.recordSaved))` → 시트 닫고 주간 새로고침 (`:195-198`)
  - 캘린더에서 날짜 선택 → `calendar(.presented(.navigateToDiary))` → 해당 날짜 주로 전환 후 캘린더 닫기 (`:216-233`)

## 화면 구성 (UI)
`DailyDetailView`는 `NavigationStack` 안 VStack(기본 툴바 숨김). 위→아래로: 연월 헤더 → 날짜 캐러셀 → 구분선 → 기록 콘텐츠. 전체 `.refreshable`(pull-to-refresh).

### 1) 연월 + 설정 헤더 (`YearAndMonthSection`)
- [목적] 현재 보고 있는 월 표시 + 캘린더/설정 진입.
- [정보 위계] 1차(월 이동), 2차(설정).
- [현재 구현] 좌측 "YYYY년 M월" 버튼(chevron 포함, 탭 → 캘린더 sheet), 우측 톱니 아이콘(탭 → 설정).
- [UX 의도] 월 텍스트가 곧 캘린더 진입점임을 chevron으로 암시. 설정은 최소 노출.

### 2) 날짜 캐러셀 (`DateCarouselView`)
- [목적] 주 단위 날짜 탐색 + 기록 유무 미리보기.
- [정보 위계] 1차 네비게이션. 상단 고정.
- [현재 구현] 이전/현재/다음 3주를 가로로 배치, `DragGesture` 스와이프(임계값 화면폭 30%)로 주 전환. 각 날짜는 `DateItemView`(요일/일자 + 기록 있으면 점 표시). 선택된 날짜 강조.
- [UX 의도] 캘린더보다 가벼운 일상 탐색 도구. 오늘·선택·기록유무의 시각 구분이 핵심.

### 3) 기록 콘텐츠 (`RecordContentSection` → ScrollView)
선택 날짜의 기록을 표시. 기록 유무로 분기.

#### 3-a) `RecordListView` (기록 있음)
LazyVStack으로 아래를 순서대로:
- **`RunningRecordCard`** — 저장된 일기 카드(핵심). 아래 별도 설명.
- **`WeatherTrademarkView`** — Apple Weather 법적 고지/출처.
- **`HealthKitWorkoutCard`** — 아직 일기로 작성되지 않은 워크아웃 카드. 거리/시간/페이스/케이던스 + 블러 placeholder(더보기 힌트) + "일기 작성" 버튼.

#### 3-b) `EmptyRecordView` (기록 없음)
- 아이콘 + 안내 메시지. `noHealthKitWorkout` 에러 시 주황(coral) 경고 + 복구 제안.

### 4) `RunningRecordCard` (저장된 일기 카드) — as-is 상세
현재 이 카드 하나에 일기의 거의 모든 정보가 들어간다.
- [목적] 한 번의 러닝을 정량 데이터 + 감성 회고로 회고.
- [정보 위계 · 현재] ① 시간 헤더(시각 + 거리·시간) ② 성능 2열 그리드(페이스·심박·케이던스·칼로리·파워·수직진폭·접지시간) ③ 통증 부위 스티커 ④ 환경 문장(신발·주법·난이도, 언어별 어순 처리) ⑤ 메모(Georgia 세리프체) ⑥ 경로 지도(`RouteMapSection`: 날씨 라벨 + `RouteMapView`).
- [현재 구현] 색상 `gray_100` 계열 배경, `coral` 통증 강조. 정보 밀도 높음.
- [UX 의도] "지표는 훑고 메모는 읽히게." 정량과 감성의 균형.

## as-is → to-be (중요)
현재는 **주간 기록 화면 카드(`RunningRecordCard`)에 일기의 모든 정보가 노출**된다(성능 그리드·통증·환경·메모·경로까지). 앞으로는 다음과 같이 전환한다.

- **to-be 카드**: 요약 수준(예: 시각 + 거리/시간/평균 페이스 + 만족도/난이도 힌트)만 노출해 목록 스캔성을 높인다.
- **상세는 별도 화면으로 이동**: 카드 탭 → **일기 상세 화면**([06-record-detail.md](./06-record-detail.md))에서 확장된 HealthKit 정량 데이터(시계열 그래프·구간 스플릿 등)를 피트니스 앱 수준으로 상세 표현한다.
- 즉 `RunningRecordCard`의 무거운 하위 섹션(성능 그리드·경로·시계열)은 06 상세 화면으로 이전되고, 이 화면은 "빠르게 훑는 주간 목록"에 집중한다.

## 기능 / 인터랙션

| 동작 | Action | 결과 |
|------|--------|------|
| 화면 표시 | `onAppear` | 주 날짜 계산 후 `fetchWeekRecords` (`:96-101`) |
| 프리로드 | `preloadRequested` | 날씨 trademark + 신발 캐시 병렬 프리로드 (`:103-107`) |
| 날짜 탭 | `dateSelected` | `selectedDate` 변경 (`:109-111`) |
| 주 스와이프 | `weekChanged(offset:)` | 주 이동, 같은 요일 유지(없으면 첫날) 후 재조회 (`:113-131`) |
| 기록 조회 | `fetchWeekRecords` | 일기(persistences) + 워크아웃(HealthKit) 병렬 조회 (`:133-151`) |
| 신규 일기 작성 | `createRecord(workout)` | `CreateDiary`(신규) present + 신발 로드 (`:177-185`) |
| 기존 일기 수정 | `editRecord(diary)` | `CreateDiary`(수정) present + 신발 로드 (`:187-193`) |
| 캘린더 열기 | `calendarButtonTapped` | `Calendar` sheet present (`:208-210`) |
| 설정 열기 | `settingsButtonTapped` | `Settings` push present (`:238-241`) |
| 당겨서 새로고침 | `refreshCurrentWeek` | `fetchWeekRecords` 재실행 (`:251-252`) |

- **파생 상태**: `filteredWorkoutsOnSelectedDate`는 이미 일기로 저장된 워크아웃(같은 `startTime`)을 제외한다. (`:37-40`)

## 데이터
- **모델**: `Diary`(저장 일기), `HealthKitWorkout`(운동 측정), `WeatherTrademark`(날씨 출처), `YearMonthDay`.
- **조회**: `persistencesClient.fetchRecords`(SwiftData 로컬) + `healthKitClient.fetchRunningDataBetweenDates`(HealthKit) 병렬. `weatherClient.fetchTrademark`, `shoeClient.fetchAllShoes`(캐시 `ShoeCache`).
- **상태 저장 구조**: `diaries: [YearMonthDay: [Diary]]`, `workouts: [YearMonthDay: [HealthKitWorkout]]`로 날짜별 그룹핑. (`:153-155`)

## 구현 상태
- ✅ 주간 캐러셀·스와이프·날짜 선택
- ✅ 일기/워크아웃 병렬 조회 및 날짜별 그룹핑
- ✅ 저장 일기 카드 / 미작성 워크아웃 카드 / 빈 상태 분기
- ✅ pull-to-refresh, 신발·날씨 프리로드
- 🚧 캘린더 sheet에 `presentationDetents` 지정 시 콘텐츠 전체 축소 버그로 detents 주석 처리됨 (`DailyDetailView.swift:56-57`)
- ❌ (to-be) 카드 요약화 + 일기 상세 화면 분리([06](./06-record-detail.md))
