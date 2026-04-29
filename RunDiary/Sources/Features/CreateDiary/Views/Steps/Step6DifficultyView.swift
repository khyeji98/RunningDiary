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
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(DifficultyLevel.allCases, id: \.self) { level in
                DifficultyBar(
                    level: level,
                    isSelected: shouldFill(level)
                ) {
                    onSelect(level)
                }
            }
        }
    }

    private func shouldFill(_ level: DifficultyLevel) -> Bool {
        guard let selected else { return false }
        return level.rawValue <= selected.rawValue
    }
}

private struct DifficultyBar: View {
    let level: DifficultyLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue300 : Color.gray100)
                .frame(maxWidth: .infinity)
                .frame(height: barHeight)
        }
        .buttonStyle(.plain)
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
