//
//  RunningConditionFeature.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import CommonFoundation
import ComposableArchitecture
import Foundation
import Models

@Reducer
struct RunningConditionFeature {
    @ObservableState
    struct State: Equatable {
        var selectedPainAreas: Set<PainArea> = []
        var selectedRunningStyle: RunninStyle?
        var memo: String = ""
        var selectedShoe: ShoeModel?

        let painAreaOptions = PainArea.allCases
        let runningStyleOptions = RunninStyle.allCases

        init(existingRecord: Diary?) {
            self.selectedPainAreas = Set(existingRecord?.painAreas ?? [])
            self.selectedRunningStyle = existingRecord?.runningStyle
            self.memo = existingRecord?.memo ?? ""
            self.selectedShoe = ShoeStorage.search(id: existingRecord?.shoes ?? "")
        }
    }

    enum Action {
        case updateSelectedPainAreas(Set<PainArea>)
        case updateSelectedRunningStyle(RunninStyle?)
        case updateMemo(String)
        case updateSelectedShoe(ShoeModel?)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .updateSelectedPainAreas(let areas):
                state.selectedPainAreas = areas
                return .none

            case .updateSelectedRunningStyle(let style):
                state.selectedRunningStyle = style
                return .none

            case .updateMemo(let text):
                state.memo = text
                return .none

            case .updateSelectedShoe(let shoe):
                state.selectedShoe = shoe
                return .none
            }
        }
    }
}
