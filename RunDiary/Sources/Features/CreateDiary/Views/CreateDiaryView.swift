//
//  CreateDiaryView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import ComposableArchitecture
import Models
import PersistencesService
import SwiftUI

struct CreateDiaryView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            StepContent(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            StepNavigationBar(store: store)
        }
        .background(Color.gray50)
        .scrollDismissesKeyboard(.interactively)
        .hideKeyboardOnTapOutside()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.uiDone.value) {
                    hideKeyboard()
                }
            }
        }
        .navigationTitle(store.existingRecord == nil ? Text("record.write_title") : Text(L10n.recordEdit.value))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.uiCancel.value) {
                    dismiss()
                }
                .foregroundStyle(.gray500)
            }
        }
        .task {
            store.send(.onAppear)
        }
        .loadingIndicatorIfNeeded(store.isLoading)
    }
}

private struct StepContent: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>

    var body: some View {
        Group {
            switch store.currentStep {
            case .fitness:
                Step1FitnessView(workout: store.healthKitWorkout)

            case .weather:
                Step2WeatherView(store: store)

            case .shoes:
                Step3ShoesView(store: store)

            case .runningStyle:
                Step4RunningStyleView(store: store)

            case .painAreas:
                Step5PainAreasView(store: store)

            case .difficulty:
                Step6DifficultyView(store: store)

            case .memo:
                Step7MemoView(store: store)
            }
        }
        .id(store.currentStep)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: store.currentStep)
    }
}

// MARK: - Preview

#Preview(traits: .sampleData) {
    NavigationStack {
        CreateDiaryView(
            store: Store(
                initialState: CreateDiaryFeature.State(
                    healthKitWorkout: HealthKitWorkout(
                        distance: 5.2,
                        duration: 3665,
                        averagePace: "5'30\"",
                        averageHeartRate: 155,
                        averageCadence: 180,
                        activeEnergyBurned: 450.0,
                        runningVerticalOscillation: 8.2,
                        runningGroundContactTime: 240.0,
                        walkingStepLength: 1.1,
                        restingHeartRate: 60.0,
                        runningPower: 300.0,
                        runningStrideLength: 1.1,
                        heartRateRecoveryOneMinute: 20.0,
                        routeData: nil,
                        startDate: .now,
                        endDate: .now
                    )
                )
            ) {
                CreateDiaryFeature()
            }
        )
    }
}
