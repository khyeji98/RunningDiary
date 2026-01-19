//
//  DailyDetailFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 1/19/26.
//

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
        let mockTrademark = WeatherTrademark(imageURL: nil, legalPageURL: nil)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.weatherTrademark = mockTrademark

        let sut = makeTestStore(
            initialState: initialState,
            diaries: expectedDiaries,
            workouts: expectedWorkouts
        )

        // .merge로 전송되는 액션들의 순서가 비결정적이므로 exhaustivity off
        sut.exhaustivity = .off

        // When
        await sut.send(.onAppear) {
            // Then
            $0.dates = expectedWeekDates
        }

        // Then - 최종 상태 확인
        await sut.skipReceivedActions()
        #expect(sut.state.diaries == Dictionary(grouping: expectedDiaries, by: \.yearMonthDay))
        #expect(sut.state.workouts == Dictionary(grouping: expectedWorkouts, by: \.yearMonthDay))
        #expect(sut.state.isLoading == false)
    }

    @Test("onAppear: dates가 이미 있으면 dates 유지")
    func onAppear_existingDates_preservesDates() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let existingDates = makeWeekDates(containing: testDate)
        let mockTrademark = WeatherTrademark(imageURL: nil, legalPageURL: nil)

        var initialState = DailyDetailFeature.State(selectedDate: testDate, dates: existingDates)
        initialState.weatherTrademark = mockTrademark

        let sut = makeTestStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // .merge로 전송되는 액션들의 순서가 비결정적이므로 exhaustivity off
        sut.exhaustivity = .off

        // When - dates가 이미 있으므로 state 변화 없음
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
            $0.diaries = Dictionary(grouping: expectedDiaries, by: \.yearMonthDay)
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

    // MARK: - AddRecord Integration Tests

    @Test("createRecord: AddRecord를 추가 모드로 표시")
    func createRecord_opensAddRecordInAddMode() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let healthKitWorkout = makeHealthKitWorkout(yearMonthDay: testDate)

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        }

        sut.exhaustivity = .off

        // When
        await sut.send(.createRecord(healthKitWorkout))

        // Then
        #expect(sut.state.addRecord != nil)
        #expect(sut.state.addRecord?.existingRecord == nil)
        #expect(sut.state.addRecord?.healthKitWorkout.data == healthKitWorkout)
    }

    @Test("editRecord: AddRecord를 편집 모드로 표시")
    func editRecord_opensAddRecordInEditMode() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let diary = makeDiary(yearMonthDay: testDate)

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.editRecord(diary)) {
            $0.addRecord = AddRecordFeature.State(
                existingRecord: diary,
                healthKitWorkout: nil
            )
        }
    }

    @Test("addRecord dismiss: 시트 닫힘")
    func addRecordDismiss_closesSheet() async {
        // Given
        var initialState = DailyDetailFeature.State()
        initialState.addRecord = AddRecordFeature.State(
            existingRecord: nil,
            healthKitWorkout: nil
        )

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.addRecord(.dismiss)) {
            $0.addRecord = nil
        }
    }

    @Test("addRecord recordSaved: 주 단위 새로고침")
    func addRecordSaved_refreshesWeek() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = weekDates
        initialState.addRecord = AddRecordFeature.State(
            existingRecord: nil,
            healthKitWorkout: nil
        )

        let sut = makeTestStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.addRecord(.presented(.recordSaved))) {
            $0.addRecord = nil
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

    // MARK: - Weather Attribution Tests

    @Test("onAppear: weatherTrademark이 nil이면 fetch 트리거")
    func onAppear_noTrademark_fetchesTrademark() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedTrademark = WeatherTrademark(
            imageURL: URL(string: "https://example.com/icon.png"),
            legalPageURL: URL(string: "https://example.com/legal")
        )

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [] }
            $0.persistencesClient.fetchRecords = { _, _ in [] }
            $0.weatherClient.fetchTrademark = { expectedTrademark }
        }

        // .merge로 전송되는 액션들의 순서가 비결정적이므로 exhaustivity off
        sut.exhaustivity = .off

        // When
        await sut.send(.onAppear) {
            $0.dates = makeWeekDates(containing: testDate)
        }

        // Then - 최종 상태 확인
        await sut.skipReceivedActions()
        #expect(sut.state.weatherTrademark == expectedTrademark)
        #expect(sut.state.isLoading == false)
    }

    @Test("onAppear: weatherTrademark이 이미 있으면 fetch 생략")
    func onAppear_existingTrademark_skipsFetch() async {
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

        // .merge로 전송되는 액션들의 순서가 비결정적이므로 exhaustivity off
        sut.exhaustivity = .off

        // When
        await sut.send(.onAppear) {
            $0.dates = makeWeekDates(containing: testDate)
        }

        // Then - 최종 상태 확인 (weatherTrademark은 변경되지 않음)
        await sut.skipReceivedActions()
        #expect(sut.state.weatherTrademark == existingTrademark)
        #expect(sut.state.isLoading == false)
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
            $0.persistencesClient.migrateHealthKitMetrics = { _, _, _, _, _ in }
        }
    }
}
