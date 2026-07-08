# TC 매트릭스 — {FeatureName}

> 이슈: #{NN}
> 대상 Feature: `{FeaturePath}`
> 대상 테스트: `{TestFilePath}`

## Reducer-level TC

각 행 = given State + send Action → expected State 변화 + received Actions.

| tc id | given (initial State) | when (Action) | then (State 변화) | then (received) | 비고 |
|---|---|---|---|---|---|
| `{feature}-{action}-{variant}` |  | `.{action}` |  | `.{received}` |  |

## 커버리지 자가 점검
- [ ] 액션별 정상 경로
- [ ] 실패/에러 경로
- [ ] 도메인 특수 분기(취소 등)
- [ ] 낙관적 업데이트 → 실패 시 롤백
- [ ] delegate / dismiss / 자식 Feature 통합
- [ ] computed property
- [ ] 사용자 노출 에러 메시지 정확성

## Client/Service-level TC (해당 시)

| tc id | given (mock) | when | then | 비고 |
|---|---|---|---|---|
|  |  |  |  |  |

## 재작성 진행 체크리스트
- [ ] 대상 테스트 파일 전체 주석화
- [ ] TC 단위 복원(작성→해제→실행→구현 수정)
- [ ] 전부 GREEN, 주석 잔여 0
- [ ] strict concurrency 경고 0
