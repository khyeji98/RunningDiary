//
//  Step1FitnessView.swift
//  RunDiary
//

import Models
import SwiftUI

struct Step1FitnessView: View {
    private let workout: HealthKitWorkout

    init(workout: HealthKitWorkout) {
        self.workout = workout
    }

    var body: some View {
        VStack(spacing: 0) {
            StepTitleLabel(L10n.recordStepTitleFitness)

            ScrollView {
                HealthKitSectionView(workout: workout)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
    }
}
