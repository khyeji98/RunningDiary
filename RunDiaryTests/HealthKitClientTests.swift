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
@MainActor
struct HealthKitClientTests {

    // MARK: - fetchRunningDataBetweenDates(weekly) Tests

    @Test("weekly: 매니저가 반환한 데이터를 그대로 반환한다")
    // TC: hkclient-weekly-returnsData
    func fetchWeekly_returnsManagerData() async throws {
        // Given
        let expectedCount = 3
        let expectedDistances: [Double] = [5.0, 7.5, 10.0]
        let workouts = expectedDistances.map { makeHealthKitWorkout(distance: $0) }
        let manager = StubHealthKitManager(weeklyResult: .success(workouts))
        let client = makeSUT(manager: manager)

        // When
        let result = try await client.fetchRunningDataBetweenDates(Date.now, Date.now)

        // Then
        #expect(result.count == expectedCount)
        #expect(result.map(\.distance) == expectedDistances)
    }

    @Test("weekly: 매니저가 빈 배열을 반환하면 빈 배열을 반환한다")
    // TC: hkclient-weekly-empty
    func fetchWeekly_returnsEmpty_whenManagerReturnsEmpty() async throws {
        // Given
        let manager = StubHealthKitManager(weeklyResult: .success([]))
        let client = makeSUT(manager: manager)

        // When
        let result = try await client.fetchRunningDataBetweenDates(Date.now, Date.now)

        // Then
        #expect(result.isEmpty)
    }

    @Test("weekly: 매니저가 에러를 던지면 동일한 에러를 재전파한다")
    // TC: hkclient-weekly-throws
    func fetchWeekly_throwsError_whenManagerThrows() async {
        // Given
        let manager = StubHealthKitManager(weeklyResult: .failure(HealthKitError.dataNotFound))
        let client = makeSUT(manager: manager)

        // When / Then
        await #expect(throws: HealthKitError.dataNotFound) {
            try await client.fetchRunningDataBetweenDates(Date.now, Date.now)
        }
    }

    @Test("weekly: 전달받은 날짜(역순 포함)를 그대로 매니저에 전달한다")
    // TC: hkclient-weekly-forwardsDates
    func fetchWeekly_forwardsDates_toManager() async throws {
        // Given
        let startDate = Date.now
        let endDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
        let manager = StubHealthKitManager()
        let client = makeSUT(manager: manager)

        // When
        _ = try await client.fetchRunningDataBetweenDates(startDate, endDate)

        // Then
        let capturedDates = manager.capturedWeeklyDates
        #expect(capturedDates?.0 == startDate)
        #expect(capturedDates?.1 == endDate)
    }

    @Test("weekly: fetchWeeklyRunningData만 호출하고 fetchDetailedRunningData는 호출하지 않는다")
    // TC: hkclient-weekly-callsCorrectMethod
    func fetchWeekly_callsOnlyWeeklyMethod() async throws {
        // Given
        let manager = StubHealthKitManager(
            weeklyResult: .success([makeHealthKitWorkout(distance: 5.0)]),
            detailedResult: .success(makeHealthKitWorkout(distance: 10.0))
        )
        let client = makeSUT(manager: manager)

        // When
        _ = try await client.fetchRunningDataBetweenDates(Date.now, Date.now)

        // Then
        #expect(manager.didCallWeekly == true)
        #expect(manager.didCallDetailed == false)
    }

    // MARK: - fetchDetailedRunningData Tests

    @Test("detailed: 매니저가 반환한 데이터를 그대로 반환한다")
    // TC: hkclient-detailed-returnsData
    func fetchDetailed_returnsManagerData() async throws {
        // Given
        let expectedWorkout = makeHealthKitWorkout(distance: 7.5)
        let manager = StubHealthKitManager(detailedResult: .success(expectedWorkout))
        let client = makeSUT(manager: manager)

        // When
        let result = try await client.fetchDetailedRunningData(Date.now, Date.now)

        // Then
        #expect(result == expectedWorkout)
    }

    @Test("detailed: 매니저가 nil을 반환하면 nil을 반환한다")
    // TC: hkclient-detailed-returnsNil
    func fetchDetailed_returnsNil_whenManagerReturnsNil() async throws {
        // Given
        let manager = StubHealthKitManager(detailedResult: .success(nil))
        let client = makeSUT(manager: manager)

        // When
        let result = try await client.fetchDetailedRunningData(Date.now, Date.now)

        // Then
        #expect(result == nil)
    }

    @Test("detailed: 매니저가 에러를 던지면 동일한 에러를 재전파한다")
    // TC: hkclient-detailed-throws
    func fetchDetailed_throwsError_whenManagerThrows() async {
        // Given
        let manager = StubHealthKitManager(detailedResult: .failure(HealthKitError.notAvailable))
        let client = makeSUT(manager: manager)

        // When / Then
        await #expect(throws: HealthKitError.notAvailable) {
            try await client.fetchDetailedRunningData(Date.now, Date.now)
        }
    }

    @Test("detailed: 전달받은 날짜를 그대로 매니저에 전달한다")
    // TC: hkclient-detailed-forwardsDates
    func fetchDetailed_forwardsDates_toManager() async throws {
        // Given
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
        let endDate = Date.now
        let manager = StubHealthKitManager()
        let client = makeSUT(manager: manager)

        // When
        _ = try await client.fetchDetailedRunningData(startDate, endDate)

        // Then
        let capturedDates = manager.capturedDetailedDates
        #expect(capturedDates?.0 == startDate)
        #expect(capturedDates?.1 == endDate)
    }

    @Test("detailed: fetchDetailedRunningData만 호출하고 fetchWeeklyRunningData는 호출하지 않는다")
    // TC: hkclient-detailed-callsCorrectMethod
    func fetchDetailed_callsOnlyDetailedMethod() async throws {
        // Given
        let manager = StubHealthKitManager(
            weeklyResult: .success([makeHealthKitWorkout(distance: 5.0)]),
            detailedResult: .success(makeHealthKitWorkout(distance: 10.0))
        )
        let client = makeSUT(manager: manager)

        // When
        _ = try await client.fetchDetailedRunningData(Date.now, Date.now)

        // Then
        #expect(manager.didCallDetailed == true)
        #expect(manager.didCallWeekly == false)
    }
}

// MARK: - Test Helpers

private extension HealthKitClientTests {
    /// `HealthKitClient.live(manager:)`로 SUT를 생성한다.
    /// 실제 `liveValue`와 동일한 배선(delegation) 로직을 태우기 위해
    /// 고정 클로저 대신 `HealthKitClient.live`를 재사용한다.
    func makeSUT(manager: StubHealthKitManager) -> HealthKitClient {
        .live(manager: manager)
    }

    /// HealthKitWorkout 생성 헬퍼
    func makeHealthKitWorkout(
        distance: Double = 5.0,
        startDate: Date = .now
    ) -> HealthKitWorkout {
        HealthKitWorkout(
            distance: distance,
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
            startDate: startDate,
            endDate: startDate.addingTimeInterval(1800)
        )
    }
}

// MARK: - Stubs

/// `fetchRunningDataBetweenDates`/`fetchDetailedRunningData`가 실제로 주입된 매니저에
/// 위임하는지 검증하기 위한 테스트 전용 fake.
private final class StubHealthKitManager: HealthKitManagerProtocol, @unchecked Sendable {
    private let weeklyResult: Result<[HealthKitWorkout], Error>
    private let detailedResult: Result<HealthKitWorkout?, Error>

    var capturedWeeklyDates: (Date, Date)?
    var capturedDetailedDates: (Date, Date)?
    var didCallWeekly = false
    var didCallDetailed = false

    init(
        weeklyResult: Result<[HealthKitWorkout], Error> = .success([]),
        detailedResult: Result<HealthKitWorkout?, Error> = .success(nil)
    ) {
        self.weeklyResult = weeklyResult
        self.detailedResult = detailedResult
    }

    func ensureAuthorizationIfNeeded() async throws {
        Issue.record("unexpected call: ensureAuthorizationIfNeeded")
    }

    func fetchRunningData(for date: Date) async throws -> [HealthKitWorkout] {
        Issue.record("unexpected call: fetchRunningData(for:)")
        return []
    }

    func fetchWeeklyRunningData(from startDate: Date, to endDate: Date) async throws -> [HealthKitWorkout] {
        didCallWeekly = true
        capturedWeeklyDates = (startDate, endDate)
        return try weeklyResult.get()
    }

    func fetchDetailedRunningData(from startDate: Date, to endDate: Date) async throws -> HealthKitWorkout? {
        didCallDetailed = true
        capturedDetailedDates = (startDate, endDate)
        return try detailedResult.get()
    }
}
