# Git Convention

## Branch

| 브랜치 | 용도 |
|--------|------|
| `main` | 기본 브랜치 |
| `feature/{description}` | 기능 구현 (e.g., `feature/calendar-view`) |
| `fix/{description}` | 버그 수정 |
| `refactor/{description}` | 리팩터링 |

## Commit

형식: `type: description (#issue_number)`

예시: `feat: 캘린더 뷰 구현 (#1)`

| type | 용도 |
|------|------|
| `feat` | 기능 구현 |
| `fix` | 버그 수정 |
| `refactor` | 리팩터링 |
| `docs` | 문서 수정 |
| `test` | 테스트 추가/수정 |
| `chore` | 기타 |

- description: 한국어
- issue_number: 관련 이슈 번호
- body(선택): 빈 줄 후 한국어로 무엇을, 왜 변경했는지
- Atomic commit: 커밋 단위가 빌드 가능한 상태여야 한다
- **금지**: "Generated with Claude Code" 문구, "Co-Authored-By" attribution

## Issue

형식: `type: description` (e.g., `feat: 캘린더 뷰 구현`)

- content: 한국어
- assignee: self
- template: `.github/ISSUE_TEMPLATE/feature.md`

## Pull Request

형식: `type: description`

- content: 한국어
- template: `.github/PULL_REQUEST_TEMPLATE.md`
- 권장 크기: 500줄 미만
- assignee: self
- issue 연결: `Closes #number`
