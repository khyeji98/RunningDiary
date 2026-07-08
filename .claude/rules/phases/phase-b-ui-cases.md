# Phase B — ui-test-cases.md 작성 (UI 시각 변형 매트릭스)

> 이 문서는 **Phase B 진입 시점에만** 읽는다.

## 목적
대상 화면(SwiftUI View)의 **모든 시각적 변형을 매트릭스로 정의**한다. Phase C의 스냅샷 케이스가 이 표를 1:1 가이드로 삼는다.

## 산출물
- 위치: `docs/specs/issue-{이슈번호}/ui-test-cases.md`
- 형식: 9개 컬럼 마크다운 표 (Phase A′ 시작 시 빈 셸로 사전 생성).

## 컬럼 9개 및 작성 규칙
| 컬럼 | 규칙 |
|---|---|
| case id | `<screen>-<component>-<variant>` (kebab-case, 공백 없음) |
| 컴포넌트 | 실제 SwiftUI 타입명과 일치 |
| 상태/입력 조건 | TCA `State` 값으로 기술 (예: `isLoading=true`, `errorMessage="…"`) |
| 테마 | 도메인 분기 있으면 명시, 없으면 `—` |
| 언어 / DynamicType | 기본 `ko_KR / .large`, 접근성 `.accessibilityExtraLarge` |
| Light/Dark | **독립 행으로 분리** (동일 시나리오 2행) |
| 디바이스 | 기본 `iPhone 15`, 다른 사이즈만 명시 |
| 기대 시각 결과 | 스냅샷 미열람 상태에서도 리뷰어가 이해 가능한 기술적 묘사 |
| 스냅샷 파일명 | `<case-id>.png` (Phase C 재사용) |

## 최소 커버리지 체크리스트
1. **상태 분기**: 화면이 가질 수 있는 상태(loading/loaded/empty/error)만큼만.
2. **테마 분기**: 있으면 각각 최소 1행.
3. **선택 필드 분기**: 의미 있는 nil/존재, 0/1/N 케이스.
4. **Light/Dark 쌍**: 동일 시나리오마다 2행.
5. **접근성 DynamicType**: 텍스트 비중 큰 컴포넌트 최소 1~2행.

## 권장 작성 순서
1. 각 컴포넌트의 "정상 loaded" Light 기본 케이스
2. 동일 행 Dark 복제
3. 테마/선택 필드 분기 추가
4. 상태 분기(loading/empty/error) 추가
5. 접근성 DynamicType 1~2행

## 종료 조건
- `<!-- TODO -->` 0개
- 9개 컬럼 완전성
- 모든 행에 스냅샷 파일명 기재
- 최소 커버리지 5항목 자가 점검
- 표만으로 스냅샷 내용을 머릿속에 그릴 수 있는 수준

## 안티 패턴
- 기본 1개만 찍고 나머지 PR 후 추가 → 매트릭스 불완전.
- Light/Dark 한 행에 묶기 → 각각 다른 파일이므로 분리 필수.
- "기대 결과"에 "Figma와 동일"만 기록 → 독립 이해 불가.
- 접근성 DynamicType 생략 → 텍스트 잘림은 가장 흔한 회귀.

## 다음 단계
종료 조건 충족 → `phase-c-snapshot.md` 개시.
