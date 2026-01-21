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
        // Pain & Style
        var selectedPainAreas: Set<PainArea> = []
        var selectedRunningStyle: RunninStyle?

        // Condition
        var sleepHours: String = ""
        var memo: String = ""

        // Shoes
        var selectedShoe: ShoeModel?

        // Static Options
        let painAreaOptions = PainArea.allCases
        let runningStyleOptions = RunninStyle.allCases

        init(existingRecord: Diary?) {
            self.selectedPainAreas = Set(existingRecord?.painAreas ?? [])
            self.selectedRunningStyle = existingRecord?.runningStyle
            self.sleepHours = existingRecord?.condition.sleep?.toString ?? ""
            self.memo = existingRecord?.condition.memo ?? ""
            self.selectedShoe = ShoeStorage.search(id: existingRecord?.shoes ?? "")
        }
    }

    enum Action {
        case updateSelectedPainAreas(Set<PainArea>)
        case updateSelectedRunningStyle(RunninStyle?)
        case updateSleepHours(String)
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

            case .updateSleepHours(let hours):
                state.sleepHours = hours
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
