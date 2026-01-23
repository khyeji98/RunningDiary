//
//  TestHelpers.swift
//  RunDiaryTests
//
//  Created by Claude on 1/19/26.
//

import CommonFoundation
import Foundation
import Models

@testable import RunDiary

// MARK: - Date Helpers

/// 오늘 날짜의 YearMonthDay 반환
func makeTodayYearMonthDay() -> YearMonthDay {
    YearMonthDay(date: Date())
}

/// YearMonthDay 생성 헬퍼
/// - Parameters:
///   - year: 연도 (기본값: 현재 연도)
///   - month: 월 (기본값: 1)
///   - day: 일 (기본값: 1)
/// - Returns: 지정된 날짜의 YearMonthDay
func makeYearMonthDay(
    year: Int? = nil,
    month: Int = 1,
    day: Int = 1
) -> YearMonthDay {
    let calendar = Calendar.current
    let currentYear = year ?? calendar.component(.year, from: Date())
    return YearMonthDay(year: currentYear, month: month, day: day)
}

/// 주 날짜 배열 생성 헬퍼
func makeWeekDates(containing date: YearMonthDay) -> [YearMonthDay] {
    DateHelper.getWeekDates(for: date.toDate()).map { YearMonthDay(date: $0) }
}

// MARK: - Model Helpers

/// HealthKitWorkout 생성 헬퍼
func makeHealthKitWorkout(
    yearMonthDay: YearMonthDay,
    distance: Double = 5.0,
    duration: TimeInterval = 1800,
    averagePace: String = "6'00\"",
    averageHeartRate: Int = 150,
    averageCadence: Int = 170,
    startOffset: TimeInterval = 0
) -> HealthKitWorkout {
    let startDate = yearMonthDay.toDate().addingTimeInterval(startOffset)
    return HealthKitWorkout(
        distance: distance,
        duration: duration,
        averagePace: averagePace,
        averageHeartRate: averageHeartRate,
        averageCadence: averageCadence,
        activeEnergyBurned: 350.0,
        runningVerticalOscillation: 8.0,
        runningGroundContactTime: 240.0,
        walkingStepLength: 1.0,
        restingHeartRate: 60.0,
        runningPower: 300.0,
        runningStrideLength: 1.0,
        heartRateRecoveryOneMinute: 20.0,
        routeData: nil,
        startDate: startDate,
        endDate: startDate.addingTimeInterval(duration)
    )
}

/// Diary 생성 헬퍼
func makeDiary(
    yearMonthDay: YearMonthDay,
    distance: Double = 5.0,
    duration: TimeInterval = 1800,
    averagePace: String = "6'00\"",
    averageHeartRate: Int = 150,
    averageCadence: Int = 170,
    startOffset: TimeInterval = 0
) -> Diary {
    let workout = makeHealthKitWorkout(
        yearMonthDay: yearMonthDay,
        distance: distance,
        duration: duration,
        averagePace: averagePace,
        averageHeartRate: averageHeartRate,
        averageCadence: averageCadence,
        startOffset: startOffset
    )
    return Diary(
        workout: workout,
        runningStyle: .midfoot
    )
}
