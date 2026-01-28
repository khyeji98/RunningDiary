# Architecture

RunDiary는 **The Composable Architecture (TCA)** 를 기반으로 설계되어 단방향 데이터 흐름을 보장하고, 테스트 용이성과 상태 관리의 예측 가능성을 높였습니다.

## 📐 아키텍처 개요

앱은 크게 **Feature(UI & Logic)**, **Client (Interface)**, **Service (Implementation)**, **Model (Domain)** 계층으로 분리되어 있습니다.

```mermaid
graph TD
    App(RunDiary App) --> RootFeature
    
    subgraph "Presentation Layer (TCA)"
        RootFeature --> CalendarFeature
        RootFeature --> DailyRecordFeature
        RootFeature --> RecordFormFeature
    end
    
    subgraph "Domain Layer"
        CalendarFeature --> RecordClient
        DailyRecordFeature --> RecordClient
        RecordFormFeature --> RecordClient
        RecordFormFeature --> HealthClient
        RecordFormFeature --> WeatherClient
    end
    
    subgraph "Data Layer"
        RecordClient --> SwiftDataService
        HealthClient --> HealthKitService
        WeatherClient --> WeatherKitService
    end
```

## 🧩 모듈 구조

SPM(Swift Package Manager)을 활용하여 기능을 모듈화했습니다.

| 모듈명 | 역할 | 주요 내용 |
|--------|------|----------|
| **RunDiary** | 메인 앱 타겟 | `App.swift`, 최상위 뷰, Feature 조합 |
| **Dependencies** | 모듈 컨테이너 | 기능별 하위 모듈 포함 |
| ↳ **Models** | 도메인 모델 | `RunningRecord`, `Condition`, `WeatherInfo` 등 데이터 구조체 |
| ↳ **CommonFoundation** | 공통 유틸리티 | 기본 익스텐션, 유틸리티 함수 |
| ↳ **PersistencesService** | 로컬 저장소 | SwiftData 관련 로직 (CRUD, Container 설정) |
| ↳ **HealthKitService** | 헬스 데이터 | HealthKit 권한 요청 및 워크아웃 데이터 fetch |
| ↳ **WeatherKitService** | 날씨 데이터 | CoreLocation 및 WeatherKit을 이용한 날씨 조회 |
| ↳ **DependencyProxy** | 의존성 주입 | TCA `DependencyValues` 확장 및 클라이언트 인터페이스 정의 |

## 🔄 데이터 흐름 (Data Flow)

모든 상태 변경은 **Action**을 통해 시작되며, **Reducer**에서 처리된 후 **State**에 반영됩니다.

1.  **User Action**: 사용자가 "기록 추가" 버튼 클릭
2.  **Reducer**: `RecordFormFeature` Reducer가 액션 수신
3.  **Dependency Call**: `HealthClient`를 통해 HealthKit 데이터 요청
4.  **Effect**: 비동기 데이터 수신 후 `UpdateHealthData` 액션 반환
5.  **State Update**: 수신된 데이터로 State 업데이트 → View 자동 갱신
6.  **Persistence**: 저장 버튼 클릭 시 `RecordClient`를 통해 SwiftData에 영구 저장

## 🧪 테스트 전략

TCA의 `TestStore`를 활용하여 비즈니스 로직을 단위 테스트합니다.

-   **State 검증**: 액션 수행 전후의 State 변화를 정밀하게 assertion
-   **Effect 검증**: API 호출 등 Side Effect의 실행 및 결과 값 모의(Mocking) 검증
