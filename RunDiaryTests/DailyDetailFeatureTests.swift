//
//  DailyDetailFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 1/19/26.
//

import CommonFoundation
import ComposableArchitecture
import Foundation
import Models
import Testing

@testable import RunDiary

@MainActor
@Suite("DailyDetailFeature")
struct DailyDetailFeatureTests {

    // MARK: - Initialization Tests

    @Test("onAppear: dates가 비어있으면 주 날짜 초기화 및 fetchWeekRecords 트리거")
    func onAppear_emptyDates_initializesWeekDatesAndFetch() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedWeekDates = makeWeekDates(containing: testDate)
        let expectedDiaries = [makeDiary(yearMonthDay: testDate)]
        let expectedWorkouts = [makeHealthKitWorkout(yearMonthDay: testDate)]

        let initialState = DailyDetailFeature.State(selectedDate: testDate)

        let sut = makeTestStore(
            initialState: initialState,
            diaries: expectedDiaries,
            workouts: expectedWorkouts
        )

        // fetchWeekRecords → weekRecordsFetched 연쇄 이후의 in-flight effect는 skip
        sut.exhaustivity = .off

        // When
        await sut.send(.onAppear) {
            // Then
            $0.dates = expectedWeekDates
        }

        // Then - 최종 상태 확인
        await sut.skipReceivedActions()
        #expect(sut.state.diaries == Dictionary(grouping: expectedDiaries, by: \.workout.yearMonthDay))
        #expect(sut.state.workouts == Dictionary(grouping: expectedWorkouts, by: \.yearMonthDay))
        #expect(sut.state.isLoading == false)
    }

    @Test("onAppear: dates가 이미 있으면 dates 유지 및 fetchWeekRecords 트리거")
    func onAppear_existingDates_preservesDates() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let existingDates = makeWeekDates(containing: testDate)

        let initialState = DailyDetailFeature.State(selectedDate: testDate, dates: existingDates)

        let sut = makeTestStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        sut.exhaustivity = .off

        // When - dates는 유지되고 fetchWeekRecords만 트리거
        await sut.send(.onAppear)

        // Then - 최종 상태 확인 (dates는 변경되지 않음)
        await sut.skipReceivedActions()
        #expect(sut.state.dates == existingDates)
        #expect(sut.state.isLoading == false)
    }

    // MARK: - Date Selection Tests

    @Test("dateSelected: selectedDate만 변경")
    func dateSelected_changesOnlySelectedDate() async {
        // Given
        let initialDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: initialDate)
        let newSelectedDate = weekDates.first { $0 != initialDate } ?? weekDates[0]

        var initialState = DailyDetailFeature.State(selectedDate: initialDate)
        initialState.dates = weekDates

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.dateSelected(newSelectedDate)) {
            $0.selectedDate = newSelectedDate
        }
    }

    // MARK: - Week Navigation Tests

    @Test("weekChanged: 다음 주 이동 및 fetchWeekRecords 트리거")
    func weekChanged_forward_movesToNextWeekAndFetches() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let currentWeekDates = makeWeekDates(containing: testDate)
        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!.toDate())
        let expectedNextWeekDates = DateHelper.getWeekDates(for: nextWeekStart).map { YearMonthDay(date: $0) }

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = currentWeekDates

        let sut = makeTestStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.weekChanged(offset: 1)) {
            // Then
            $0.dates = expectedNextWeekDates

            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: testDate.toDate())
            if let newSelectedDate = expectedNextWeekDates.first(where: {
                calendar.component(.weekday, from: $0.toDate()) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = expectedNextWeekDates.first!
            }
        }

        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }

    @Test("weekChanged: 이전 주 이동")
    func weekChanged_backward_movesToPreviousWeek() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let currentWeekDates = makeWeekDates(containing: testDate)
        let prevWeekStart = DateHelper.addWeeks(-1, to: currentWeekDates.first!.toDate())
        let expectedPrevWeekDates = DateHelper.getWeekDates(for: prevWeekStart).map { YearMonthDay(date: $0) }

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = currentWeekDates

        let sut = makeTestStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.weekChanged(offset: -1)) {
            // Then
            $0.dates = expectedPrevWeekDates

            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: testDate.toDate())
            if let newSelectedDate = expectedPrevWeekDates.first(where: {
                calendar.component(.weekday, from: $0.toDate()) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = expectedPrevWeekDates.first!
            }
        }

        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }

    // MARK: - Data Fetching Tests

    @Test("fetchWeekRecords: dates가 비어있으면 emptyWeekDates 에러")
    func fetchWeekRecords_emptyDates_returnsEmptyWeekDatesError() async {
        // Given
        let sut = TestStore(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        }

        // When
        await sut.send(.fetchWeekRecords)

        // Then
        await sut.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .emptyWeekDates
        }
    }

    @Test("fetchWeekRecords: 성공 시 diaries와 workouts 설정")
    func fetchWeekRecords_success_setsDiariesAndWorkouts() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)
        let expectedDiaries = [makeDiary(yearMonthDay: testDate, distance: 5.5)]
        let expectedWorkouts = [makeHealthKitWorkout(yearMonthDay: testDate, distance: 6.0)]

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = weekDates

        let sut = makeTestStore(
            initialState: initialState,
            diaries: expectedDiaries,
            workouts: expectedWorkouts
        )

        // When
        await sut.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        // Then
        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.diaries = Dictionary(grouping: expectedDiaries, by: \.workout.yearMonthDay)
            $0.workouts = Dictionary(grouping: expectedWorkouts, by: \.yearMonthDay)
        }
    }

    @Test("fetchWeekRecords: 실패 시 에러 상태 설정")
    func fetchWeekRecords_failure_setsErrorState() async {
        // Given
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Network error" }
        }

        let testDate = makeTodayYearMonthDay()
        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = makeWeekDates(containing: testDate)

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in
                throw TestError()
            }
            $0.persistencesClient.fetchRecords = { _, _ in [] }
        }

        // When
        await sut.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        // Then
        await sut.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .fetchFailed(underlyingError: "Network error")
        }
    }

    // MARK: - Calendar Integration Tests

    @Test("calendarButtonTapped: Calendar 시트 표시")
    func calendarButtonTapped_showsCalendarSheet() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.calendarButtonTapped) {
            $0.calendar = CalendarFeature.State(selectedDate: testDate)
        }
    }

    @Test("calendar dismiss: 시트 닫힘")
    func calendarDismiss_closesSheet() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.calendar = CalendarFeature.State(selectedDate: testDate)

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.calendar(.dismiss)) {
            $0.calendar = nil
        }
    }

    @Test("calendar navigateToDiary: 날짜 이동 및 fetchWeekRecords 트리거")
    func calendarNavigateToDiary_navigatesToDateAndFetches() async {
        // Given
        let currentDate = makeYearMonthDay(year: 2025, month: 11, day: 27)
        let selectedDate = makeYearMonthDay(year: 2025, month: 12, day: 10)
        let expectedWeekDates = makeWeekDates(containing: selectedDate)

        var initialState = DailyDetailFeature.State(selectedDate: currentDate)
        initialState.dates = makeWeekDates(containing: currentDate)
        initialState.calendar = CalendarFeature.State(selectedDate: selectedDate)

        let sut = makeTestStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.calendar(.presented(.navigateToDiary))) {
            // Then
            $0.calendar = nil
            $0.dates = expectedWeekDates
            $0.selectedDate = selectedDate
        }

        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }

    // MARK: - Computed Properties Tests

    @Test("diariesOnSelectedDate: 선택 날짜의 diaries 반환")
    func diariesOnSelectedDate_returnsDiariesForSelectedDate() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedDiary = makeDiary(yearMonthDay: testDate)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.diaries = [testDate: [expectedDiary]]

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        #expect(sut.state.diariesOnSelectedDate == [expectedDiary])
    }

    @Test("workoutsOnSelectedDate: 선택 날짜의 workouts 반환")
    func workoutsOnSelectedDate_returnsWorkoutsForSelectedDate() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedWorkout = makeHealthKitWorkout(yearMonthDay: testDate)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.workouts = [testDate: [expectedWorkout]]

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        #expect(sut.state.workoutsOnSelectedDate == [expectedWorkout])
    }

    // MARK: - Refresh Tests

    @Test("refreshCurrentWeek: fetchWeekRecords 트리거")
    func refreshCurrentWeek_triggersFetchWeekRecords() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = makeWeekDates(containing: testDate)

        let sut = makeTestStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.refreshCurrentWeek)

        // Then
        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }

    // MARK: - CreateDiary Integration Tests

    @Test("createRecord: CreateDiary를 추가 모드로 표시")
    func createRecord_opensCreateDiaryInAddMode() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let healthKitWorkout = makeHealthKitWorkout(yearMonthDay: testDate)

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [] }
        }

        sut.exhaustivity = .off

        // When
        await sut.send(.createRecord(healthKitWorkout))

        // Then
        #expect(sut.state.createDiary != nil)
        #expect(sut.state.createDiary?.existingRecord == nil)
        #expect(sut.state.createDiary?.healthKitWorkout == healthKitWorkout)
    }

    @Test("editRecord: CreateDiary를 편집 모드로 표시")
    func editRecord_opensCreateDiaryInEditMode() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let diary = makeDiary(yearMonthDay: testDate)

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [] }
        }

        sut.exhaustivity = .off

        // When & Then
        await sut.send(.editRecord(diary)) {
            $0.createDiary = CreateDiaryFeature.State(
                existingRecord: diary,
                healthKitWorkout: diary.workout
            )
        }
    }

    @Test("createDiary dismiss: 시트 닫힘")
    func createDiaryDismiss_closesSheet() async {
        // Given
        var initialState = DailyDetailFeature.State()
        initialState.createDiary = CreateDiaryFeature.State(
            existingRecord: nil,
            healthKitWorkout: makeHealthKitWorkout(yearMonthDay: makeTodayYearMonthDay())
        )

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.createDiary(.dismiss)) {
            $0.createDiary = nil
        }
    }

    @Test("createDiary recordSaved: 주 단위 새로고침")
    func createDiarySaved_refreshesWeek() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = weekDates
        initialState.createDiary = CreateDiaryFeature.State(
            existingRecord: nil,
            healthKitWorkout: makeHealthKitWorkout(yearMonthDay: testDate)
        )

        let sut = makeTestStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.createDiary(.presented(.recordSaved))) {
            $0.createDiary = nil
        }

        // Then
        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }

    // MARK: - Settings Integration Tests

    @Test("settingsButtonTapped: Settings 화면 표시")
    func settingsButtonTapped_opensSettings() async {
        // Given
        let testDate = makeTodayYearMonthDay()

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        }

        sut.exhaustivity = .off

        // When & Then
        await sut.send(.settingsButtonTapped) {
            $0.settings = SettingsFeature.State()
        }
    }

    @Test("settings dismiss: 화면 닫힘")
    func settingsDismiss_closesSettings() async {
        // Given
        let testDate = makeTodayYearMonthDay()

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.settings = SettingsFeature.State()

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.settings(.dismiss)) {
            $0.settings = nil
        }
    }

    // MARK: - Preload Tests

    @Test("preloadRequested: weatherTrademark이 nil이면 fetch 트리거")
    func preloadRequested_noTrademark_fetchesTrademark() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedTrademark = WeatherTrademark(
            imageURL: URL(string: "https://example.com/icon.png"),
            legalPageURL: URL(string: "https://example.com/legal")
        )

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.weatherClient.fetchTrademark = { expectedTrademark }
            $0.shoeClient.fetchAllShoes = { [] }
        }

        // .merge로 전송되는 액션들의 순서가 비결정적이므로 exhaustivity off
        sut.exhaustivity = .off

        // When
        await sut.send(.preloadRequested)

        // Then
        await sut.skipReceivedActions()
        #expect(sut.state.weatherTrademark == expectedTrademark)
    }

    @Test("preloadRequested: weatherTrademark이 이미 있으면 fetch 생략")
    func preloadRequested_existingTrademark_skipsFetch() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let existingTrademark = WeatherTrademark(
            imageURL: URL(string: "https://example.com/icon.png"),
            legalPageURL: URL(string: "https://example.com/legal")
        )

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.weatherTrademark = existingTrademark

        let sut = makeTestStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        sut.exhaustivity = .off

        // When
        await sut.send(.preloadRequested)

        // Then - 최종 상태 확인 (weatherTrademark은 변경되지 않음)
        await sut.skipReceivedActions()
        #expect(sut.state.weatherTrademark == existingTrademark)
    }

    // MARK: - Error Handling Tests

    @Test("weekRecordsFetchFailed: 에러 상태 설정")
    func weekRecordsFetchFailed_setsErrorState() async {
        // Given
        let expectedError = DailyDetailError.fetchFailed(underlyingError: "Network error")

        var initialState = DailyDetailFeature.State()
        initialState.isLoading = true

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.weekRecordsFetchFailed(expectedError)) {
            $0.isLoading = false
            $0.error = expectedError
        }
    }
}

    // MARK: - filteredWorkoutsOnSelectedDate Tests

    @Test("filteredWorkoutsOnSelectedDate: diary와 startTime 일치하는 workout 제외")
    func filteredWorkouts_excludesWorkoutsMatchingDiaryStartTime() {
        // Given
        let testDate = makeTodayYearMonthDay()
        let sharedStart = testDate.toDate()
        let diary = makeDiary(yearMonthDay: testDate, startOffset: 0)
        let matchedWorkout = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 0)
        let unmatchedWorkout = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 3600)

        var state = DailyDetailFeature.State(selectedDate: testDate)
        state.diaries = [testDate: [diary]]
        state.workouts = [testDate: [matchedWorkout, unmatchedWorkout]]

        // When & Then
        #expect(state.filteredWorkoutsOnSelectedDate == [unmatchedWorkout])
    }

    @Test("filteredWorkoutsOnSelectedDate: diary 없으면 모든 workout 포함")
    func filteredWorkouts_noDiaries_includesAllWorkouts() {
        // Given
        let testDate = makeTodayYearMonthDay()
        let w1 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 0)
        let w2 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 3600)

        var state = DailyDetailFeature.State(selectedDate: testDate)
        state.workouts = [testDate: [w1, w2]]

        // When & Then
        #expect(state.filteredWorkoutsOnSelectedDate.count == 2)
    }

    @Test("filteredWorkoutsOnSelectedDate: workout 없으면 빈 배열")
    func filteredWorkouts_noWorkouts_returnsEmpty() {
        // Given
        let testDate = makeTodayYearMonthDay()
        let diary = makeDiary(yearMonthDay: testDate)

        var state = DailyDetailFeature.State(selectedDate: testDate)
        state.diaries = [testDate: [diary]]

        // When & Then
        #expect(state.filteredWorkoutsOnSelectedDate.isEmpty)
    }

    @Test("filteredWorkoutsOnSelectedDate: 여러 diary 중 일부만 매칭 → 나머지 workout 유지")
    func filteredWorkouts_partialMatch_keepsUnmatched() {
        // Given
        let testDate = makeTodayYearMonthDay()
        let d1 = makeDiary(yearMonthDay: testDate, startOffset: 0)
        let d2 = makeDiary(yearMonthDay: testDate, startOffset: 3600)
        let w1 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 0)
        let w2 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 3600)
        let w3 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 7200)

        var state = DailyDetailFeature.State(selectedDate: testDate)
        state.diaries = [testDate: [d1, d2]]
        state.workouts = [testDate: [w1, w2, w3]]

        // When & Then
        #expect(state.filteredWorkoutsOnSelectedDate == [w3])
    }

    // MARK: - Migration Side-Effect Tests

    @Test("weekRecordsFetched: metrics=0인 diary → HealthKit 데이터로 마이그레이션 호출")
    func weekRecordsFetched_zeroMetricsDiary_triggersMigration() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)
        let startTime = testDate.toDate()

        let diaryWithZeroMetrics = makeDiaryWithZeroMetrics(
            yearMonthDay: testDate,
            startTime: startTime
        )
        let matchingWorkout = makeHealthKitWorkout(
            yearMonthDay: testDate,
            startOffset: 0
        )

        var migratedRecordId: UUID?
        var migratedActiveEnergy: Double?

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = weekDates

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.persistencesClient.fetchRecords = { _, _ in [diaryWithZeroMetrics] }
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [matchingWorkout] }
            $0.persistencesClient.update = { id, _, _, _, _, _, _, _, _, _, _, _, _, _, activeEnergy, _, _, _, _, _, _, _, _, _ in
                migratedRecordId = id
                migratedActiveEnergy = activeEnergy
            }
            $0.shoeClient.fetchAllShoes = { [] }
        }

        sut.exhaustivity = .off

        // When
        await sut.send(.fetchWeekRecords)
        await sut.skipReceivedActions()

        // Then
        #expect(migratedRecordId == diaryWithZeroMetrics.id)
        #expect(migratedActiveEnergy == matchingWorkout.activeEnergyBurned)
    }

    @Test("weekRecordsFetched: metrics 모두 0 초과인 diary → 마이그레이션 생략")
    func weekRecordsFetched_nonZeroMetrics_skipsMigration() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)
        let diary = makeDiary(yearMonthDay: testDate)
        var migrationCallCount = 0

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = weekDates

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.persistencesClient.fetchRecords = { _, _ in [diary] }
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [] }
            $0.persistencesClient.update = { _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ in
                migrationCallCount += 1
            }
            $0.shoeClient.fetchAllShoes = { [] }
        }

        sut.exhaustivity = .off

        // When
        await sut.send(.fetchWeekRecords)
        await sut.skipReceivedActions()

        // Then — makeDiary의 workout은 metrics > 0이므로 마이그레이션 미호출
        #expect(migrationCallCount == 0)
    }

// MARK: - Private Test Helpers

private extension DailyDetailFeatureTests {
    func makeTestStore(
        initialState: DailyDetailFeature.State,
        diaries: [Diary],
        workouts: [HealthKitWorkout]
    ) -> TestStore<DailyDetailFeature.State, DailyDetailFeature.Action> {
        TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in workouts }
            $0.persistencesClient.fetchRecords = { _, _ in diaries }
            $0.persistencesClient.update = { _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ in }
            $0.shoeClient.fetchAllShoes = { [] }
        }
    }
}
