//
//  CalendarFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 12/1/25.
//

import ComposableArchitecture
import Foundation
import Models
import Testing

@testable import RunDiary

@MainActor
struct CalendarFeatureTests {
    // MARK: - Test Cases

    @Test("onAppear 시 초기 날짜 범위로 fetchRecords 호출")
    func onAppear_fetchRecords() async {
        // Given
        let selectedDate = YearMonthDay(year: 2025, month: 6, day: 15)
        let store = makeTestStore(selectedDate: selectedDate)

        // When
        await store.send(.onAppear)

        // Then
        await store.receive(\.fetchRecords) {
            $0.isLoading = true
        }
        await store.receive(\.recordsFetched) {
            $0.isLoading = false
        }
    }

    @Test("fetchRecords 성공 시 dailyRecords 및 monthlyTotals 업데이트")
    func fetchRecords_success() async {
        // Given
        let startDate = YearMonthDay(year: 2025, month: 6, day: 1)
        let endDate = YearMonthDay(year: 2025, month: 6, day: 30)

        let mockRecord = makeRunningRecord(yearMonthDay: startDate)

        let expectedDailyRecords: [YearMonthDay: DailyRecord] = [
            startDate: DailyRecord(
                yearMonthDay: startDate,
                healthKitWorkouts: [],
                savedRecords: [mockRecord]
            )
        ]

        let store = makeTestStore(
            selectedDate: startDate,
            mockDailyRecords: expectedDailyRecords
        )

        // When
        await store.send(.fetchRecords(startDate: startDate, endDate: endDate)) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.recordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
            let yearMonth = startDate.toYearMonth()
            $0.monthlyTotals[yearMonth] = 5.0
        }
    }

    @Test("fetchRecords 실패 시 에러 처리")
    func fetchRecords_failure() async {
        // Given
        let startDate = YearMonthDay(year: 2025, month: 6, day: 1)
        let endDate = YearMonthDay(year: 2025, month: 6, day: 30)

        let store = makeTestStore(
            selectedDate: startDate,
            shouldFail: true
        )

        // When
        await store.send(.fetchRecords(startDate: startDate, endDate: endDate)) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.recordsFetchedFailure) {
            $0.isLoading = false
        }
    }

    @Test("잘못된 날짜 범위로 fetchRecords 호출 시 즉시 에러")
    func fetchRecords_invalidDateRange() async {
        // Given
        let startDate = YearMonthDay(year: 2025, month: 6, day: 30)
        let endDate = YearMonthDay(year: 2025, month: 6, day: 1)
        let store = makeTestStore(selectedDate: startDate)

        // When & Then
        await store.send(.fetchRecords(startDate: startDate, endDate: endDate))
        await store.receive(\.recordsFetchedFailure)
    }

    @Test("fetchOlderRecords 시 startDate 확장 및 추가 fetch")
    func fetchOlderRecords_extendsStartDate() async {
        // Given
        let selectedDate = YearMonthDay(year: 2025, month: 6, day: 15)
        let store = makeTestStore(selectedDate: selectedDate)
        let originalStartDate = store.state.startDate

        // When
        await store.send(.fetchOlderRecords) {
            // startDate가 6개월 이전으로 확장
            let expectedNewStart = originalStartDate.add(month: -6)!
            $0.startDate = expectedNewStart
        }

        // Then - fetchRecords 액션과 그 결과를 모두 받아야 함
        await store.receive(\.fetchRecords) {
            $0.isLoading = true
        }
        await store.receive(\.recordsFetched) {
            $0.isLoading = false
        }
    }

    @Test("selectDate 시 selectedDate 업데이트")
    func selectDate_updatesSelectedDate() async {
        // Given
        let initialDate = YearMonthDay(year: 2025, month: 6, day: 15)
        let newDate = YearMonthDay(year: 2025, month: 6, day: 20)
        let store = makeTestStore(selectedDate: initialDate)

        // When & Then
        await store.send(.selectDate(newDate)) {
            $0.selectedDate = newDate
        }
    }

    @Test("saveLastVisibleMonth 시 lastVisibleMonth 업데이트")
    func saveLastVisibleMonth_updatesLastVisibleMonth() async {
        // Given
        let store = makeTestStore(selectedDate: .today)
        let month = YearMonth(year: 2025, month: 3)

        // When & Then — fileprivate(set)이므로 exhaustivity off로 처리
        store.exhaustivity = .off
        await store.send(.saveLastVisibleMonth(month))
        #expect(store.state.lastVisibleMonth == month)
    }

    @Test("oldestMonthBecameVisible 시 fetchOlderRecords 체이닝")
    func oldestMonthBecameVisible_chainsFetchOlderRecords() async {
        // Given
        let selectedDate = YearMonthDay(year: 2025, month: 6, day: 15)
        let store = makeTestStore(selectedDate: selectedDate)
        let originalStartDate = store.state.startDate

        // When
        await store.send(.oldestMonthBecameVisible)

        // Then
        await store.receive(\.fetchOlderRecords) {
            $0.startDate = originalStartDate.add(month: -6)!
        }
        await store.receive(\.fetchRecords) {
            $0.isLoading = true
        }
        await store.receive(\.recordsFetched) {
            $0.isLoading = false
        }
    }

    @Test("recordsFetched: 같은 월 여러 기록의 거리가 누적됨")
    func recordsFetched_accumulatesDistanceInSameMonth() async {
        // Given
        let june1 = YearMonthDay(year: 2025, month: 6, day: 1)
        let june15 = YearMonthDay(year: 2025, month: 6, day: 15)
        let record1 = makeRunningRecord(yearMonthDay: june1, distance: 5.0)
        let record2 = makeRunningRecord(yearMonthDay: june15, distance: 7.0)

        let mockRecords: [YearMonthDay: DailyRecord] = [
            june1: DailyRecord(yearMonthDay: june1, healthKitWorkouts: [], savedRecords: [record1]),
            june15: DailyRecord(yearMonthDay: june15, healthKitWorkouts: [], savedRecords: [record2])
        ]
        let store = makeTestStore(selectedDate: june1, mockDailyRecords: mockRecords)

        // When
        await store.send(.fetchRecords(startDate: june1, endDate: june15)) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.recordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = mockRecords
            $0.monthlyTotals[june1.toYearMonth()] = 12.0
        }
    }

    // MARK: - State Init Tests

    @Test("State init: selectedDate가 오늘이면 endDate = today")
    func stateInit_todaySelected_endDateIsToday() {
        let today = YearMonthDay.today
        let state = CalendarFeature.State(selectedDate: today)
        #expect(state.endDate == today)
        #expect(state.startDate == today.add(month: -6)!)
    }

    @Test("State init: selectedDate가 3개월 전이면 endDate = today")
    func stateInit_recentPast_endDateIsToday() {
        let threeMonthsAgo = YearMonthDay.today.add(month: -3)!
        let state = CalendarFeature.State(selectedDate: threeMonthsAgo)
        #expect(state.endDate == YearMonthDay.today)
    }

    @Test("State init: selectedDate가 6개월 이상 전이면 endDate = selectedDate + 6개월")
    func stateInit_farPast_endDateIsSelectedPlusSixMonths() {
        let farPast = YearMonthDay(year: 2020, month: 1, day: 1)
        let expected = farPast.add(month: 6)!
        let state = CalendarFeature.State(selectedDate: farPast)
        #expect(state.endDate == expected)
        #expect(state.startDate == farPast.add(month: -6)!)
    }

    // MARK: - isEnabledTodayButton Tests

    @Test("isEnabledTodayButton: selectedDate가 today가 아니면 true")
    func isEnabledTodayButton_selectedDateNotToday_returnsTrue() {
        let yesterday = YearMonthDay.today.add(day: -1)!
        let state = CalendarFeature.State(selectedDate: yesterday)
        #expect(state.isEnabledTodayButton == true)
    }

    @Test("isEnabledTodayButton: selectedDate == today, lastVisibleMonth nil → false")
    func isEnabledTodayButton_todayAndNoLastMonth_returnsFalse() {
        let state = CalendarFeature.State(selectedDate: .today)
        #expect(state.isEnabledTodayButton == false)
    }

    @Test("isEnabledTodayButton: selectedDate == today, lastVisibleMonth 과거 월 → true")
    func isEnabledTodayButton_todayAndPastLastMonth_returnsTrue() async {
        let store = makeTestStore(selectedDate: .today)
        store.exhaustivity = .off

        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .month, value: -2, to: Date())!
        let pastMonth = YearMonth(date: pastDate)

        await store.send(.saveLastVisibleMonth(pastMonth))
        #expect(store.state.isEnabledTodayButton == true)
    }

    @Test("isEnabledTodayButton: selectedDate == today, lastVisibleMonth == 현재 월 → false")
    func isEnabledTodayButton_todayAndCurrentLastMonth_returnsFalse() async {
        let store = makeTestStore(selectedDate: .today)
        store.exhaustivity = .off

        let currentMonth = YearMonth(date: Date())
        await store.send(.saveLastVisibleMonth(currentMonth))
        #expect(store.state.isEnabledTodayButton == false)
    }

    // MARK: - Helper

    private func makeTestStore(
        selectedDate: YearMonthDay,
        mockDailyRecords: [YearMonthDay: DailyRecord] = [:],
        shouldFail: Bool = false
    ) -> TestStore<CalendarFeature.State, CalendarFeature.Action> {
        TestStore(
            initialState: CalendarFeature.State(selectedDate: selectedDate)
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { from, to in
                if shouldFail {
                    struct TestError: Error {}
                    throw TestError()
                }
                return mockDailyRecords
            }
        }
    }

    private func makeRunningRecord(
        yearMonthDay: YearMonthDay,
        distance: Double = 5.0,
        startTime: Date? = nil
    ) -> Diary {
        let start = startTime ?? yearMonthDay.toDate()
        let workout = HealthKitWorkout(
            distance: distance,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            activeEnergyBurned: 0,
            runningVerticalOscillation: 0,
            runningGroundContactTime: 0,
            walkingStepLength: 0,
            restingHeartRate: 0,
            runningPower: 0,
            runningStrideLength: 0,
            heartRateRecoveryOneMinute: 0,
            routeData: nil,
            startDate: start,
            endDate: start.addingTimeInterval(1800)
        )
        return Diary(
            workout: workout,
            runningStyle: .midfoot,
            memo: nil
        )
    }
}
