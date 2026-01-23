//
//  DailyDetailFeature.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import CommonFoundation
import ComposableArchitecture
import Foundation
import Models

@Reducer
struct DailyDetailFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var selectedDate: YearMonthDay
        var dates: [YearMonthDay]
        var diaries: [YearMonthDay: [Diary]] = [:]
        var workouts: [YearMonthDay: [HealthKitWorkout]] = [:]
        var isLoading: Bool = false
        var error: DailyDetailError? = nil
        var weatherTrademark: WeatherTrademark? = nil
        @Presents var addRecord: AddRecordFeature.State?
        @Presents var calendar: CalendarFeature.State?
        @Presents var settings: SettingsFeature.State?

        var diariesOnSelectedDate: [Diary] {
            diaries[selectedDate] ?? []
        }
        var workoutsOnSelectedDate: [HealthKitWorkout] {
            workouts[selectedDate] ?? []
        }

        var filteredWorkoutsOnSelectedDate: [HealthKitWorkout] {
            let diaryStartTimes = Set(diariesOnSelectedDate.map { $0.workout.startTime })
            return workoutsOnSelectedDate.filter { !diaryStartTimes.contains($0.startTime) }
        }

        init(
            selectedDate: YearMonthDay = .today,
            dates: [YearMonthDay] = [],
            diaries: [YearMonthDay: [Diary]] = [:],
            workouts: [YearMonthDay: [HealthKitWorkout]] = [:],
            addRecord: AddRecordFeature.State? = nil,
            calendar: CalendarFeature.State? = nil,
            settings: SettingsFeature.State? = nil
        ) {
            self.selectedDate = selectedDate
            self.dates = dates
            self.diaries = diaries
            self.workouts = workouts
            self.addRecord = addRecord
            self.calendar = calendar
            self.settings = settings
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case dateSelected(YearMonthDay)
        case weekChanged(offset: Int)
        case fetchWeekRecords
        case weekRecordsFetched([Diary], [HealthKitWorkout])
        case weekRecordsFetchFailed(DailyDetailError)
        case fetchWeatherTrademark
        case weatherTrademarkFetched(WeatherTrademark)
        case createRecord(HealthKitWorkout)
        case editRecord(Diary)
        case addRecord(PresentationAction<AddRecordFeature.Action>)
        case calendarButtonTapped
        case calendar(PresentationAction<CalendarFeature.Action>)
        case settingsButtonTapped
        case settings(PresentationAction<SettingsFeature.Action>)
        case refreshCurrentWeek
    }

    // MARK: - Dependency

    @Dependency(\.healthKitClient) var healthKitClient
    @Dependency(\.persistencesClient) var persistencesClient
    @Dependency(\.weatherClient) var weatherClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.dates.isEmpty {
                    state.dates = DateHelper.getWeekDates(for: state.selectedDate.toDate()).map { YearMonthDay(date: $0) }
                }

                return .merge(
                    .send(.fetchWeekRecords),
                    .send(.fetchWeatherTrademark)
                )

            case let .dateSelected(date):
                state.selectedDate = date
                return .none

            case let .weekChanged(offset):
                // 현재 주에서 N주 이동
                let calendar = Calendar.current
                let currentWeekStart = state.dates.first ?? state.selectedDate
                let newWeekStart = DateHelper.addWeeks(offset, to: currentWeekStart.toDate())
                state.dates = DateHelper.getWeekDates(for: newWeekStart).map { YearMonthDay(date: $0) }

                // 선택된 날짜를 새 주의 같은 요일로 이동
                if let selectedDateWeekday = calendar.dateComponents([.weekday], from: state.selectedDate.toDate()).weekday,
                   let newSelectedDate = state.dates.first(where: {
                       calendar.dateComponents([.weekday], from: $0.toDate()).weekday == selectedDateWeekday
                   }) {
                    state.selectedDate = newSelectedDate
                } else {
                    // 같은 요일이 없으면 새 주의 첫날(월요일)로 이동
                    state.selectedDate = YearMonthDay(date: newWeekStart)
                }

                return .send(.fetchWeekRecords)

            case .fetchWeekRecords:
                guard let startDate = state.dates.first,
                      let endDate = state.dates.last else {
                    return .send(.weekRecordsFetchFailed(.emptyWeekDates))
                }

                state.isLoading = true
                state.error = nil

                return .run { send in
                    do {
                        async let diaries = try await persistencesClient.fetchRecords(startDate.toDate(), endDate.toDate())
                        async let workouts = try await healthKitClient.fetchRunningDataBetweenDates(startDate.toDate(), endDate.toDate())
                        try await send(.weekRecordsFetched(diaries, workouts))
                    } catch {
                        let errorMessage = error.localizedDescription
                        await send(.weekRecordsFetchFailed(.fetchFailed(underlyingError: errorMessage)))
                    }
                }

            case let .weekRecordsFetched(diaries, workouts):
                state.diaries = Dictionary(grouping: diaries, by: \.workout.yearMonthDay)
                state.workouts = Dictionary(grouping: workouts, by: \.yearMonthDay)
                state.isLoading = false
                return .run { [persistencesClient] _ in
                    // HealthKit -> SwiftData 데이터 동기화
                    for diary in diaries {
                        // 8개 속성 중 하나라도 0이면 마이그레이션 대상 (기존에는 nil 체크였으나 HealthKitWorkout에서는 0으로 처리됨)
                        guard diary.workout.activeEnergyBurned == 0
                            || diary.workout.runningVerticalOscillation == 0
                            || diary.workout.runningGroundContactTime == 0
                            || diary.workout.walkingStepLength == 0
                            || diary.workout.restingHeartRate == 0
                            || diary.workout.runningPower == 0
                            || diary.workout.runningStrideLength == 0
                            || diary.workout.heartRateRecoveryOneMinute == 0
                        else { continue }

                        // startTime이 일치하는 workout 찾기
                        guard let matchingWorkout = workouts.first(where: { $0.startTime == diary.workout.startTime }) else { continue }

                        // persistencesClient로 업데이트 요청
                        try? await persistencesClient.updateRecord(
                            recordId: diary.id,
                            activeEnergyBurned: matchingWorkout.activeEnergyBurned,
                            runningVerticalOscillation: matchingWorkout.runningVerticalOscillation,
                            runningGroundContactTime: matchingWorkout.runningGroundContactTime,
                            walkingStepLength: matchingWorkout.walkingStepLength,
                            restingHeartRate: matchingWorkout.restingHeartRate,
                            runningPower: matchingWorkout.runningPower,
                            runningStrideLength: matchingWorkout.runningStrideLength,
                            heartRateRecoveryOneMinute: matchingWorkout.heartRateRecoveryOneMinute
                        )
                    }
                }

            case let .weekRecordsFetchFailed(error):
                state.isLoading = false
                state.error = error
                AppLogger.dailyDetail.error("weekRecordsFetchFailed - error: \(error.localizedDescription)")
                return .none

            case .fetchWeatherTrademark:
                guard state.weatherTrademark == nil else { return .none }

                return .run { send in
                    let trademark = try await weatherClient.fetchTrademark()
                    await send(.weatherTrademarkFetched(trademark))
                }

            case let .weatherTrademarkFetched(trademark):
                state.weatherTrademark = trademark
                return .none

            case let .createRecord(healthKitWorkout):
                AppLogger.dailyDetail.debug("showAddRecord - mode: 추가, date: \(state.selectedDate), healthKitWorkout: \(healthKitWorkout)")
                state.addRecord = AddRecordFeature.State(
                    existingRecord: nil,
                    healthKitWorkout: healthKitWorkout
                )
                return .none

            case let .editRecord(runningRecord):
                AppLogger.dailyDetail.debug("showAddRecord - mode: 수정, date: \(state.selectedDate), runningRecord: \(runningRecord)")
                state.addRecord = AddRecordFeature.State(
                    existingRecord: runningRecord,
                    healthKitWorkout: runningRecord.workout
                )
                return .none

            case .addRecord(.presented(.recordSaved)):
                AppLogger.dailyDetail.info("recordSaved - 새로고침 시작")
                state.addRecord = nil
                return .send(.fetchWeekRecords)

            case .addRecord(.dismiss):
                AppLogger.dailyDetail.debug("addRecord dismiss - 기록 추가/편집 화면 닫힘")
                state.addRecord = nil
                return .none

            case .addRecord:
                return .none

            case .calendarButtonTapped:
                state.calendar = CalendarFeature.State(selectedDate: state.selectedDate)
                return .none

            case .calendar(.dismiss):
                state.calendar = nil
                return .none

            case .calendar(.presented(.navigateToDiary)):
                guard let selectedYearMonthDay = state.calendar?.selectedDate else {
                    state.calendar = nil
                    return .none
                }

                let selectedDate = selectedYearMonthDay
                AppLogger.dailyDetail.info("navigateToDiary - \(selectedYearMonthDay) 날짜로 이동")

                // 선택된 날짜가 속한 주로 즉시 전환
                let newWeekDates = DateHelper.getWeekDates(for: selectedDate.toDate()).map { YearMonthDay(date: $0) }
                state.dates = newWeekDates
                state.selectedDate = selectedDate

                // 캘린더 시트 닫기
                state.calendar = nil

                return .send(.fetchWeekRecords)

            case .calendar:
                return .none

            case .settingsButtonTapped:
                AppLogger.dailyDetail.debug("settingsButtonTapped - 설정 화면 표시")
                state.settings = SettingsFeature.State()
                return .none

            case .settings(.dismiss):
                AppLogger.dailyDetail.debug("settings dismiss - 설정 화면 닫힘")
                state.settings = nil
                return .none

            case .settings:
                return .none

            case .refreshCurrentWeek:
                return .send(.fetchWeekRecords)
            }
        }
        .ifLet(\.$addRecord, action: \.addRecord) {
            AddRecordFeature()
        }
        .ifLet(\.$calendar, action: \.calendar) {
            CalendarFeature()
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsFeature()
        }
    }
}
