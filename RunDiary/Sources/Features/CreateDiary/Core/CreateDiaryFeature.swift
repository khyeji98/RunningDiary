//
//  CreateDiaryFeature.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import ComposableArchitecture
import CoreLocation
import Foundation
import Models
import PersistencesService

@Reducer
struct CreateDiaryFeature {
    @ObservableState
    struct State: Equatable {
        var existingRecord: Diary?
        var healthKitWorkout: HealthKitWorkout

        var selectedPainAreas: Set<PainArea>
        var selectedRunningStyle: RunninStyle?
        var selectedShoe: ShoeModel?
        var selectedDifficultyLevel: DifficultyLevel?
        var memo: String

        var weather: WeatherData? = nil

        var isLoading: Bool = false
        var errorMassage: String?

        var isFormValid: Bool {
            guard selectedShoe != nil else { return false }
            guard selectedRunningStyle != nil else { return false }
            guard selectedDifficultyLevel != nil else { return false }
            return true
        }

        init(
            existingRecord: Diary? = nil,
            healthKitWorkout: HealthKitWorkout
        ) {
            self.existingRecord = existingRecord
            self.healthKitWorkout = healthKitWorkout
            self.selectedPainAreas = Set(existingRecord?.painAreas ?? [])
            self.selectedRunningStyle = existingRecord?.runningStyle
            self.selectedShoe = ShoeStorage.search(id: existingRecord?.shoes ?? "")
            self.selectedDifficultyLevel = existingRecord?.difficultyLevel ?? .medium
            self.memo = existingRecord?.memo ?? ""
        }
    }

    enum Action {
        case onAppear
        case updateSelectedPainAreas(Set<PainArea>)
        case updateSelectedRunningStyle(RunninStyle?)
        case updateSelectedShoe(ShoeModel?)
        case updateSelectedDifficultyLevel(DifficultyLevel?)
        case updateMemo(String)
        case weatherFetched(WeatherData?)
        case saveRecord
        case recordSaved
        case recordSaveFailed(String)
    }

    @Dependency(\.runningRecordClient) var runningRecordClient
    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if let record = state.existingRecord {
                    state.weather = record.weather
                    state.selectedDifficultyLevel = record.difficultyLevel
                }
                return .none

            case .updateSelectedPainAreas(let areas):
                state.selectedPainAreas = areas
                return .none

            case .updateSelectedRunningStyle(let style):
                state.selectedRunningStyle = style
                return .none

            case .updateSelectedShoe(let shoe):
                state.selectedShoe = shoe
                return .none

            case .updateSelectedDifficultyLevel(let level):
                state.selectedDifficultyLevel = level
                return .none

            case .updateMemo(let text):
                state.memo = text
                return .none

            case .weatherFetched(let weather):
                state.weather = weather
                return .none

            case .saveRecord:
                state.isLoading = true
                state.errorMassage = nil

                let id = state.existingRecord?.id ?? UUID()
                let workout = state.healthKitWorkout
                let location = extractLocationFromRoute(workout.routeData)
                let yearMonthDay = YearMonthDay(date: workout.startTime)
                let difficultyLevel = state.selectedDifficultyLevel

                let startInterval = workout.startTime.timeIntervalSince1970
                let endInterval = workout.endTime.timeIntervalSince1970
                let middleInterval = (startInterval + endInterval) / 2.0
                let middleTime = Date(timeIntervalSince1970: middleInterval)

                let painAreas = state.selectedPainAreas
                let runningStyle = state.selectedRunningStyle
                let memo = state.memo
                let shoeId = state.selectedShoe?.id ?? ""
                let isNewRecord = state.existingRecord == nil

                return .run { send in
                    do {
                        let weather: WeatherData?
                        if let location = location {
                            do {
                                weather = try await weatherClient.fetchWeather(middleTime, location)
                                await send(.weatherFetched(weather))
                            } catch {
                                AppLogger.createDiary.warning("날씨 조회 실패: \(error.localizedDescription)")
                                weather = nil
                                await send(.weatherFetched(nil))
                            }
                        } else {
                            weather = nil
                        }

                        let record = Diary(
                            id: id,
                            workout: workout,
                            painAreas: Array(painAreas),
                            runningStyle: runningStyle,
                            memo: memo.isEmpty ? nil : memo,
                            shoes: shoeId,
                            weather: weather,
                            difficultyLevel: difficultyLevel
                        )

                        if isNewRecord {
                            try await runningRecordClient.saveRecord(record)
                        } else {
                            try await runningRecordClient.updateRecord(record)
                        }

                        await send(.recordSaved)
                    } catch {
                        if let runningRecordError = error as? PersistencesError {
                            await send(.recordSaveFailed(runningRecordError.errorDescription ?? runningRecordError.localizedDescription))
                        } else {
                            await send(.recordSaveFailed(error.localizedDescription))
                        }
                    }
                }

            case .recordSaved:
                state.isLoading = false
                return .run { _ in
                    await dismiss()
                }

            case .recordSaveFailed(let errorMassage):
                state.isLoading = false
                state.errorMassage = errorMassage
                return .none
            }
        }
    }

    private func extractLocationFromRoute(_ routeData: Data?) -> CLLocationCoordinate2D? {
        guard let routeData = routeData,
              let coordinates = try? JSONDecoder().decode([Location].self, from: routeData),
              !coordinates.isEmpty else {
            return nil
        }

        let first = coordinates.first!
        let last = coordinates.last!
        let midLatitude = (first.latitude + last.latitude) / 2.0
        let midLongitude = (first.longitude + last.longitude) / 2.0

        return CLLocationCoordinate2D(latitude: midLatitude, longitude: midLongitude)
    }
}
