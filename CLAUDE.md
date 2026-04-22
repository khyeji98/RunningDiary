# Running Log Diary

## Overview
- **Goal**: 러닝 일지와 컨디션을 기록·관리하는 iOS 앱
- **Core Design**: TCA 기반 예측 가능한 상태 관리와 모듈화된 Feature 구조
- **Key Concept**: 명확한 State–Action 경계, 데이터 주도 UI 업데이트

## Tech Stack
- **Architecture**: TCA (@Reducer, State, Action, Dependency)
- **Storage**: SwiftData (Repository pattern)
- **Integration**: HealthKit (distance/heart rate/cadence/route), WeatherKit
- **Min Target**: iOS 18.0

## Project Structure
- `RunDiary/Sources/Features/` — Feature 모듈 (Calendar, CreateDiary, DailyDetail, Settings)
- `RunDiary/Sources/Clients/` — TCA Dependency 클라이언트 (HealthKit, Persistences, RunningRecord, Weather)
- `RunDiary/Sources/Core/` — DesignSystem, Extensions, Storage, Utils
- `RunDiary/Sources/App/` — App Entry Point
- `Dependencies/` — 로컬 Swift 패키지 (CoreNetwork, HealthKitService, Models, PersistencesService 등)
- `RunDiaryTests/` — 테스트

## Build & Run
- **빌드**: `xcodebuild -scheme RunDiary -destination 'platform=iOS Simulator,name=iPhone 16'`
- **테스트**: `xcodebuild test -scheme RunDiaryTests -destination 'platform=iOS Simulator,name=iPhone 16'`

## Testing
- **Framework**: Swift Testing (`@Test`, `#expect`)
- **TCA**: Reducer 테스트는 반드시 TestStore 사용, Dependency는 mock 구현 필수
- **Naming**: `test_trigger_result`

## Workflow
- 코드 수정 완료 후 `xcodebuild` 빌드 실행
- 빌드 성공 시 `/commit` skill 실행
- 빌드 실패 시 에러 수정 후 재빌드
- 새 기능 구현 시 `@tdd` 파이프라인 실행 (PRD → TC → Test → Impl → Review)

## Key Decisions
- Navigation은 TCA tree-based (`@Reducer enum`) 사용
- CoreNetwork는 싱글톤 패키지로 분리
- TCA Dependency는 struct 기반 Client 패턴 (protocol 아님)

## Conventions
- **Code**: `~/.claude/rules/code-convention.md` (auto-loaded)
- **Commit**: `.claude/rules/commit-convention.md` (auto-loaded, 이모지 미사용)
- **Git workflow**: [CONTRIBUTING.md](./CONTRIBUTING.md)