---
name: refresh-strings
description: Refresh L10n.swift from String Catalog
---

Localizable.xcstrings -> L10n.swift 갱신

## 작업 순서

1. **스크립트 확인**: `Scripts/generate_l10n.{swift,py}` 존재 시 실행
2. **수동 갱신** (스크립트 없을 시):
   - `RunDiary/Resources/Localizable.xcstrings` 파싱
   - 키 -> 계층구조 변환 (`ui.cancel` -> `L10n.UI.cancel`)
   - `RunDiary/Sources/Generated/L10n.swift` 업데이트
3. **빌드 테스트**: `xcodebuild -scheme RunDiary -destination 'generic/platform=iOS Simulator' build`
4. **결과 보고**: 변경사항, 빌드 상태, 다음 단계

## 변환 규칙
- dot(`.`) -> enum 계층, underscore(`_`) -> camelCase
- 예: `healthkit.error.not_available` -> `L10n.Healthkit.Error.notAvailable`
- 코드: `static let cancel = String(localized: "ui.cancel") // Cancel`

## 주의사항
- 기존 구조/주석 유지
- camelCase 일관성
- 빌드 실패 시 되돌리지 말고 오류 보고
- 중복 키 체크

## 파일 경로
- 소스: `RunDiary/Resources/Localizable.xcstrings`
- 대상: `RunDiary/Sources/Generated/L10n.swift`

## 예시 출력
```
L10n.swift 갱신 완료
- 변경/삭제된 키: 0개
- 총 키: 58개, 파일: 8.5KB, Enum: 6개
빌드 성공 (3.2초)
```
