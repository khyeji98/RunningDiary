//
//  HealthKitWorkoutCard.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import CommonFoundation
import Models
import SwiftUI

struct HealthKitWorkoutCard: View {
    let workout: HealthKitWorkout
    let onCreate: () -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    init(
        record: HealthKitWorkout,
        onCreate: @escaping () -> Void
    ) {
        self.workout = record
        self.onCreate = onCreate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                // Start time (top-right)
                HStack {
                    Spacer()
                    Text(workout.startTime.formattedString(formatter: .hourMinutes))
                        .font(.caption)
                        .foregroundColor(.gray500)
                }

                // Main distance title (bold)
                Text("\(workout.distance.to2f) km")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            // 2-column grid for workout stats
            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                RecordVerticalRow(
                    title: L10n.recordFieldDuration.value,
                    value: workout.formattedDuration
                )
                RecordVerticalRow(
                    title: L10n.recordFieldPace.value,
                    value: workout.averagePace
                )
                RecordVerticalRow(
                    title: L10n.recordFieldHeartRate.value,
                    value: "\(workout.averageHeartRate) bpm"
                )
                RecordVerticalRow(
                    title: L10n.recordFieldCadence.value,
                    value: "\(workout.averageCadence) spm"
                )
            }

            // Blur placeholder to hint at more data
            BlurredPlaceholderView(gridColumns: gridColumns)

            // Write Diary button at the bottom
            Button(action: onCreate) {
                ZStack {
                    Capsule()
                        .fill(.yellow100)

                    L10n.recordWriteDiaryButton.text
                        .fontWeight(.semibold)
                        .foregroundColor(.blue700)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .liquidGlass()
    }
}

// MARK: - Blur Placeholder View
private struct BlurredPlaceholderView: View {
    let gridColumns: [GridItem]

    var body: some View {
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
            PlaceholderItem()
            PlaceholderItem()
        }
        .blur(radius: 4)
        .opacity(0.6)
    }
}

// MARK: - Placeholder Item
private struct PlaceholderItem: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("More Data")
                .font(.caption)
                .foregroundColor(.gray500)
            Text("--")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        HealthKitWorkoutCard(
            record: HealthKitWorkout(
                distance: 5.23,
                duration: 1935,
                averagePace: "6'10\"",
                averageHeartRate: 156,
                averageCadence: 178,
                activeEnergyBurned: 320.5,
                runningVerticalOscillation: 8.2,
                runningGroundContactTime: 245,
                walkingStepLength: 1.1,
                restingHeartRate: 58,
                runningPower: 280,
                runningStrideLength: 1.2,
                heartRateRecoveryOneMinute: 22,
                routeData: nil,
                startDate: Date(),
                endDate: Date().addingTimeInterval(1935)
            ),
            onCreate: {}
        )
        .padding()
        Spacer()
    }
    .background(Color.gray50)
}
