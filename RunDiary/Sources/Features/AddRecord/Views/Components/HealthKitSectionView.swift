//
//  HealthKitSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import SwiftUI
import Models

struct HealthKitSectionView: View {
    let workout: HealthKitWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("record.section.workout")
                    .font(.headline)
                    .foregroundStyle(.blue700)
            }
            .padding(.bottom, 4)

            VStack(spacing: 12) {
                HStack {
                    L10n.recordFieldDistance.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(workout.formattedDistance)
                        .foregroundStyle(.blue700)
                    L10n.unitKm.text
                        .foregroundColor(.gray)
                }

                HStack {
                    L10n.recordFieldDuration.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(workout.formattedDuration)
                        .foregroundStyle(.blue700)
                }

                HStack {
                    L10n.recordFieldPace.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(workout.averagePace)
                        .foregroundStyle(.blue700)
                }

                HStack {
                    L10n.recordFieldHeartRate.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(workout.formattedAverageHeartRate)
                        .foregroundStyle(.blue700)
                    L10n.unitBpm.text
                        .foregroundColor(.gray)
                }

                HStack {
                    L10n.recordFieldCadence.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(workout.formattedAverageCadence)
                        .foregroundStyle(.blue700)
                    L10n.unitSpm.text
                        .foregroundColor(.gray500)
                }

                if !workout.formattedActiveEnergyBurned.isEmpty {
                    HStack {
                        L10n.recordFieldActiveEnergy.text
                            .foregroundColor(.gray500)
                        Spacer()
                        Text(workout.formattedActiveEnergyBurned)
                            .foregroundStyle(.blue700)
                        L10n.unitKcal.text
                            .foregroundColor(.gray500)
                    }
                }

                if !workout.formattedRunningPower.isEmpty {
                    HStack {
                        L10n.recordFieldRunningPower.text
                            .foregroundColor(.gray500)
                        Spacer()
                        Text(workout.formattedRunningPower)
                            .foregroundStyle(.blue700)
                        L10n.unitWatts.text
                            .foregroundColor(.gray500)
                    }
                }

                if !workout.formattedVerticalOscillation.isEmpty {
                    HStack {
                        L10n.recordFieldVerticalOscillation.text
                            .foregroundColor(.gray500)
                        Spacer()
                        Text(workout.formattedVerticalOscillation)
                            .foregroundStyle(.blue700)
                        L10n.unitCm.text
                            .foregroundColor(.gray500)
                    }
                }

                if !workout.formattedGroundContactTime.isEmpty {
                    HStack {
                        L10n.recordFieldGroundContactTime.text
                            .foregroundColor(.gray500)
                        Spacer()
                        Text(workout.formattedGroundContactTime)
                            .foregroundStyle(.blue700)
                        L10n.unitMs.text
                            .foregroundColor(.gray500)
                    }
                }
            }
            
            HStack {
                Spacer()
                Text("common.from_apple_health")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

