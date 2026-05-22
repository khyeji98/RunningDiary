//
//  Step6DifficultyView.swift
//  RunDiary
//

import ComposableArchitecture
import Models
import SwiftUI

struct Step6DifficultyView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>

    var body: some View {
        VStack(spacing: 0) {
            StepTitleLabel(L10n.recordStepTitleDifficulty)

            Spacer()

            VStack(spacing: 24) {
                DifficultyBarRow(
                    selected: store.selectedDifficultyLevel
                ) {
                    store.send(.updateSelectedDifficultyLevel($0))
                }
                .frame(height: 160)

                if let level = store.selectedDifficultyLevel {
                    Text(level.displayName)
                        .font(.headline)
                        .foregroundStyle(.blue700)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

private struct DifficultyBarRow: View {
    let selected: DifficultyLevel?
    let onSelect: (DifficultyLevel) -> Void

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    DifficultyBar(level: level, isSelected: shouldFill(level))
                }
            }
            .overlay {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                onSelect(levelAt(x: value.location.x, width: geometry.size.width))
                            }
                    )
            }
        }
    }

    private func shouldFill(_ level: DifficultyLevel) -> Bool {
        guard let selected else { return false }
        return level.rawValue <= selected.rawValue
    }

    private func levelAt(x: CGFloat, width: CGFloat) -> DifficultyLevel {
        let fraction = max(0, min(x / width, 1))
        let count = DifficultyLevel.allCases.count
        let index = min(Int(fraction * CGFloat(count)), count - 1)
        return DifficultyLevel.allCases[index]
    }
}

private struct DifficultyBar: View {
    let level: DifficultyLevel
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.blue300 : Color.gray100)
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)
    }

    private var barHeight: CGFloat {
        switch level {
        case .veryEasy: return 50
        case .easy: return 80
        case .medium: return 110
        case .hard: return 135
        case .veryHard: return 160
        }
    }
}

// MARK: - Preview

#Preview {
    Step6DifficultyView(
        store: Store(
            initialState: CreateDiaryFeature.State(healthKitWorkout: .preview)
        ) {
            CreateDiaryFeature()
        }
    )
}

#Preview("어려움 선택됨") {
    var state = CreateDiaryFeature.State(healthKitWorkout: .preview)
    state.selectedDifficultyLevel = .hard

    return Step6DifficultyView(
        store: Store(initialState: state) {
            CreateDiaryFeature()
        }
    )
}
