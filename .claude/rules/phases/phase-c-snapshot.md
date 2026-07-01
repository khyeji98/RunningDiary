# Phase C — 스냅샷 테스트 (swift-snapshot-testing)

> 이 문서는 **Phase C 진입 시점에만** 읽는다.

## 진입 요건
Phase B(`ui-test-cases.md` 작성) 완료가 선행 조건.

## 의존성
- `pointfreeco/swift-snapshot-testing`을 SPM으로 `RunDiaryTests` 타겟에 추가.
- 기존에 추가돼 있으면 재사용, 신규면 현재 PR에 포함.
- `__Snapshots__/`는 git 추적.

## 작업 흐름 (케이스별 RED → GREEN)
1. `ui-test-cases.md`의 행을 SnapshotTests 케이스로 전환.
2. `assertSnapshot(of: …, as: .image(…))` 호출만 작성.
3. 실행 → 참조 스냅샷 없음(RED).
4. 필요 시 SwiftUI 뷰 보강.
5. **record 모드 1회 활성화** → PNG 생성 → 눈으로 검증 → 기대 결과 일치 확인.
6. **record 비활성화** → 재실행 → GREEN.
7. 다음 케이스.

> ⚠️ record를 켠 채 머지하면 모든 테스트가 무조건 통과되어 회귀 보호가 무력화된다.

## 전체 케이스 고정 파라미터
| 항목 | 설정값 | 목적 |
|---|---|---|
| 디바이스 | iPhone 15(프로젝트 표준) | 픽셀 일관성 |
| 지역 | ko_KR | 기본값 |
| 텍스트 크기 | .large(기본), .accessibilityExtraLarge(접근성) | ui-test-cases.md 일치 |
| 명/암 모드 | 각각 별도 케이스 | 한 행 통합 금지 |
| 시간 | 고정값 | 시간 의존 컴포넌트 결정성 |
| UUID/이미지 | mock/placeholder 동기 주입 | 플레이키 방지 |

## Record 모드 운용 규칙
**허용:** 신규 케이스만 1회 record 후 즉시 OFF / 의도적 시각 변경 시 PR 본문에 사유 + before·after 첨부 후 record.
**금지:** 분석 없이 덮어쓰기 / 코드에 record 상태 유지 / 전체 케이스 일괄 record.

## 종료 체크리스트
- [ ] `ui-test-cases.md` 전 행에 스냅샷 케이스 대응
- [ ] 매트릭스 전 케이스 GREEN
- [ ] `__Snapshots__` PNG diff를 PR 본문 첨부
- [ ] record 갱신은 의도적 변경만
- [ ] 고정값(지역/DynamicType/명암 등) 코드 명시
- [ ] 빌드 경고/에러 0 (SWIFT_STRICT_CONCURRENCY)

## 안티 패턴
1. 분석 없이 깨진 스냅샷 record로 덮어쓰기
2. record 유지 → CI 항상 통과 → 회귀 미감지
3. 케이스마다 환경(언어/디바이스) 변경 → 플레이키
4. 비동기 이미지 로드 전 스냅샷 생성
5. 시간 의존 컴포넌트에 실제 `Date()` 사용
6. `ui-test-cases.md` 갱신 없이 신규 케이스 추가
