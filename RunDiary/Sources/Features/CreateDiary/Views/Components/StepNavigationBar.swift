//
//  StepNavigationBar.swift
//  RunDiary
//

import ComposableArchitecture
import SwiftUI

struct StepNavigationBar: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>

    var body: some View {
        HStack(spacing: 12) {
            if !store.currentStep.isFirst {
                PreviousButton {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        _ = store.send(.previousStepTapped)
                    }
                }
            }

            if store.currentStep.isLast {
                SaveButton(isEnabled: store.isFormValid && !store.isLoading) {
                    _ = store.send(.saveRecord)
                }
            } else {
                NextButton(isEnabled: canGoNext) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        _ = store.send(.nextStepTapped)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var canGoNext: Bool {
        switch store.currentStep {
        case .fitness: return true
        case .weather:
            return store.skyCondition != nil
                && store.windLevel != nil
                && store.feelsLike != nil
                && store.humidityLevel != nil

        case .shoes: return store.selectedShoe != nil
        case .runningStyle: return store.selectedRunningStyle != nil
        case .painAreas: return true
        case .difficulty: return store.selectedDifficultyLevel != nil
        case .memo: return true
        }
    }
}

private struct PreviousButton: View {
    private let onTap: () -> Void

    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            L10n.uiPrevious.text
                .font(.body.weight(.medium))
                .foregroundStyle(Color.blue700)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue300, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct NextButton: View {
    private let isEnabled: Bool
    private let onTap: () -> Void

    init(isEnabled: Bool, onTap: @escaping () -> Void) {
        self.isEnabled = isEnabled
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            L10n.uiNext.text
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(isEnabled ? Color.blue300 : Color.blue300.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct SaveButton: View {
    private let isEnabled: Bool
    private let onTap: () -> Void

    init(isEnabled: Bool, onTap: @escaping () -> Void) {
        self.isEnabled = isEnabled
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            L10n.uiSave.text
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(isEnabled ? Color.blue300 : Color.blue300.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
