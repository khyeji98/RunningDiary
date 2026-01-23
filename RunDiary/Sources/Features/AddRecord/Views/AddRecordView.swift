//
//  AddRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import ComposableArchitecture
import CommonFoundation
import SwiftUI
import Models
import PersistencesService

struct AddRecordView: View {
    @Bindable var store: StoreOf<AddRecordFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // HealthKit 데이터 섹션
                HealthKitSectionView(workout: store.healthKitWorkout)

                // 신발 섹션
                ShoesSectionView(
                    selectedShoe: Binding(
                        get: { store.selectedShoe },
                        set: { store.send(.updateSelectedShoe($0)) }
                    )
                )

                // 주법 섹션
                RunningStyleSectionView(
                    selectedStyle: Binding(
                        get: { store.selectedRunningStyle },
                        set: { store.send(.updateSelectedRunningStyle($0)) }
                    ),
                    styleOptions: RunninStyle.allCases
                )

                // 통증 부위 섹션
                PainAreasSectionView(
                    selectedPainAreas: Binding(
                        get: { store.selectedPainAreas },
                        set: { store.send(.updateSelectedPainAreas($0)) }
                    ),
                    painAreaOptions: PainArea.allCases
                )

                // 난이도 섹션
                DifficultyLevelSectionView(
                    selectedLevel: Binding(
                        get: { store.selectedDifficultyLevel },
                        set: { store.send(.updateSelectedDifficultyLevel($0)) }
                    )
                )

                // 메모 섹션
                MemoSectionView(
                    memo: Binding(
                        get: { store.memo },
                        set: { store.send(.updateMemo($0)) }
                    )
                )
            }
            .padding()
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

            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.uiSave.value) {
                    hideKeyboard()
                    store.send(.saveRecord)
                }
                .foregroundStyle(store.isLoading || !store.isFormValid ? .blue300.opacity(0.3) : .blue300)
                .disabled(store.isLoading || !store.isFormValid)
            }
        }
        .task {
            store.send(.onAppear)
        }
        .loadingIndicatorIfNeeded(store.isLoading)
    }
}

// MARK: - Preview

#Preview(traits: .sampleData) {
    NavigationStack {
        AddRecordView(
            store: Store(
                initialState: AddRecordFeature.State(
                    healthKitWorkout: HealthKitWorkout(
                        distance: 5.2,
                        duration: 3665,  // 1시간 1분 5초
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
                AddRecordFeature()
            }
        )
    }
}
