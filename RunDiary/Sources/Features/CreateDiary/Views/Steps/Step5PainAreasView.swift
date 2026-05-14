//
//  Step5PainAreasView.swift
//  RunDiary

import ComposableArchitecture
import Models
import SwiftUI

struct Step5PainAreasView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>
    @State private var rippleTriggers: [PainArea: UUID] = [:]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    StepTitleLabel(L10n.recordStepTitlePain)

                    BodyPainCanvas(
                        selected: store.selectedPainAreas,
                        rippleTriggers: rippleTriggers
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                }
                .frame(height: geo.size.height * 0.7)

                Divider()

                ScrollView {
                    DynamicGridLayout(items: PainArea.allCases, spacing: 8) { area in
                        PainPointButton(
                            area: area,
                            isSelected: store.selectedPainAreas.contains(area)
                        ) {
                            toggle(area)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .frame(height: geo.size.height * 0.3)
            }
        }
    }

    private func toggle(_ area: PainArea) {
        var next = store.selectedPainAreas
        if next.contains(area) {
            next.remove(area)
            rippleTriggers.removeValue(forKey: area)
        } else {
            next.insert(area)
            rippleTriggers[area] = UUID()
        }
        store.send(.updateSelectedPainAreas(next))
    }
}

private struct BodyPainCanvas: View {
    let selected: Set<PainArea>
    let rippleTriggers: [PainArea: UUID]

    var body: some View {
        GeometryReader { geo in
            let imageSize = geo.size.width
            let yOffset = (geo.size.height - imageSize) / 2

            ZStack(alignment: .topLeading) {
                Image("img_body")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(Color.gray300)
                    .frame(width: imageSize, height: imageSize)
                    .offset(y: yOffset)

                ForEach(PainArea.allCases, id: \.self) { area in
                    if selected.contains(area) {
                        Circle()
                            .fill(Color.coral)
                            .frame(width: 10, height: 10)
                            .position(
                                x: imageSize * area.anchor.x,
                                y: yOffset + imageSize * area.anchor.y
                            )

                        if let trigger = rippleTriggers[area] {
                            PainPointRippleEffect()
                                .id(trigger)
                                .position(
                                    x: imageSize * area.anchor.x,
                                    y: yOffset + imageSize * area.anchor.y
                                )
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}

// MARK: - Preview

#Preview("선택 없음") {
    Step5PainAreasView(
        store: Store(
            initialState: CreateDiaryFeature.State(healthKitWorkout: .preview)
        ) {
            CreateDiaryFeature()
        }
    )
}

#Preview("무릎·종아리·발목 선택됨") {
    var state = CreateDiaryFeature.State(healthKitWorkout: .preview)
    state.selectedPainAreas = [.knee, .calf, .ankle]

    return Step5PainAreasView(
        store: Store(initialState: state) {
            CreateDiaryFeature()
        }
    )
}
