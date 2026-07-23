# RunDiary 화면·기능 명세

> 이 문서 세트는 RunDiary의 화면 구성과 기능을 명세한다.
> 목적 ① AI 협업(바이브코딩) 시 화면 단위로 명확히 지시하고 구현/미구현을 대조해 백로그를 남기기 위함.
> 목적 ② Claude Design에 디자인 시스템·UIUX 제작을 요청할 때의 근거 자료.
>
> RunDiary는 1인 기획·개발 프로젝트로 별도 기획서가 없으므로, 이 문서가 사실상의 기능명세서 역할을 한다.

## 앱 개요
- **한 줄 정의**: 러닝 일지와 컨디션을 기록·회고하는 iOS 앱. 정량 데이터(HealthKit)와 감성 회고(통증/주법/난이도/메모/날씨)를 결합한다.
- **아키텍처**: TCA(The Composable Architecture). 각 Feature = `Core/`(Reducer: State·Action·Dependency) + `Views/`(SwiftUI).
- **저장**: 현재 로컬 SwiftData 단일 테이블(`RunningRecordPersistenceModel`). 향후 서버 원격 DB로 이전 예정(→ [07-migration-loading](./07-migration-loading.md)).
- **통합**: HealthKit(거리/심박/케이던스/파워/경로/시계열), WeatherKit(날씨 자동 조회).
- **테마**: 라이트 모드 고정(`Info.plist` `UIUserInterfaceStyle = Light`).
- **최소 타깃**: iOS 18.0.

## 네비게이션 흐름

앱은 `@Reducer enum Destination` / `StackState` 기반 스택 네비게이션을 쓰지 않는다. 루트는 `Route` enum 스위칭, 메인 화면은 개별 `@Presents`(sheet/push) 방식이다.

```
RunDiaryApp (@main)
└─ RootView / AppFeature.Route          ← 루트 라우팅(독립 UI 없음)
   ├─ .loading  → ProgressView          ← 세션 판정 중 임시 스피너(전용 스플래시 아님)
   ├─ .login    → LoginView             ── delegate(.signedIn) ──▶ .main
   └─ .main     → DailyDetailView        ← 메인 허브(주간 러닝 기록)
        ├─ @Presents createDiary → CreateDiaryView   (navigationDestination push, 7단계 위저드)
        ├─ @Presents calendar    → CalendarView      (sheet, 날짜 선택 → navigateToDiary)
        └─ @Presents settings    → SettingsView      (navigationDestination push)
```

- **앱 시작**: `AppFeature.onAppear`에서 `tokenClient.hasValidSession()`으로 분기 → 세션 있으면 `.main`, 없으면 `.login`. (`AppFeature.swift:56-58`)
- **로그인 성공**: `LoginFeature`가 `delegate(.signedIn)` 전송 → `AppFeature`가 `.main`으로 전환. (`AppFeature.swift:60-62`)
- **메인 허브**: `DailyDetailFeature`가 3개 자식 화면을 `@Presents`로 보유하고 오케스트레이션. (`DailyDetailFeature.swift:26-28`, `.ifLet` `:266-274`)
- **로그아웃/토큰 만료**: 🚧 미구현. `.signedOut` delegate 수신 → 토큰 clear → `.login` 전환 경로가 TODO 상태. (`AppFeature.swift:64-65`)

> 루트 라우팅(`AppFeature`)은 독립 화면 UI가 없어 별도 문서를 두지 않고 이 흐름 섹션에 포함한다.

## 화면 인덱스

| # | 화면 | 상태 | 문서 |
|---|------|------|------|
| 01 | 로그인 (Apple Sign In) | ✅ 구현 | [01-login.md](./01-login.md) |
| 02 | 주간 기록 허브 (Daily Detail) | ✅ 구현 | [02-daily-detail.md](./02-daily-detail.md) |
| 03 | 월간 캘린더 시트 | ✅ 구현 | [03-calendar.md](./03-calendar.md) |
| 04 | 일기 작성 위저드 (7단계) | ✅ 구현 | [04-create-diary.md](./04-create-diary.md) |
| 05 | 설정 | ✅ 구현 | [05-settings.md](./05-settings.md) |
| 06 | 일기 상세 화면 (확장 HealthKit) | ❌ 신규/미래 | [06-record-detail.md](./06-record-detail.md) |
| 07 | 마이그레이션 로딩 (로컬→원격) | ❌ 신규/미래 | [07-migration-loading.md](./07-migration-loading.md) |

- 미구현·TODO 전체 집계: [backlog.md](./backlog.md)
- Claude Design 전달용 디자인 브리프·프롬프트: [design-brief.md](./design-brief.md)

## 디자인 토큰 현황

디자인 시스템은 아직 정립 전이다. 현재 코드베이스가 보유한 자산은 다음과 같다.

### 색상 (에셋 카탈로그 `RunDiary/Resources/Colors.xcassets/`)
9개 colorset만 정의돼 있다. Swift 헬퍼(Asset enum 등) codegen은 없다.

| 토큰 | 용도(관찰된 사용처) |
|------|---------------------|
| `gray_50` / `gray_100` / `gray_300` / `gray_500` / `gray_700` | 배경·구분선·보조 텍스트·본문 텍스트 등 그레이 스케일 |
| `blue_300` / `blue_700` | 강조/링크 계열 |
| `yellow_100` | 캘린더 "일기 보기" 버튼 등 포인트 |
| `coral` | 통증/미저장 워크아웃 표식 등 주의·강조 |

### 타이포그래피
- **토큰 체계 없음.** 각 화면에서 SwiftUI 기본 `.font()`를 직접 사용한다.
- 예외적으로 메모는 세리프체(Georgia)를 직접 지정(감성 강조).

### 컴포넌트/모디파이어 (`RunDiary/Sources/Core/DesignSystem/`)
토큰이 아니라 재사용 뷰·모디파이어 3종만 존재한다.
- `LiquidGlassModifier` — 글래스 효과
- `DynamicGridLayout` — 동적 그리드
- `RouteMapView` — 러닝 경로 지도

> Claude Design에 요청할 것: 위 9색을 기반으로 한 **컬러 시스템(라이트 전용)**, **타이포그래피 스케일**, 핵심 컴포넌트(카드/칩/버튼/그래프) 토큰화. 상세는 [design-brief.md](./design-brief.md) 참고.

## 문서 규칙
- 각 화면 문서는 공통 템플릿(목적 / 진입·이탈 / 화면 구성(UI) / 기능·인터랙션 / 데이터 / 구현 상태)을 따른다.
- 구현 상태 표기: ✅ 구현됨 · 🚧 부분/버그 · ❌ 미구현.
- 신규(06/07) 문서는 구현이 없는 **설계안**이며 문서 상단에 이를 명시한다.
- 이 문서 세트는 테스트 명세(`docs/specs/`)와 목적이 다르다. 여기는 제품/화면 명세, 저기는 명세-우선 테스트 재작성 산출물이다.
