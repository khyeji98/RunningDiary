# SwiftUI Preview Convention

## 기본 규칙

- 모든 View 파일은 `#Preview` 블록을 반드시 포함한다.
- `#Preview` 블록은 파일의 **가장 마지막**에 위치한다.
- `// MARK: - Preview` 마커로 구분한다.

```swift
struct MyView: View { ... }

// MARK: - SubViews (있는 경우)

private struct SomeSubView: View { ... }

// MARK: - Preview   ← 항상 마지막

#Preview { ... }
```

## 픽스처 (Fixture)

- 여러 뷰에서 공유되는 더미 데이터는 `Core/Extensions/*+Preview.swift` 패턴으로 작성한다.
- 현재 제공되는 픽스처: `HealthKitWorkout.preview`

```swift
// Core/Extensions/HealthKitWorkout+Preview.swift
extension HealthKitWorkout {
    static var preview: HealthKitWorkout { ... }
}
```

## TCA Store 바인딩 뷰

`StoreOf<SomeFeature>`를 받는 뷰는 `Store(initialState:)` 로 스토어를 생성한다.

```swift
#Preview("기본 상태") {
    MyView(
        store: Store(
            initialState: SomeFeature.State(...)
        ) {
            SomeFeature()
        }
    )
}
```

- 외부 의존성(네트워크, DB 등)이 실행되어선 안 되는 경우 `withDependencies` 로 no-op 처리한다.

```swift
#Preview {
    MyView(
        store: Store(initialState: ...) {
            SomeFeature()
        } withDependencies: {
            $0.someClient.fetch = { [] }
        }
    )
}
```

## 다중 프리뷰

확인이 필요한 상태가 여러 개라면 `#Preview("이름")` 으로 명명한다.

```swift
#Preview("기본") { ... }

#Preview("항목 선택됨") {
    var state = SomeFeature.State(...)
    state.selected = [.itemA, .itemB]
    return MyView(store: Store(initialState: state) { SomeFeature() })
}
```

## 일반 SwiftUI 뷰 (Store 없음)

TCA 의존성이 없는 컴포넌트는 더미 값을 직접 주입한다.

```swift
#Preview {
    SomeButton(title: "확인", isSelected: false)
}

#Preview("선택됨") {
    SomeButton(title: "확인", isSelected: true)
}
```
