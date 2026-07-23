# 백로그 (미구현 · 버그 · 부채 집계)

> 각 화면 문서의 🚧/❌/🐛 항목을 한곳에 모은 계획용 집계표. 우선순위는 사용자 판단으로 조정.
> 범례: ❌ 미구현 · 🚧 부분/버그 · 🐛 사소 버그 · 🌐 로컬라이제이션 · 🧹 기술 부채

## 우선순위 요약

| 우선 | 항목 | 유형 | 화면/영역 | 근거 |
|------|------|------|-----------|------|
| P1 | 일기 상세 화면(확장 HealthKit) 신규 구현 | ❌ | [06](./06-record-detail.md) | 데이터는 존재, UI만 신규 |
| P1 | 주간 카드 요약화 + 상세 진입 배선 | ❌ | [02](./02-daily-detail.md)→[06](./06-record-detail.md) | to-be 방향 |
| P2 | 로컬→원격 마이그레이션 파이프라인 + 로딩 화면 | ❌ | [07](./07-migration-loading.md) | 업로드 API·오케스트레이션 신규 |
| P2 | 로그아웃/세션 만료 시 `.signedOut` 처리 | ❌ | [01](./01-login.md)/App | `AppFeature.swift:64-65` TODO |
| P3 | 캘린더 sheet `presentationDetents` 버그 | 🚧 | [02](./02-daily-detail.md)/[03](./03-calendar.md) | `DailyDetailView.swift:56-57` |
| P3 | baseURL 키 이원화 정리(`APIBaseURL`/`API_BASE_URL`) | 🧹 | [07](./07-migration-loading.md) | 서버 확장 선행 |
| P4 | `CreateDiaryFeature.errorMassage` 오타 | 🐛 | [04](./04-create-diary.md) | `CreateDiaryFeature.swift:65` 등 |
| P4 | Step4 주법 설명 L10n 미적용 | 🌐 | [04](./04-create-diary.md) | 한글 하드코딩 |
| P4 | 설정 타이틀 "설정" L10n 미적용 | 🌐 | [05](./05-settings.md) | `SettingsView.swift` |
| P5 | 디자인 토큰 체계(타이포/컴포넌트) 정립 | 🧹 | 전역 | [README 토큰 현황](./README.md#디자인-토큰-현황) |

## 상세

### P1 — 일기 상세 화면 (신규)
- 확장된 HealthKit 데이터(시계열 그래프·구간 스플릿·경로·상세 지표)를 피트니스 앱 수준으로 표현하는 전용 화면.
- **선행 완료**: `WorkoutSeries`/`WorkoutSplit`/`routeData`/지표는 이미 `Diary`에 보관됨. Swift Charts 그래프 등 UI만 신규.
- 함께: 주간 화면 `RunningRecordCard`를 요약으로 축소하고 카드 탭 → 상세 push 배선.
- 참조: [06-record-detail.md](./06-record-detail.md)

### P2 — 마이그레이션 파이프라인 + 로딩 화면 (신규)
- 로컬 SwiftData → 서버 원격 DB 최초 업로드 + 진행률/재시도 로딩 화면.
- **신규 필요**: 러닝 기록 업로드 `RequestAPI`(현재 `Endpoint`에 shoes만), 마이그레이션 오케스트레이션 Client/Feature, 완료 플래그, 진입 판정.
- **재사용 가능**: `TokenClient`/`AuthClient`, `CoreNetwork`, 평탄화 로컬 스키마, `Diary.id` upsert 키.
- 참조: [07-migration-loading.md](./07-migration-loading.md)

### P2 — 로그아웃/세션 만료 처리
- `AppFeature`에 `.signedOut` delegate 수신 → `tokenClient.clear()` → `.login` 전환 경로 미구현.
- 현재 코드에 TODO 주석으로 남아 있음. (`AppFeature.swift:64-65`)
- 설정 화면 로그아웃 항목 추가와 연계 가능([05](./05-settings.md)).

### P3 — 캘린더 시트 detents 버그
- 캘린더 sheet에 `presentationDetents` 지정 시 콘텐츠 전체가 축소되는 버그로 detents가 주석 처리됨. 현재 전체 높이 시트로만 표시. (`DailyDetailView.swift:56-57`)

### P3 — baseURL 키 이원화
- `CoreNetwork` → `APIBaseURL`, `AuthService` → `API_BASE_URL`. 서버 통신 확장 전에 통일 권장.

### P4 — 사소 버그 / 로컬라이제이션
- `CreateDiaryFeature.errorMassage` → `errorMessage` 오타(기능 영향 없음).
- Step4 주법 설명 문구 한글 하드코딩(L10n 누락).
- 설정 네비게이션 타이틀 "설정" 하드코딩(다른 화면은 대부분 L10n 사용).

### P5 — 디자인 토큰 정립
- 색상 9종(colorset)만 존재, 타이포그래피·컴포넌트 토큰 미정립. Claude Design 협업으로 정립 예정.
- 참조: [design-brief.md](./design-brief.md)
