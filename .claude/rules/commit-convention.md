# Commit Convention (RunDiary)

> 본 프로젝트 한정. 전역 규칙(`~/.claude/rules/commit-convention.md`)을 오버라이드한다.

## Format
```
{header}: {message}
```

이모지를 사용하지 않는다.

## Header

| Header     | Description                          |
|------------|--------------------------------------|
| `feat`     | 기능 구현 관련 작업                  |
| `fix`      | 버그나 이슈 수정                     |
| `refactor` | 리팩토링, 코드변경(린팅, 포맷팅 등) |
| `hotfix`   | 긴급 수정(릴리즈 직후 이슈 수정)    |
| `docs`     | 문서 수정/추가                       |
| `remove`   | 파일 삭제                            |
| `chore`    | 기타 등등                            |

## Message Rules
- 헤더 + 메시지 한 줄은 50글자 이하로 작성한다.
- 마침표를 붙이지 않는다.
- 무엇과 왜를 명시한다.
- 어떻게를 명시해야 할 경우 빈 줄을 추가하고 본문으로 작성한다.

## Examples
```
feat: HealthKit 러닝 데이터 자동 가져오기 구현

fix: 날짜 캐러셀 오프셋 계산 오류 수정

refactor: NetworkService를 CoreNetwork 싱글톤 패키지로 교체

docs: README에 프로젝트 설정 가이드 추가

feat: 캘린더 뷰에 만족도 시각화 추가

HealthKit 쿼리 결과를 월별로 그룹핑하여
캘린더 셀에 컬러 인디케이터로 표시
```
