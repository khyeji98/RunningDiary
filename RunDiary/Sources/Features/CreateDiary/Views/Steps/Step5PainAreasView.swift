//
//  Step5PainAreasView.swift
//  RunDiary

import ComposableArchitecture
import Models
import SwiftUI

struct Step5PainAreasView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>
    @State private var lastRippleArea: PainArea?
    @State private var rippleTriggerID: UUID?

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    StepTitleLabel(L10n.recordStepTitlePain)

                    BodyPainCanvas(
                        selected: store.selectedPainAreas,
                        lastRippleArea: lastRippleArea,
                        rippleTriggerID: rippleTriggerID
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
        let isSelecting = !next.contains(area)
        if isSelecting {
            next.insert(area)
            lastRippleArea = area
            let newID = UUID()
            rippleTriggerID = newID
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                guard rippleTriggerID == newID else { return }
                lastRippleArea = nil
                rippleTriggerID = nil
            }
        } else {
            next.remove(area)
        }
        store.send(.updateSelectedPainAreas(next))
    }
}

private struct BodyPainCanvas: View {
    let selected: Set<PainArea>
    let lastRippleArea: PainArea?
    let rippleTriggerID: UUID?

    // img_body.png 비율: 1504 × 2800
    private static let imageAspect: CGFloat = 1504.0 / 2800.0

    var body: some View {
        GeometryReader { geo in
            let containerWidth = geo.size.width
            let containerHeight = geo.size.height
            let isWidthLimited = containerWidth / containerHeight <= Self.imageAspect
            let renderWidth: CGFloat = isWidthLimited ? containerWidth : containerHeight * Self.imageAspect
            let renderHeight: CGFloat = isWidthLimited ? containerWidth / Self.imageAspect : containerHeight
            let xOff = (containerWidth - renderWidth) / 2
            let yOff = (containerHeight - renderHeight) / 2

            ZStack {
                Image("img_body")
                    .resizable()
                    .scaledToFit()
                    .frame(width: containerWidth, height: containerHeight)

                if let area = lastRippleArea, let id = rippleTriggerID {
                    PainRippleEffect()
                        .id(id)
                        .position(
                            x: xOff + renderWidth * area.anchor.x,
                            y: yOff + renderHeight * area.anchor.y
                        )
                }
            }
            .frame(width: containerWidth, height: containerHeight)
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
