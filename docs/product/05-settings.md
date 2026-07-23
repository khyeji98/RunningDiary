# 05. 설정

> 대상: `RunDiary/Sources/Features/Settings/Core/SettingsFeature.swift`, `Views/SettingsView.swift`

## 목적
앱의 법적 고지(개인정보처리방침·이용약관) 웹 페이지로 이동하기 위한 최소 설정 화면. 현재는 계정·알림·테마 등 다른 설정 항목이 없다.

## 진입 / 이탈
- **진입**: `DailyDetailFeature.settingsButtonTapped` → `settings` push present(연월 헤더 우측 톱니). (`DailyDetailFeature.swift:238-241`)
- **이탈**: 뒤로 가기 → `settings(.dismiss)`. (`DailyDetailFeature.swift:243-245`)

## 화면 구성 (UI)
`SettingsView`는 `List`.

### 1) 항목 리스트
- [목적] 법적 문서 링크 제공.
- [정보 위계] 1차(유일 콘텐츠).
- [현재 구현] Section 안에 각 `SettingsItem` Button(표시명 + chevron). 탭 시 로케일별 웹 URL을 외부 브라우저로 오픈. 네비게이션 타이틀 "설정".
- [UX 의도] 표준 iOS 설정 리스트 관습. 향후 항목 확장(계정/로그아웃/데이터 관리) 대비한 그룹 구조.

### SettingsItem
| 항목 | 표시명 | URL |
|------|--------|-----|
| `privacyPolicy` | `L10n.settingsPrivacyPolicy` | `https://apps.kimhyeji.dev/run-diary/privacy-policy/{lang}/` |
| `termsOfService` | `L10n.settingsTermsOfService` | `https://apps.kimhyeji.dev/run-diary/use-of-terms/{lang}/` |

- `{lang}` = 현재 로케일 기준 `ko`/`en`/`ja`(기본 `ko`). (`SettingsFeature.swift:41-58`)

## 기능 / 인터랙션

| 동작 | Action | 결과 |
|------|--------|------|
| 항목 탭 | `settingsItemTapped(item)` | `URLOpener.open(item.url)`로 외부 브라우저 오픈 (`:66-73`) |

- State는 없음(주석: "간단한 화면이므로 별도 상태 불필요"). (`:16-18`)

## 데이터
- 로컬 상수(URL)만 사용. 외부 조회·저장 없음. `URLOpener`, `AppLogger.settings`.

## 구현 상태
- ✅ 개인정보처리방침 / 이용약관 로케일별 링크 오픈
- 🌐 네비게이션 타이틀 "설정"이 L10n 미적용 하드코딩([backlog](./backlog.md))
- ❌ 계정/로그아웃, 데이터 관리(마이그레이션 트리거 등) 항목 미존재 — 향후 확장 후보
