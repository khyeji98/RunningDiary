//
//  CreateDiaryFeatureTests.swift
//  RunDiaryTests
//

import ComposableArchitecture
import Foundation
import Models
import Testing

@testable import RunDiary

@MainActor
@Suite("CreateDiaryFeature step navigation")
struct CreateDiaryFeatureStepTests {

    @Test("nextStepTapped advances to the next step")
    func nextStepTapped_advancesStep() async {
        let store = makeStore()

        await store.send(.nextStepTapped) {
            $0.currentStep = .weather
        }
        await store.send(.nextStepTapped) {
            $0.currentStep = .shoes
        }
    }

    @Test("nextStepTapped at the last step keeps the step")
    func nextStepTapped_atLastStep_noChange() async {
        let store = makeStore { state in
            state.currentStep = .memo
        }

        await store.send(.nextStepTapped)
    }

    @Test("previousStepTapped at the first step keeps the step")
    func previousStepTapped_atFirstStep_noChange() async {
        let store = makeStore()

        await store.send(.previousStepTapped)
    }

    @Test("previousStepTapped goes back one step")
    func previousStepTapped_goesBack() async {
        let store = makeStore { state in
            state.currentStep = .weather
        }

        await store.send(.previousStepTapped) {
            $0.currentStep = .fitness
        }
    }
}

@MainActor
@Suite("CreateDiaryFeature weather step edits")
struct CreateDiaryFeatureWeatherTests {

    @Test("updateSkyCondition stores the value")
    func updateSkyCondition() async {
        let store = makeStore()
        await store.send(.updateSkyCondition(.cloudy)) {
            $0.skyCondition = .cloudy
        }
    }

    @Test("updateWindLevel stores the value")
    func updateWindLevel() async {
        let store = makeStore()
        await store.send(.updateWindLevel(.strong)) {
            $0.windLevel = .strong
        }
    }

    @Test("updateFeelsLike stores the value")
    func updateFeelsLike() async {
        let store = makeStore()
        await store.send(.updateFeelsLike(.cold)) {
            $0.feelsLike = .cold
        }
    }

    @Test("updateHumidityLevel stores the value")
    func updateHumidityLevel() async {
        let store = makeStore()
        await store.send(.updateHumidityLevel(.humid)) {
            $0.humidityLevel = .humid
        }
    }

    @Test("weatherFetched copies classification fields into state")
    func weatherFetched_copiesClassification() async {
        let store = makeStore()

        let fetched = WeatherData(
            temperature: 25, humidity: 80, windSpeed: 6,
            cloudCover: 0.8, apparentTemperature: 28
        )

        await store.send(.weatherFetched(fetched)) {
            $0.weather = fetched
            $0.skyCondition = .cloudy
            $0.windLevel = .strong
            $0.feelsLike = .hot
            $0.humidityLevel = .humid
        }
    }
}

@MainActor
@Suite("CreateDiaryFeature save")
struct CreateDiaryFeatureSaveTests {

    @Test("saveRecord merges user-edited classification into weather and persists")
    func saveRecord_mergesWeather() async {
        let workout = makeWorkout()

        let baseWeather = WeatherData(
            temperature: 18, humidity: 50, windSpeed: 1,
            skyCondition: .sunny, windLevel: .weak,
            feelsLike: .neutral, humidityLevel: .dry
        )

        var capturedRecord: Diary?

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: workout)
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { record in
                capturedRecord = record
            }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.weatherClient.fetchWeather = { _, _ in baseWeather }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        let shoe = ShoeStorage.shoes.first!
        await store.send(.updateSelectedShoe(shoe))
        await store.send(.updateSelectedRunningStyle(.midfoot))
        await store.send(.weatherFetched(baseWeather))
        await store.send(.updateSkyCondition(.cloudy))
        await store.send(.updateWindLevel(.strong))
        await store.send(.updateFeelsLike(.hot))
        await store.send(.updateHumidityLevel(.humid))

        await store.send(.saveRecord)
        await store.skipReceivedActions()

        let saved = try? #require(capturedRecord)
        #expect(saved?.weather?.temperature == 18)
        #expect(saved?.weather?.humidity == 50)
        #expect(saved?.weather?.windSpeed == 1)
        #expect(saved?.weather?.skyCondition == .cloudy)
        #expect(saved?.weather?.windLevel == .strong)
        #expect(saved?.weather?.feelsLike == .hot)
        #expect(saved?.weather?.humidityLevel == .humid)
    }
}

@MainActor
@Suite("CreateDiaryFeature initial state")
struct CreateDiaryFeatureInitTests {

    @Test("init with existing weather populates classification fields")
    func init_existingWeather_populatesClassification() {
        let workout = makeWorkout()
        let weather = WeatherData(
            temperature: 5, humidity: 80, windSpeed: 6,
            skyCondition: .cloudy, windLevel: .strong,
            feelsLike: .cold, humidityLevel: .humid
        )
        let existing = Diary(
            workout: workout,
            runningStyle: .midfoot,
            weather: weather
        )

        let state = CreateDiaryFeature.State(
            existingRecord: existing,
            healthKitWorkout: workout
        )

        #expect(state.skyCondition == .cloudy)
        #expect(state.windLevel == .strong)
        #expect(state.feelsLike == .cold)
        #expect(state.humidityLevel == .humid)
    }

    @Test("init without existing record leaves classification nil")
    func init_noExistingRecord_classificationIsNil() {
        let state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())

        #expect(state.skyCondition == nil)
        #expect(state.windLevel == nil)
        #expect(state.feelsLike == nil)
        #expect(state.humidityLevel == nil)
        #expect(state.currentStep == .fitness)
    }
}

// MARK: - Helpers

@MainActor
private func makeStore(
    mutate: ((inout CreateDiaryFeature.State) -> Void)? = nil
) -> TestStore<CreateDiaryFeature.State, CreateDiaryFeature.Action> {
    var state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
    mutate?(&state)
    return TestStore(initialState: state) {
        CreateDiaryFeature()
    } withDependencies: {
        $0.runningRecordClient.saveRecord = { _ in }
        $0.runningRecordClient.updateRecord = { _ in }
        $0.runningRecordClient.fetchData = { _, _ in [:] }
        $0.weatherClient.fetchWeather = { _, _ in
            WeatherData(temperature: 20, humidity: 50, windSpeed: 1)
        }
    }
}

private func makeWorkout() -> HealthKitWorkout {
    HealthKitWorkout(
        distance: 5.0,
        duration: 1800,
        averagePace: "6'00\"",
        averageHeartRate: 150,
        averageCadence: 170,
        activeEnergyBurned: 350,
        runningVerticalOscillation: 8,
        runningGroundContactTime: 240,
        walkingStepLength: 1,
        restingHeartRate: 60,
        runningPower: 300,
        runningStrideLength: 1,
        heartRateRecoveryOneMinute: 20,
        routeData: nil,
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 1800)
    )
}
