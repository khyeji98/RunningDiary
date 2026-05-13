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

private struct BodyPainCanvas: View {
    let selected: Set<PainArea>
    let onToggle: (PainArea) -> Void

    var body: some View {
        GeometryReader { geo in
            // SVG는 1:1 비율이므로 컨테이너 너비에 맞춰 정사각형으로 렌더
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
                    PainPointButton(
                        area: area,
                        isSelected: selected.contains(area)
                    ) {
                        onToggle(area)
                    }
                    .position(
                        x: imageSize * area.anchor.x,
                        y: yOffset + imageSize * area.anchor.y
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
