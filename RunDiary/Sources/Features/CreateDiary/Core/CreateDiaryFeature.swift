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
    enum Step: Int, CaseIterable, Equatable {
        case fitness
        case weather
        case shoes
        case runningStyle
        case painAreas
        case difficulty
        case memo

        var isFirst: Bool { self == Self.allCases.first }
        var isLast: Bool { self == Self.allCases.last }

        var next: Step? {
            guard let index = Self.allCases.firstIndex(of: self) else { return nil }
            let nextIndex = Self.allCases.index(after: index)
            return nextIndex < Self.allCases.endIndex ? Self.allCases[nextIndex] : nil
        }

        var previous: Step? {
            guard let index = Self.allCases.firstIndex(of: self) else { return nil }
            let previousIndex = Self.allCases.index(before: index)
            return previousIndex >= Self.allCases.startIndex ? Self.allCases[previousIndex] : nil
        }
    }

    @ObservableState
    struct State: Equatable {
        var existingRecord: Diary?
        var healthKitWorkout: HealthKitWorkout

        var currentStep: Step = .fitness

        var selectedPainAreas: Set<PainArea>
        var selectedRunningStyle: RunninStyle?
        var selectedShoe: Shoe?
        var selectedDifficultyLevel: DifficultyLevel?
        var memo: String

        var shoes: [Shoe] = []
        var isShoesLoading: Bool = false

        var weather: WeatherData?

        var skyCondition: SkyCondition?
        var windLevel: WindLevel?
        var feelsLike: FeelsLikeLevel?
        var humidityLevel: HumidityLevel?

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
            self.selectedShoe = nil
            self.selectedDifficultyLevel = existingRecord?.difficultyLevel ?? .medium
            self.memo = existingRecord?.memo ?? ""

            if let weather = existingRecord?.weather {
                self.weather = weather
                self.skyCondition = weather.skyCondition
                self.windLevel = weather.windLevel
                self.feelsLike = weather.feelsLike
                self.humidityLevel = weather.humidityLevel
            }
        }
    }

    enum Action {
        case onAppear
        case nextStepTapped
        case previousStepTapped
        case updateSelectedPainAreas(Set<PainArea>)
        case updateSelectedRunningStyle(RunninStyle?)
        case updateSelectedShoe(Shoe?)
        case shoesLoaded([Shoe])
        case shoesLoadFailed
        case updateSelectedDifficultyLevel(DifficultyLevel?)
        case updateMemo(String)
        case updateSkyCondition(SkyCondition)
        case updateWindLevel(WindLevel)
        case updateFeelsLike(FeelsLikeLevel)
        case updateHumidityLevel(HumidityLevel)
        case weatherFetched(WeatherData?)
        case saveRecord
        case recordSaved
        case recordSaveFailed(String)
    }

    @Dependency(\.runningRecordClient) var runningRecordClient
    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.shoeClient) var shoeClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let shoesEffect = loadShoesEffect(state: &state)

                if state.existingRecord != nil {
                    return shoesEffect
                }

                let workout = state.healthKitWorkout
                let location = extractLocationFromRoute(workout.routeData)

                guard let location else { return shoesEffect }

                let middleTime = workoutMiddleTime(workout)

                let weatherEffect: Effect<Action> = .run { send in
                    do {
                        let weather = try await weatherClient.fetchWeather(middleTime, location)
                        await send(.weatherFetched(weather))
                    } catch {
                        AppLogger.createDiary.warning("날씨 조회 실패: \(error.localizedDescription)")
                        await send(.weatherFetched(nil))
                    }
                }

                return .merge(shoesEffect, weatherEffect)

            case .nextStepTapped:
                if let next = state.currentStep.next {
                    state.currentStep = next
                }
                return .none

            case .previousStepTapped:
                if let previous = state.currentStep.previous {
                    state.currentStep = previous
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

            case .shoesLoaded(let shoes):
                state.shoes = shoes
                state.isShoesLoading = false
                if state.selectedShoe == nil, let id = state.existingRecord?.shoes {
                    state.selectedShoe = shoes.first { $0.id == id }
                }
                return .none

            case .shoesLoadFailed:
                state.isShoesLoading = false
                return .none

            case .updateSelectedDifficultyLevel(let level):
                state.selectedDifficultyLevel = level
                return .none

            case .updateMemo(let text):
                state.memo = text
                return .none

            case .updateSkyCondition(let value):
                state.skyCondition = value
                return .none

            case .updateWindLevel(let value):
                state.windLevel = value
                return .none

            case .updateFeelsLike(let value):
                state.feelsLike = value
                return .none

            case .updateHumidityLevel(let value):
                state.humidityLevel = value
                return .none

            case .weatherFetched(let weather):
                state.weather = weather
                if let weather {
                    state.skyCondition = weather.skyCondition
                    state.windLevel = weather.windLevel
                    state.feelsLike = weather.feelsLike
                    state.humidityLevel = weather.humidityLevel
                }
                return .none

            case .saveRecord:
                state.isLoading = true
                state.errorMassage = nil

                let id = state.existingRecord?.id ?? UUID()
                let workout = state.healthKitWorkout
                let painAreas = state.selectedPainAreas
                let runningStyle = state.selectedRunningStyle
                let memo = state.memo
                let shoeId = state.selectedShoe?.id ?? ""
                let difficultyLevel = state.selectedDifficultyLevel
                let weather = mergeWeather(
                    base: state.weather,
                    sky: state.skyCondition,
                    wind: state.windLevel,
                    feels: state.feelsLike,
                    humid: state.humidityLevel
                )
                let isNewRecord = state.existingRecord == nil

                return .run { send in
                    do {
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

    private func workoutMiddleTime(_ workout: HealthKitWorkout) -> Date {
        let startInterval = workout.startTime.timeIntervalSince1970
        let endInterval = workout.endTime.timeIntervalSince1970
        let middleInterval = (startInterval + endInterval) / 2.0
        return Date(timeIntervalSince1970: middleInterval)
    }

    private func loadShoesEffect(state: inout State) -> Effect<Action> {
        if !state.shoes.isEmpty { return .none }

        state.isShoesLoading = true

        return .run { [shoeClient] send in
            if await ShoeCache.shared.isLoaded {
                let shoes = await ShoeCache.shared.allShoes()
                await send(.shoesLoaded(shoes))
                return
            }

            do {
                let shoes = try await shoeClient.fetchAllShoes()
                await ShoeCache.shared.store(shoes)
                await send(.shoesLoaded(shoes))
            } catch {
                AppLogger.createDiary.warning("신발 조회 실패: \(error.localizedDescription)")
                await send(.shoesLoadFailed)
            }
        }
    }

    private func mergeWeather(
        base: WeatherData?,
        sky: SkyCondition?,
        wind: WindLevel?,
        feels: FeelsLikeLevel?,
        humid: HumidityLevel?
    ) -> WeatherData? {
        guard let base else { return nil }

        return WeatherData(
            temperature: base.temperature,
            humidity: base.humidity,
            windSpeed: base.windSpeed,
            skyCondition: sky ?? base.skyCondition,
            windLevel: wind ?? base.windLevel,
            feelsLike: feels ?? base.feelsLike,
            humidityLevel: humid ?? base.humidityLevel
        )
    }
}
