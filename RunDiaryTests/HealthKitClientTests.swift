//
//  HealthKitClientTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/23/25.
//

import Foundation
import HealthKitService
import Models

import Testing

@testable import RunDiary

@Suite("HealthKitClient")
struct HealthKitClientTests {

  // MARK: - fetchRunningDataBetweenDates Tests

  @Test("fetchRunningDataBetweenDates: 날짜 범위 러닝 데이터 조회 성공")
  func fetchRunningDataBetweenDatesReturnsData() async throws {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
    let endDate = Date.now

    let expectedData = [
      HealthKitWorkout(
        distance: 5.0,
        duration: 1800,
        averagePace: "6'00\"",
        averageHeartRate: 150,
        averageCadence: 178,
        activeEnergyBurned: 400,
        runningVerticalOscillation: 8.0,
        runningGroundContactTime: 240.0,
        walkingStepLength: 1.0,
        restingHeartRate: 58.0,
        runningPower: 290.0,
        runningStrideLength: 1.0,
        heartRateRecoveryOneMinute: 21.0,
        routeData: nil,
        startDate: Calendar.current.date(byAdding: .day, value: -5, to: endDate)!,
        endDate: Calendar.current.date(byAdding: .day, value: -5, to: endDate)!.addingTimeInterval(1800)
      ),
      HealthKitWorkout(
        distance: 7.5,
        duration: 2700,
        averagePace: "6'00\"",
        averageHeartRate: 160,
        averageCadence: 182,
        activeEnergyBurned: 600,
        runningVerticalOscillation: 8.2,
        runningGroundContactTime: 235.0,
        walkingStepLength: 1.1,
        restingHeartRate: 62.0,
        runningPower: 310.0,
        runningStrideLength: 1.1,
        heartRateRecoveryOneMinute: 19.0,
        routeData: nil,
        startDate: Calendar.current.date(byAdding: .day, value: -3, to: endDate)!,
        endDate: Calendar.current.date(byAdding: .day, value: -3, to: endDate)!.addingTimeInterval(2700)
      ),
      HealthKitWorkout(
        distance: 10.0,
        duration: 3600,
        averagePace: "6'00\"",
        averageHeartRate: 165,
        averageCadence: 185,
        activeEnergyBurned: 800,
        runningVerticalOscillation: 8.5,
        runningGroundContactTime: 230.0,
        walkingStepLength: 1.2,
        restingHeartRate: 65.0,
        runningPower: 320.0,
        runningStrideLength: 1.2,
        heartRateRecoveryOneMinute: 18.0,
        routeData: nil,
        startDate: Calendar.current.date(byAdding: .day, value: -1, to: endDate)!,
        endDate: Calendar.current.date(byAdding: .day, value: -1, to: endDate)!.addingTimeInterval(3600)
      )
    ]

    let client = HealthKitClient(
      fetchRunningDataBetweenDates: { _, _ in expectedData },
      fetchDetailedRunningData: { _, _ in nil }
    )

    let result = try await client.fetchRunningDataBetweenDates(startDate, endDate)

    #expect(result.count == 3)
    #expect(result[0].distance == 5.0)
    #expect(result[1].distance == 7.5)
    #expect(result[2].distance == 10.0)
  }

  @Test("fetchRunningDataBetweenDates: 데이터가 없을 때 빈 배열 반환")
  func fetchRunningDataBetweenDatesReturnsEmptyWhenNoData() async throws {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
    let endDate = Date.now

    let client = HealthKitClient(
      fetchRunningDataBetweenDates: { _, _ in [] },
      fetchDetailedRunningData: { _, _ in nil }
    )

    let result = try await client.fetchRunningDataBetweenDates(startDate, endDate)

    #expect(result.isEmpty)
  }

  @Test("fetchRunningDataBetweenDates: 데이터 조회 중 에러 발생")
  func fetchRunningDataBetweenDatesThrowsError() async throws {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
    let endDate = Date.now

    let client = HealthKitClient(
      fetchRunningDataBetweenDates: { _, _ in
        throw HealthKitError.notAvailable
      },
      fetchDetailedRunningData: { _, _ in nil }
    )

    await #expect(throws: HealthKitError.self) {
      try await client.fetchRunningDataBetweenDates(startDate, endDate)
    }
  }

  @Test("fetchRunningDataBetweenDates: 날짜 범위가 역순일 때")
  func fetchRunningDataBetweenDatesWithReversedDates() async throws {
    let startDate = Date.now
    let endDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!

    let client = HealthKitClient(
      fetchRunningDataBetweenDates: { _, _ in [] },
      fetchDetailedRunningData: { _, _ in nil }
    )

    let result = try await client.fetchRunningDataBetweenDates(startDate, endDate)

    #expect(result.isEmpty)
  }
}
