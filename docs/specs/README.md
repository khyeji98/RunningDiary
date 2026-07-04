# Specs

명세-우선 테스트 재작성 워크플로우의 산출물(TC 매트릭스, UI 테스트 케이스 표)을 보관한다.

## 디렉토리 네이밍 (표준)

- 폴더명은 이슈 타입과 무관하게 **`issue-{이슈번호}`** 로 통일한다.
  - 예: 이슈 #23 → `docs/specs/issue-23/`
- `#`는 경로명에 쓰지 않는다.

## 폴더 구성

| 파일 | 설명 |
|---|---|
| `tc-matrix.md` | Reducer-level TC 매트릭스 (given State + Action → State 변화 + received) |
| `ui-test-cases.md` | (UI 화면이 있는 경우) 9컬럼 시각 변형 매트릭스 |
| `ci-build-and-test-failure.md` | (CI 이슈가 있는 경우) Build & Test 실패 원인과 해결 기록 |

## 권위 출처

네이밍/생성 규칙의 단일 진실 소스는 `feature-respec-tc` 스킬(`.claude/skills/feature-respec-tc/SKILL.md`)이다.
관련 컨벤션: `.claude/rules/testing-convention.md`, `.claude/rules/phases/`(phase-a/b/c).
