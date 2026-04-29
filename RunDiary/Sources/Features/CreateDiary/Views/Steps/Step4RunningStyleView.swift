//
//  Step4RunningStyleView.swift
//  RunDiary
//

import ComposableArchitecture
import Models
import SwiftUI

struct Step4RunningStyleView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>

    var body: some View {
        VStack(spacing: 0) {
            StepTitleLabel(L10n.recordStepTitleStyle)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(RunninStyle.allCases, id: \.self) { style in
                        RunningStyleCard(
                            style: style,
                            isSelected: store.selectedRunningStyle == style
                        ) {
                            store.send(.updateSelectedRunningStyle(style))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct RunningStyleCard: View {
    let style: RunninStyle
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                FootIcon(style: style, isSelected: isSelected)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.localizedName)
                        .font(.headline)
                        .foregroundStyle(isSelected ? Color.blue700 : Color.gray700)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.gray500)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .background(isSelected ? Color.blue300.opacity(0.1) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue300 : Color.gray100, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var description: String {
        switch style {
        case .forefoot: return "앞꿈치부터 닿는 주법"
        case .midfoot: return "발 중간이 먼저 닿는 주법"
        case .heelfoot: return "뒤꿈치부터 닿는 주법"
        }
    }
}

private struct FootIcon: View {
    let style: RunninStyle
    let isSelected: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.gray100)

            Capsule()
                .fill(isSelected ? Color.blue300 : Color.gray300)
                .frame(width: 24, height: 18)
                .offset(y: highlightOffset)
        }
    }

    private var highlightOffset: CGFloat {
        switch style {
        case .forefoot: return -16
        case .midfoot: return 0
        case .heelfoot: return 16
        }
    }
}
