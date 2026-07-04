# PR #23 Build & Test CI 실패 원인과 해결

> 대상 브랜치: `feat/23-apple-signin`  
> 대상 워크플로우: `.github/workflows/build-and-test.yml`  
> 관련 커밋: `9e44623`, `25710cb`

## 요약

PR #23의 `Build & Test` CI는 두 번의 독립적인 환경 문제로 실패했다.

1. CI 체크아웃 결과에 `Config/Secrets.xcconfig`가 없어 Xcode 프로젝트를 열지 못했다.
2. CI 러너의 최신 iOS Simulator 런타임에서 `iPhone 16` destination을 찾지 못했다.

두 문제 모두 앱 로직이나 테스트 코드 실패가 아니라, CI 실행 환경에서 필요한 파일과 시뮬레이터 destination을 안정적으로 준비하지 못해 발생했다.

## 1차 실패: `Secrets.xcconfig` 누락

### 실패 로그

```text
error: Unable to open base configuration reference file
'../Config/Secrets.xcconfig'. (in target 'RunDiary' from project 'RunDiary')
Testing failed: Testing cancelled because the build failed.
** TEST FAILED **
```

### 원인

Xcode 프로젝트가 `Config/Secrets.xcconfig`를 base configuration으로 참조하고 있었다. 하지만 실제 값 파일인 `Config/Secrets.xcconfig`는 `.gitignore` 대상이라 GitHub Actions 체크아웃 결과에는 존재하지 않았다.

저장소에는 `Config/Secrets.xcconfig.template`만 추적되고 있었고, `fastlane`의 `beta`/`release` lane은 빌드 전에 secrets 파일을 생성하지만 `build-and-test.yml`은 fastlane을 거치지 않고 `xcodebuild`를 직접 실행했다.

결과적으로 CI에서는 Xcode 프로젝트가 base config 파일을 열 수 없어 테스트 시작 전에 빌드가 중단됐다.

### 해결

`actions/checkout` 직후, Xcode가 프로젝트를 열기 전에 템플릿 파일을 복사해 `Config/Secrets.xcconfig`를 생성하도록 했다.

```yaml
- name: Generate Secrets.xcconfig
  run: cp Config/Secrets.xcconfig.template Config/Secrets.xcconfig
```

민감 값이 필요한 테스트가 아니고, 템플릿에는 비민감 기본값만 들어 있으므로 CI 빌드용 placeholder config로 충분하다.

## 2차 실패: `iPhone 16` destination 미존재

### 실패 로그

```text
xcodebuild: error: Unable to find a device matching the provided destination specifier:
        { platform:iOS Simulator, OS:latest, name:iPhone 16 }
```

### 원인

기존 워크플로우는 다음처럼 시뮬레이터 이름을 고정했다.

```yaml
DESTINATION: "platform=iOS Simulator,name=iPhone 16"
```

`OS`를 지정하지 않으면 `xcodebuild`는 이를 `OS:latest`로 해석한다. GitHub Actions의 `macos-latest`와 `latest-stable` Xcode 조합에서는 최신 iOS 런타임에 `iPhone 16` 디바이스가 없을 수 있다.

즉, `iPhone 16` 자체가 전혀 없는 것이 아니라, "최신 OS 런타임의 iPhone 16" 조합이 CI 러너에 없어서 destination 매칭에 실패했다.

### 해결

고정 문자열 대신 CI 러너에 실제로 존재하는 iPhone 시뮬레이터 UDID를 `simctl`로 찾고, `xcodebuild`에는 이름이 아닌 `id` 기반 destination을 전달하도록 변경했다.

```yaml
- name: Select iOS Simulator
  run: |
    SIMULATOR_UDID=$(xcrun simctl list devices available | grep -E "iPhone 16 \([0-9A-F-]{36}\) \((Shutdown|Booted)\)" | head -n 1 | sed -E "s/.*\(([0-9A-F-]{36})\).*/\1/")

    if [ -z "$SIMULATOR_UDID" ]; then
      SIMULATOR_UDID=$(xcrun simctl list devices available | grep -E "iPhone .* \([0-9A-F-]{36}\) \((Shutdown|Booted)\)" | head -n 1 | sed -E "s/.*\(([0-9A-F-]{36})\).*/\1/")
    fi

    if [ -z "$SIMULATOR_UDID" ]; then
      xcrun simctl list devices available
      exit 1
    fi

    echo "DESTINATION=platform=iOS Simulator,id=$SIMULATOR_UDID" >> "$GITHUB_ENV"
    echo "Selected simulator: $SIMULATOR_UDID"
```

우선 `iPhone 16`을 선택하되, 해당 기기가 없으면 사용 가능한 첫 번째 iPhone 시뮬레이터로 fallback한다. 이후 `xcodebuild`는 `$DESTINATION`을 그대로 사용한다.

```yaml
xcodebuild clean test \
  -workspace RunDiary.xcodeproj/project.xcworkspace \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -enableCodeCoverage YES \
  -skipMacroValidation \
  -skipPackagePluginValidation
```

## 최종 해결 흐름

최종 CI 준비 순서는 다음과 같다.

1. 저장소 체크아웃
2. `Config/Secrets.xcconfig.template`을 `Config/Secrets.xcconfig`로 복사
3. Xcode 버전 설정
4. 사용 가능한 iPhone Simulator UDID 선택
5. Swift Package Dependencies resolve
6. 선택된 simulator destination으로 `xcodebuild clean test` 실행

## 검증

로컬에서 다음을 확인했다.

- `build-and-test.yml` YAML 파싱 성공
- `Config/Secrets.xcconfig.template` 복사 명령 정상 동작
- `xcodebuild -resolvePackageDependencies` 성공
- `simctl` 기반 선택식이 로컬 `iPhone 16` UDID를 정상 선택
- UDID 기반 destination으로 `PainAreasMapperTests` 실행 성공

전체 테스트는 별도 스냅샷 테스트 실패가 있었지만, 이번 CI 실패 원인이었던 base config 누락과 simulator destination 매칭 문제는 해결됐다.

## 재발 방지 포인트

- CI에서 `.gitignore` 대상 파일을 Xcode build setting이 참조한다면, 체크아웃 직후 생성 스텝을 둔다.
- GitHub Actions macOS 러너의 시뮬레이터 목록은 Xcode/macOS 이미지 업데이트에 따라 바뀔 수 있으므로, 특정 `name + OS:latest` 조합에 의존하지 않는다.
- iOS CI의 `xcodebuild -destination`은 가능하면 실제 러너에서 선택한 UDID 기반으로 전달한다.
- `macos-latest`, `latest-stable`처럼 moving target을 쓰는 워크플로우는 러너 이미지 변화에 취약하므로, 필요하면 Xcode 버전 또는 macOS 이미지를 고정하는 것도 고려한다.
