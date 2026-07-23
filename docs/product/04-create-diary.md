# 04. 일기 작성 위저드 (7단계)

> 대상: `RunDiary/Sources/Features/CreateDiary/Core/CreateDiaryFeature.swift`, `Views/CreateDiaryView.swift`, `Views/Steps/Step1~7`, `Components/*`(`SelectableChip`, `PainPointButton`, `StepNavigationBar` 등)

## 목적
HealthKit 워크아웃을 바탕으로 러닝 일기를 작성/수정하는 7단계 스텝 위저드. 정량 데이터(피트니스)에 사용자의 감성·컨디션(날씨 체감·신발·주법·통증·난이도·메모)을 덧입혀 하나의 `Diary`로 저장한다.

## 진입 / 이탈
- **진입**:
  - 신규: `DailyDetailFeature.createRecord(workout)` → `existingRecord: nil`로 present. (`DailyDetailFeature.swift:177-185`)
  - 수정: `DailyDetailFeature.editRecord(diary)` → `existingRecord: diary`로 present. (`:187-193`)
- **이탈**:
  - 저장 완료 → `recordSaved` → `dismiss()` → 상위가 주간 새로고침. (`CreateDiaryFeature.swift:292-296`, `DailyDetailFeature.swift:195-198`)
  - 취소 → `dismiss`.

## 스텝 구성
`Step` enum 순서(`:16-39`): `fitness → weather → shoes → runningStyle → painAreas → difficulty → memo`. `next`/`previous`/`isFirst`/`isLast`로 이동.

## 화면 구성 (UI)
`CreateDiaryView`는 VStack. 상단 스텝 콘텐츠 + 하단 네비게이션 바.

### 공통 프레임
- **`StepContent`**: `currentStep`에 따라 Step1~7 뷰를 opacity transition으로 전환.
- **`StepNavigationBar`**: 이전/다음/저장 버튼. `canGoNext`로 스텝별 진행 조건 검증(날씨 4개 모두 선택, 신발 선택, 주법 선택, 난이도 선택). 마지막 스텝은 `isFormValid`로 저장 버튼 활성.
- **네비게이션**: 타이틀(작성/수정 분기), 취소 버튼(dismiss), 키보드 완료 툴바.

### 스텝별
| 스텝 | 뷰 | 구성 · UX 의도 |
|------|----|----------------|
| 1 Fitness | `Step1FitnessView` | `HealthKitSectionView`로 운동 데이터 표시(읽기 전용). 작성의 출발점 = 정량 사실 확인 |
| 2 Weather | `Step2WeatherView` | 원시 날씨 요약(기온/습도/풍속) + 4개 칩 그룹(하늘☁️/바람💨/체감🌡️/습도💧, `SelectableChip`). 자동 수치를 사용자가 체감으로 보정 |
| 3 Shoes | `Step3ShoesView` | 좌 브랜드 목록 + 우 신발 목록 2단, 체크마크 선택, 로딩 시 ProgressView. 장비 기록 |
| 4 RunningStyle | `Step4RunningStyleView` | 주법 카드 3종(forefoot/midfoot/heelfoot) + 발 아이콘·설명. 러닝 폼 자기 인식 |
| 5 PainAreas | `Step5PainAreasView` | 상단 신체 이미지 + 통증 리플 효과(`PainRippleEffect`, 2초 후 소멸), 하단 통증 부위 버튼 그리드(`PainPointButton`, 다중 선택). 부상 관리 |
| 6 Difficulty | `Step6DifficultyView` | 5단계 막대 바(높이 상승), `DragGesture`로 난이도 선택. 체감 강도 기록 |
| 7 Memo | `Step7MemoView` | `TextEditor` + placeholder. 자유 회고 |

- [UX 의도 총평] 스텝을 나눠 한 화면당 한 결정만 요구 → 기록 부담 완화. 필수(신발·주법·난이도)와 선택(통증·메모·날씨 보정) 구분.

## 기능 / 인터랙션

| 동작 | Action | 결과 |
|------|--------|------|
| 화면 표시 | `onAppear` | 신발 로드 + (신규 시) 상세 운동 데이터 조회 (`:127-150`) |
| 상세 조회 완료 | `workoutDetailFetched` | 경로에서 위치 추출 → 날씨 조회 (`:152-171`) |
| 다음/이전 | `nextStepTapped` / `previousStepTapped` | 스텝 이동 (`:173-183`) |
| 통증 선택 | `updateSelectedPainAreas` | 다중 선택 갱신 (`:185-187`) |
| 주법/신발/난이도/메모 | `updateSelected*` / `updateMemo` | 각 선택 갱신 (`:189-215`) |
| 날씨 태그 | `updateSkyCondition`/`WindLevel`/`FeelsLike`/`HumidityLevel` | 체감 보정값 갱신 (`:217-231`) |
| 신발 로드 | `shoesLoaded` / `shoesLoadFailed` | 목록 반영, 기존 신발 id 매칭 선택 (`:197-207`) |
| 저장 | `saveRecord` | `Diary` 생성 → 신규 `saveRecord` / 수정 `updateRecord` (`:243-290`) |
| 저장 완료/실패 | `recordSaved` / `recordSaveFailed` | dismiss / 에러 메시지 (`:292-301`) |

- **저장 검증**: `isFormValid` = 신발·주법·난이도 필수. (`:67-72`)

## 데이터
- **모델**: `Diary`, `HealthKitWorkout`(상세 지표는 저장 시점에 `fetchDetailedRunningData`로 추출), `WeatherData`(+체감 4분류: `SkyCondition`/`WindLevel`/`FeelsLikeLevel`/`HumidityLevel`), `Shoe`, `PainArea`, `RunninStyle`, `DifficultyLevel`.
- **조회/저장**: `healthKitClient.fetchDetailedRunningData`, `weatherClient.fetchWeather`, `shoeClient.fetchAllShoes`(캐시 `ShoeCache`), `runningRecordClient.saveRecord`/`updateRecord`(→ SwiftData).
- **위치·시간 추출**: 경로 데이터에서 시작·끝 좌표 중점, 시작·끝 시간 중점으로 날씨 조회. (`:306-326`)

## 구현 상태
- ✅ 7단계 위저드 흐름, 스텝별 진행 검증, 신규/수정 분기
- ✅ 신규 시 상세 운동 데이터 + 날씨 자동 조회, 체감 보정
- ✅ 통증 리플·난이도 드래그 등 인터랙션
- 🐛 `errorMassage` 오타 프로퍼티명(기능 영향 없음, [backlog](./backlog.md))
- 🌐 Step4 주법 설명 문구 L10n 미적용 하드코딩([backlog](./backlog.md))
