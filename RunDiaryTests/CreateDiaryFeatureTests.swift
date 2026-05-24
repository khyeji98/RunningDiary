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

        let shoe = makeShoe()

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
            $0.shoeClient.fetchAllShoes = { [shoe] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

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

// MARK: - Step Properties

@Suite("CreateDiaryFeature.Step properties")
struct CreateDiaryFeatureStepPropertyTests {

    @Test("fitness.isFirst == true, 나머지는 false")
    func isFirst_onlyFitnessIsFirst() {
        #expect(CreateDiaryFeature.Step.fitness.isFirst == true)
        for step in CreateDiaryFeature.Step.allCases.dropFirst() {
            #expect(step.isFirst == false)
        }
    }

    @Test("memo.isLast == true, 나머지는 false")
    func isLast_onlyMemoIsLast() {
        #expect(CreateDiaryFeature.Step.memo.isLast == true)
        for step in CreateDiaryFeature.Step.allCases.dropLast() {
            #expect(step.isLast == false)
        }
    }

    @Test("fitness.previous == nil")
    func previous_fitnessHasNoPrevious() {
        #expect(CreateDiaryFeature.Step.fitness.previous == nil)
    }

    @Test("memo.next == nil")
    func next_memoHasNoNext() {
        #expect(CreateDiaryFeature.Step.memo.next == nil)
    }
}

// MARK: - isFormValid

@MainActor
@Suite("CreateDiaryFeature.isFormValid")
struct CreateDiaryFeatureFormValidTests {

    @Test("shoe·style·difficulty 모두 nil → false")
    func allNil_isInvalid() {
        let state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        #expect(state.isFormValid == false)
    }

    @Test("shoe만 설정, style·difficulty nil → false")
    func onlyShoe_isInvalid() {
        var state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        state = mutated(state) { $0.selectedShoe = makeShoe() }
        #expect(state.isFormValid == false)
    }

    @Test("shoe·style 설정, difficulty 명시적 nil → false")
    func shoeAndStyle_isInvalid() {
        var state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        state = mutated(state) {
            $0.selectedShoe = makeShoe()
            $0.selectedRunningStyle = .midfoot
            $0.selectedDifficultyLevel = nil  // 기본값 .medium을 명시적으로 nil로
        }
        #expect(state.isFormValid == false)
    }

    @Test("shoe·style·difficulty 모두 설정 → true")
    func allSet_isValid() {
        var state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        state = mutated(state) {
            $0.selectedShoe = makeShoe()
            $0.selectedRunningStyle = .midfoot
            $0.selectedDifficultyLevel = .medium
        }
        #expect(state.isFormValid == true)
    }

    private func mutated(
        _ state: CreateDiaryFeature.State,
        _ mutate: (inout CreateDiaryFeature.State) -> Void
    ) -> CreateDiaryFeature.State {
        var s = state
        mutate(&s)
        return s
    }
}

// MARK: - onAppear

@MainActor
@Suite("CreateDiaryFeature.onAppear")
struct CreateDiaryFeatureOnAppearTests {

    @Test("기존 기록 수정 시 날씨 조회 생략, 신발만 로드")
    func onAppear_existingRecord_loadsOnlyShoes() async {
        let shoe = makeShoe(id: "s1")
        let existing = Diary(workout: makeWorkout(), runningStyle: .midfoot, shoes: "s1")
        var weatherFetchCalled = false

        let store = TestStore(
            initialState: CreateDiaryFeature.State(
                existingRecord: existing,
                healthKitWorkout: makeWorkout()
            )
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [shoe] }
            $0.weatherClient.fetchWeather = { _, _ in
                weatherFetchCalled = true
                return WeatherData(temperature: 20, humidity: 50, windSpeed: 1)
            }
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }

        await store.send(.onAppear) {
            $0.isShoesLoading = true
        }
        await store.receive(\.shoesLoaded) {
            $0.isShoesLoading = false
            $0.shoes = [shoe]
            $0.selectedShoe = shoe
        }

        #expect(weatherFetchCalled == false)
    }

    @Test("새 기록 + routeData 없음 → 신발만 로드")
    func onAppear_newRecordNoRoute_loadsOnlyShoes() async {
        let shoe = makeShoe(id: "s1")
        var weatherFetchCalled = false

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [shoe] }
            $0.weatherClient.fetchWeather = { _, _ in
                weatherFetchCalled = true
                return WeatherData(temperature: 20, humidity: 50, windSpeed: 1)
            }
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }

        await store.send(.onAppear) {
            $0.isShoesLoading = true
        }
        await store.receive(\.shoesLoaded) {
            $0.isShoesLoading = false
            $0.shoes = [shoe]
        }

        #expect(weatherFetchCalled == false)
    }

    @Test("새 기록 + routeData 있음 → 날씨 조회 발생")
    func onAppear_newRecordWithRoute_fetchesWeather() async {
        await ShoeCache.shared.reset()
        var weatherFetchCalled = false

        let routeData = try! JSONEncoder().encode([
            Location(latitude: 37.5, longitude: 127.0),
            Location(latitude: 37.6, longitude: 127.1)
        ])
        let workout = makeWorkoutWithRoute(routeData: routeData)

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: workout)
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [] }
            $0.weatherClient.fetchWeather = { _, _ in
                weatherFetchCalled = true
                return WeatherData(temperature: 20, humidity: 50, windSpeed: 1)
            }
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }

        store.exhaustivity = .off
        await store.send(.onAppear)
        await store.skipReceivedActions()

        #expect(weatherFetchCalled == true)
    }
}

// MARK: - shoesLoaded matching

@MainActor
@Suite("CreateDiaryFeature.shoesLoaded")
struct CreateDiaryFeatureShoesLoadedTests {

    @Test("기존 기록 shoes ID 일치하는 신발 자동 선택")
    func shoesLoaded_matchesExistingRecordShoe() async {
        let shoe = makeShoe(id: "existing-shoe")
        let existing = Diary(workout: makeWorkout(), runningStyle: .midfoot, shoes: "existing-shoe")
        let store = TestStore(
            initialState: CreateDiaryFeature.State(
                existingRecord: existing,
                healthKitWorkout: makeWorkout()
            )
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
        }

        await store.send(.shoesLoaded([shoe])) {
            $0.isShoesLoading = false
            $0.shoes = [shoe]
            $0.selectedShoe = shoe
        }
    }

    @Test("기존 기록 shoes ID 없으면 selectedShoe nil 유지")
    func shoesLoaded_noMatchingShoe_keepsSelectedShoeNil() async {
        let shoe = makeShoe(id: "other-shoe")
        let existing = Diary(workout: makeWorkout(), runningStyle: .midfoot, shoes: "not-in-list")
        let store = TestStore(
            initialState: CreateDiaryFeature.State(
                existingRecord: existing,
                healthKitWorkout: makeWorkout()
            )
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
        }

        await store.send(.shoesLoaded([shoe])) {
            $0.isShoesLoading = false
            $0.shoes = [shoe]
        }
    }

    @Test("shoesLoadFailed → isShoesLoading = false")
    func shoesLoadFailed_clearsShoesLoading() async {
        let store = makeStore { $0.isShoesLoading = true }
        await store.send(.shoesLoadFailed) {
            $0.isShoesLoading = false
        }
    }
}

// MARK: - saveRecord new vs update

@MainActor
@Suite("CreateDiaryFeature.saveRecord 신규 vs 수정")
struct CreateDiaryFeatureSaveRouteTests {

    @Test("existingRecord nil → saveRecord 호출, updateRecord 미호출")
    func saveRecord_newDiary_callsSaveNotUpdate() async {
        var saveCallCount = 0
        var updateCallCount = 0
        let shoe = makeShoe()

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in saveCallCount += 1 }
            $0.runningRecordClient.updateRecord = { _ in updateCallCount += 1 }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.updateSelectedShoe(shoe))
        await store.send(.updateSelectedRunningStyle(.midfoot))
        await store.send(.saveRecord)
        await store.skipReceivedActions()

        #expect(saveCallCount == 1)
        #expect(updateCallCount == 0)
    }

    @Test("existingRecord 있음 → updateRecord 호출, saveRecord 미호출")
    func saveRecord_existingDiary_callsUpdateNotSave() async {
        var saveCallCount = 0
        var updateCallCount = 0
        let shoe = makeShoe()
        let existing = Diary(workout: makeWorkout(), runningStyle: .midfoot)

        let store = TestStore(
            initialState: CreateDiaryFeature.State(
                existingRecord: existing,
                healthKitWorkout: makeWorkout()
            )
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in saveCallCount += 1 }
            $0.runningRecordClient.updateRecord = { _ in updateCallCount += 1 }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.updateSelectedShoe(shoe))
        await store.send(.saveRecord)
        await store.skipReceivedActions()

        #expect(saveCallCount == 0)
        #expect(updateCallCount == 1)
    }

    @Test("저장 실패 시 isLoading=false, errorMessage 설정")
    func saveRecord_failure_setsErrorMessage() async {
        struct SaveError: Error, LocalizedError {
            var errorDescription: String? { "저장 실패" }
        }
        let shoe = makeShoe()

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in throw SaveError() }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.updateSelectedShoe(shoe))
        await store.send(.updateSelectedRunningStyle(.midfoot))
        await store.send(.saveRecord) { $0.isLoading = true }
        await store.receive(\.recordSaveFailed) {
            $0.isLoading = false
            $0.errorMassage = "저장 실패"
        }
    }

    @Test("빈 memo는 Diary.memo = nil로 저장")
    func saveRecord_emptyMemo_savesNilMemo() async {
        var capturedRecord: Diary?
        let shoe = makeShoe()

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { capturedRecord = $0 }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.updateSelectedShoe(shoe))
        await store.send(.updateSelectedRunningStyle(.midfoot))
        await store.send(.updateMemo(""))
        await store.send(.saveRecord)
        await store.skipReceivedActions()

        #expect(capturedRecord?.memo == nil)
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
        $0.shoeClient.fetchAllShoes = { [] }
    }
}

private func makeShoe(
    id: String = "test-shoe-id",
    brandName: String = "TestBrand",
    name: String = "Test Shoe"
) -> Shoe {
    Shoe(
        id: id,
        brandName: brandName,
        name: name,
        nameKo: name,
        category: [:],
        subcategory: [:],
        tags: [],
        imageUrl: nil,
        reviewSummary: nil,
        pros: [],
        cons: [],
        description: nil
    )
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

private func makeWorkoutWithRoute(routeData: Data) -> HealthKitWorkout {
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
        routeData: routeData,
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 1800)
    )
}
