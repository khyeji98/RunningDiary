//
//  Step5PainAreasView.swift
//  RunDiary
//

import ComposableArchitecture
import Models
import SwiftUI

struct Step5PainAreasView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>

    var body: some View {
        VStack(spacing: 0) {
            StepTitleLabel(L10n.recordStepTitlePain)

            BodyPainCanvas(
                selected: store.selectedPainAreas
            ) { area in
                var next = store.selectedPainAreas
                if next.contains(area) {
                    next.remove(area)
                } else {
                    next.insert(area)
                }
                store.send(.updateSelectedPainAreas(next))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

private struct BodyPainCanvas: View {
    let selected: Set<PainArea>
    let onToggle: (PainArea) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                BodyPlaceholder()

                ForEach(PainArea.allCases, id: \.self) { area in
                    PainPointButton(
                        area: area,
                        isSelected: selected.contains(area)
                    ) {
                        onToggle(area)
                    }
                    .position(
                        x: geo.size.width * area.anchor.x,
                        y: geo.size.height * area.anchor.y
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct BodyPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.gray100.opacity(0.5))
            .overlay(
                Text("Body Placeholder")
                    .font(.caption)
                    .foregroundStyle(.gray500)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
