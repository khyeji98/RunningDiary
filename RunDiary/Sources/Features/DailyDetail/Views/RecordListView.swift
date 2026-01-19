//
//  RecordListView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import ComposableArchitecture
import Models
import SwiftUI

struct RecordListView: View {
    let store: StoreOf<DailyDetailFeature>
    let diaries: [Diary]
    let workouts: [HealthKitWorkout]

    init(
        store: StoreOf<DailyDetailFeature>,
        diaries: [Diary],
        workouts: [HealthKitWorkout]
    ) {
        self.store = store
        self.diaries = diaries
        self.workouts = workouts
    }

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(diaries) { diary in
                RunningRecordCard(record: diary, onEdit: { store.send(.editRecord(diary)) })
            }

            if !diaries.isEmpty, let trademark = store.weatherTrademark {
                WeatherTrademarkView(trademark: trademark)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 8)
            }

            if !diaries.isEmpty && !workouts.isEmpty {
                Divider()
                    .padding(.vertical, 10)
            }

            ForEach(workouts) { workout in
                HealthKitWorkoutCard(record: workout, onCreate: { store.send(.createRecord(workout)) })
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
    }
}



// MARK: - Preview

#Preview(traits: .sampleData) {
    ScrollView(.vertical) {
        RunningRecordCard(record: RunningRecordPersistenceModel.preview.toDomain(), onEdit: {})
    }
}
