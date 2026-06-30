---
name: feature-respec-tc
description: GitHub 이슈를 명세로 고정하고 TC 매트릭스를 도출해 기존 테스트를 명세-우선으로 재작성
---

# feature-respec-tc

이미 구현된 TCA Feature를 **GitHub 이슈로 명세화 → TC 매트릭스 도출 → 기존 테스트 재작성·복원**하는 워크플로우를 강제한다.
정통 forward TDD가 아니다. "명세 → TC → 테스트 재작성, 그 과정에서 구현 검증·수정"이다.

## 트리거
- "이슈 #NN 명세화 / TC 작성 / 테스트 재작성" 요청.
- 구현은 완료됐고 테스트를 명세 근거 위에 다시 세우려는 상황.

## 입력 체크리스트
1. 이슈 번호(#NN) 또는 신규 명세 대상 Feature
2. 대상 Feature 경로 (State/Action/Dependency)
3. 대상 테스트 파일 경로
4. 정책 결정(취소 처리·롤백·라우팅 등) — 누락 시 사용자에게 보완 요청
5. UI 화면 유무(스냅샷 단계 필요 여부)

## 작업 순서

### 1. 명세 수집·고정
- `mcp__github__get_issue`(owner `khyeji98`, repo `RunningDiary`)로 이슈 본문 read.
- 이슈가 좁거나 비었으면 `.github/ISSUE_TEMPLATE/feature.md` 양식으로 **재명세 초안** 작성 후 사용자 확인.
- 대상 Feature의 `State`/`Action`/`Dependency`를 스캔해 명세와 대조.

### 2. TC 매트릭스 도출
> **스펙 디렉토리 네이밍 (표준)**: `docs/specs/issue-{이슈번호}/` — 이슈 타입과 무관하게 `issue-` 접두어 + 이슈 번호. 예: 이슈 #23 → `docs/specs/issue-23/`. `#`는 경로명에 쓰지 않는다. 한 디렉토리에 `tc-matrix.md`, (UI 시) `ui-test-cases.md`를 둔다.

- `docs/specs/issue-{이슈번호}/tc-matrix.md` 생성 (`tc-matrix-template.md` 기반).
- reducer-level: 각 행 = given State + Action → expected State 변화 + received Actions.
- 표준 커버리지(정상/실패/취소/롤백/delegate/computed) 자가 점검.
- UI 화면이 있으면 빈 `docs/specs/issue-{이슈번호}/ui-test-cases.md` 사전 생성.
- 누락 정책/엣지케이스는 사용자에게 보완 요청.

### 3. 재작성 게이트 안내
- "주석화 → TC 단위 복원" 체크리스트를 이슈 본문/코멘트에 반영.
- 이후 단계는 **진입 시점에만** 해당 리프 문서를 읽고 진행:
  - Phase A′: `.claude/rules/phases/phase-a-reducer-respec.md`
  - Phase B: `.claude/rules/phases/phase-b-ui-cases.md`
  - Phase C: `.claude/rules/phases/phase-c-snapshot.md`

## 게이트 (직렬, 건너뛰기 금지)
1. **Gate 1**: 명세(이슈) → TC 매트릭스 → 재작성 순서.
2. **Gate 2**: TC 매트릭스 선확정(TODO 0) 후 테스트 재작성.
3. **Gate 3**: (UI) ui-test-cases.md → 스냅샷.
4. **Gate 4**: (UI) 에셋 매트릭스 코딩 전 확정.

## 역할 경계
- 분해/구조 설계는 메인 스레드. 구현/테스트 위임은 에이전트(@test-author, @domain-builder, @diff-reviewer).
- 작은 명세 변경의 TDD 흐름은 `/tdd`, 다범위 기능 분해는 `/feature`와 연계.

## 컨벤션
- 테스트: `.claude/rules/testing-convention.md` (한국어 `@Test`, `make*`, 기대값 상수, snake_case, GWT).
- 커밋/브랜치/이슈: `.claude/rules/git-convention.md`.
