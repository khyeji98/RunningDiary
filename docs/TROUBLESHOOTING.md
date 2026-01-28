# Troubleshooting & Learnings

개발 과정에서 마주친 주요 기술적 이슈와 해결 과정을 기록합니다.

## 1. CI/CD: Release 버전을 제대로 가져오지 못하는 문제
**상황**: CI 환경(Github Actions)에서 `agvtool`을 사용해 앱 버전을 추출하려 했으나, `1.1.0` 같은 값 대신 `$(MARKETING_VERSION)` 변수명 자체가 반환됨.
**원인**: 프로젝트 설정(`project.pbxproj`)에 `VERSIONING_SYSTEM`이 `apple-generic`으로 설정되어 있지 않아 `agvtool`이 정상 동작하지 않음.
**해결**:
`agvtool` 의존성을 제거하고, `xcodebuild` 명령어를 사용하여 타겟의 빌드 설정을 직접 조회하는 방식으로 변경하여 신뢰성을 확보함.

```bash
# 변경 전 (실패)
VERSION=$(agvtool what-marketing-version -terse1)

# 변경 후 (성공)
VERSION=$(xcodebuild -project RunDiary.xcodeproj -target RunDiary -configuration Release -showBuildSettings | grep 'MARKETING_VERSION =' | head -n 1 | awk '{print $3}')
```

## 2. GitHub Actions 권한 문제 (Resource not accessible)
**상황**: 릴리즈 노트 생성 워크플로(`create-release`)가 403 Forbidden 에러로 실패.
**원인**: GitHub Actions의 기본 `GITHUB_TOKEN` 권한은 읽기 전용으로 설정되어 있어 릴리즈 생성(쓰기)이 불가능했음.
**해결**: 워크플로 파일에 쓰기 권한을 명시적으로 부여.
```yaml
permissions:
  contents: write
```

## 3. GitHub Actions 빌드 최적화
**상황**: 문서(`README.md`)나 설정 파일 수정 시에도 무거운 빌드/테스트 워크플로가 실행되어 자원이 낭비됨.
**해결**: `paths` 필터를 적용하여 실제 제품 코드(`RunDiary/**`)나 의존성(`Dependencies/**`)이 변경되었을 때만 빌드가 트리거되도록 설정.
```yaml
on:
  push:
    paths:
      - 'RunDiary/**'
      - 'Dependencies/**'
      # 문서는 제외
```

## 4. SwiftData와 TCA 연동 구조
**과제**: TCA의 엄격한 상태 관리 흐름 속에서 SwiftData의 Observable 객체를 어떻게 동기화할 것인가에 대한 고민.
**해결**: 
- `PersistenceService` 모듈을 분리하여 데이터베이스 접근을 캡슐화.
- TCA의 `DependencyClient`를 통해 데이터를 주고받으며, Reducer 내부에서는 순수 데이터(Struct)로 변환하여 관리함으로써 Side Effect를 최소화함.
