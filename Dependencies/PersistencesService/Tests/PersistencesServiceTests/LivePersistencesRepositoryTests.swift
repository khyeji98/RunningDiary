//
//  LivePersistencesRepositoryTests.swift
//  PersistencesService
//
//  Created by Claude on 1/19/26.
//

import Foundation
import Models
import SwiftData
import Testing

@testable import PersistencesService

@MainActor
@Suite("LivePersistencesRepository")
struct LivePersistencesRepositoryTests {

    // MARK: - Test Helpers

    private func makeTestRepository() throws -> LivePersistencesRepository {
        let schema = Schema([RunningRecordPersistenceModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        return LivePersistencesRepository(modelContext: context)
    }

    private func makeYearMonthDay(year: Int = 2025, month: Int = 11, day: Int = 27) -> YearMonthDay {
        YearMonthDay(year: year, month: month, day: day)
    }

    private func makeDiary(
        id: UUID = UUID(),
        yearMonthDay: YearMonthDay? = nil,
        distance: Double = 5.0,
        duration: TimeInterval = 1800,
        averagePace: String = "6'00\"",
        averageHeartRate: Int = 150,
        averageCadence: Int = 170,
        painAreas: [PainArea] = [],
        runningStyle: RunninStyle? = .midfoot,
        condition: RunningCondition = RunningCondition(),
        shoes: String? = nil,
        weather: WeatherData? = nil,
        difficultyLevel: DifficultyLevel? = nil,
        routeData: Data? = nil,
        activeEnergyBurned: Double? = nil,
        runningVerticalOscillation: Double? = nil,
        runningGroundContactTime: Double? = nil,
        walkingStepLength: Double? = nil,
        startOffset: TimeInterval = 0
    ) -> Diary {
        let ymd = yearMonthDay ?? makeYearMonthDay()
        let startTime = ymd.toDate().addingTimeInterval(startOffset)
        return Diary(
            id: id,
            yearMonthDay: ymd,
            distanceInKilometers: distance,
            durationInSeconds: duration,
            averagePace: averagePace,
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            painAreas: painAreas,
            runningStyle: runningStyle,
            condition: condition,
            shoes: shoes,
            weather: weather,
            difficultyLevel: difficultyLevel,
            routeData: routeData,
            activeEnergyBurned: activeEnergyBurned,
            runningVerticalOscillation: runningVerticalOscillation,
            runningGroundContactTime: runningGroundContactTime,
            walkingStepLength: walkingStepLength,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(duration)
        )
    }

    // MARK: - fetchRunningRecord Tests

    @Test("특정 날짜에 기록이 있을 때 Diary 반환")
    func fetchRunningRecord_returnsRecord_whenExists() async throws {
        // Given
        let repository = try makeTestRepository()
        let testDate = makeYearMonthDay()
        let expectedDiary = makeDiary(yearMonthDay: testDate, distance: 7.5)

        try await repository.saveRunningRecord(expectedDiary)

        // When
        let result = try await repository.fetchRunningRecord(for: testDate.toDate())

        // Then
        #expect(result != nil)
        #expect(result?.id == expectedDiary.id)
        #expect(result?.distanceInKilometers == 7.5)
        #expect(result?.yearMonthDay == testDate)
    }

    @Test("기록이 없는 날짜 조회 시 nil 반환")
    func fetchRunningRecord_returnsNil_whenNoRecord() async throws {
        // Given
        let repository = try makeTestRepository()
        let testDate = makeYearMonthDay(year: 2025, month: 12, day: 25)

        // When
        let result = try await repository.fetchRunningRecord(for: testDate.toDate())

        // Then
        #expect(result == nil)
    }

    // MARK: - fetchRunningRecords Tests

    @Test("날짜 범위 내 여러 기록 조회")
    func fetchRunningRecords_returnsMultipleRecords_withinDateRange() async throws {
        // Given
        let repository = try makeTestRepository()

        let day1 = makeYearMonthDay(year: 2025, month: 11, day: 1)
        let day2 = makeYearMonthDay(year: 2025, month: 11, day: 15)
        let day3 = makeYearMonthDay(year: 2025, month: 11, day: 30)

        let diary1 = makeDiary(yearMonthDay: day1, distance: 5.0)
        let diary2 = makeDiary(yearMonthDay: day2, distance: 7.0)
        let diary3 = makeDiary(yearMonthDay: day3, distance: 10.0)

        try await repository.saveRunningRecord(diary1)
        try await repository.saveRunningRecord(diary2)
        try await repository.saveRunningRecord(diary3)

        let startDate = day1.toDate()
        let endDate = day3.toDate()

        // When
        let results = try await repository.fetchRunningRecords(from: startDate, to: endDate)

        // Then
        #expect(results.count == 3)
        let distances = results.map { $0.distanceInKilometers }.sorted()
        #expect(distances == [5.0, 7.0, 10.0])
    }

    @Test("빈 범위 조회 시 빈 배열 반환")
    func fetchRunningRecords_returnsEmptyArray_whenNoRecordsInRange() async throws {
        // Given
        let repository = try makeTestRepository()
        let startDate = makeYearMonthDay(year: 2020, month: 1, day: 1).toDate()
        let endDate = makeYearMonthDay(year: 2020, month: 12, day: 31).toDate()

        // When
        let results = try await repository.fetchRunningRecords(from: startDate, to: endDate)

        // Then
        #expect(results.isEmpty)
    }

    // MARK: - saveRunningRecord Tests

    @Test("새 기록 저장 성공")
    func saveRunningRecord_savesNewRecord() async throws {
        // Given
        let repository = try makeTestRepository()
        let testDate = makeYearMonthDay()
        let newDiary = makeDiary(
            yearMonthDay: testDate,
            distance: 10.0,
            duration: 3600,
            averageHeartRate: 160
        )

        // When
        try await repository.saveRunningRecord(newDiary)

        // Then
        let fetched = try await repository.fetchRunningRecord(for: testDate.toDate())
        #expect(fetched != nil)
        #expect(fetched?.id == newDiary.id)
        #expect(fetched?.distanceInKilometers == 10.0)
        #expect(fetched?.durationInSeconds == 3600)
        #expect(fetched?.averageHeartRate == 160)
    }

    // MARK: - updateRunningRecord Tests

    @Test("기존 기록 업데이트 성공")
    func updateRunningRecord_updatesExistingRecord() async throws {
        // Given
        let repository = try makeTestRepository()
        let recordId = UUID()
        let testDate = makeYearMonthDay()
        let originalDiary = makeDiary(id: recordId, yearMonthDay: testDate, distance: 5.0)

        try await repository.saveRunningRecord(originalDiary)

        let expectedDistance = 8.5

        // When
        try await repository.updateRunningRecord(
            recordId: recordId,
            date: nil,
            distance: expectedDistance,
            duration: nil,
            averagePace: nil,
            averageHeartRate: nil,
            averageCadence: nil,
            painAreas: nil,
            runningStyle: nil,
            condition: nil,
            shoes: nil,
            weather: nil,
            difficultyLevel: nil,
            routeData: nil,
            activeEnergyBurned: nil,
            runningVerticalOscillation: nil,
            runningGroundContactTime: nil,
            walkingStepLength: nil,
            restingHeartRate: nil,
            runningPower: nil,
            runningStrideLength: nil,
            heartRateRecoveryOneMinute: nil,
            startTime: nil,
            endTime: nil
        )

        // Then
        let fetched = try await repository.fetchRunningRecord(for: testDate.toDate())
        #expect(fetched?.distanceInKilometers == expectedDistance)
    }

    @Test("존재하지 않는 recordId로 업데이트 시 notFound 에러")
    func updateRunningRecord_throwsNotFound_whenRecordDoesNotExist() async throws {
        // Given
        let repository = try makeTestRepository()
        let nonExistentId = UUID()

        // When & Then
        await #expect(throws: PersistencesError.notFound) {
            try await repository.updateRunningRecord(
                recordId: nonExistentId,
                date: nil,
                distance: 10.0,
                duration: nil,
                averagePace: nil,
                averageHeartRate: nil,
                averageCadence: nil,
                painAreas: nil,
                runningStyle: nil,
                condition: nil,
                shoes: nil,
                weather: nil,
                difficultyLevel: nil,
                routeData: nil,
                activeEnergyBurned: nil,
                runningVerticalOscillation: nil,
                runningGroundContactTime: nil,
                walkingStepLength: nil,
                restingHeartRate: nil,
                runningPower: nil,
                runningStrideLength: nil,
                heartRateRecoveryOneMinute: nil,
                startTime: nil,
                endTime: nil
            )
        }
    }

    @Test("nil이 아닌 필드만 부분 업데이트")
    func updateRunningRecord_updatesOnlyNonNilFields() async throws {
        // Given
        let repository = try makeTestRepository()
        let recordId = UUID()
        let testDate = makeYearMonthDay()
        let originalCondition = RunningCondition(sleep: 7, memo: "Original memo")
        let originalDiary = makeDiary(
            id: recordId,
            yearMonthDay: testDate,
            distance: 5.0,
            duration: 1800,
            averageHeartRate: 150,
            averageCadence: 170,
            condition: originalCondition,
            shoes: "Nike"
        )

        try await repository.saveRunningRecord(originalDiary)

        let expectedDistance = 6.5
        let expectedShoes = "Adidas"

        // When - 거리와 신발만 업데이트
        try await repository.updateRunningRecord(
            recordId: recordId,
            date: nil,
            distance: expectedDistance,
            duration: nil,
            averagePace: nil,
            averageHeartRate: nil,
            averageCadence: nil,
            painAreas: nil,
            runningStyle: nil,
            condition: nil,
            shoes: expectedShoes,
            weather: nil,
            difficultyLevel: nil,
            routeData: nil,
            activeEnergyBurned: nil,
            runningVerticalOscillation: nil,
            runningGroundContactTime: nil,
            walkingStepLength: nil,
            restingHeartRate: nil,
            runningPower: nil,
            runningStrideLength: nil,
            heartRateRecoveryOneMinute: nil,
            startTime: nil,
            endTime: nil
        )

        // Then - 업데이트된 필드 확인
        let fetched = try await repository.fetchRunningRecord(for: testDate.toDate())
        #expect(fetched?.distanceInKilometers == expectedDistance)
        #expect(fetched?.shoes == expectedShoes)

        // 업데이트하지 않은 필드는 원래 값 유지
        #expect(fetched?.durationInSeconds == 1800)
        #expect(fetched?.averageHeartRate == 150)
        #expect(fetched?.averageCadence == 170)
    }

    // MARK: - deleteRunningRecord Tests

    @Test("기록 삭제 성공")
    func deleteRunningRecord_deletesRecord() async throws {
        // Given
        let repository = try makeTestRepository()
        let testDate = makeYearMonthDay()
        let diary = makeDiary(yearMonthDay: testDate, distance: 5.0)

        try await repository.saveRunningRecord(diary)

        // 저장 확인
        let beforeDelete = try await repository.fetchRunningRecord(for: testDate.toDate())
        #expect(beforeDelete != nil)

        // When
        try await repository.deleteRunningRecord(diary)

        // Then
        let afterDelete = try await repository.fetchRunningRecord(for: testDate.toDate())
        #expect(afterDelete == nil)
    }

    @Test("존재하지 않는 기록 삭제 시 notFound 에러")
    func deleteRunningRecord_throwsNotFound_whenRecordDoesNotExist() async throws {
        // Given
        let repository = try makeTestRepository()
        let nonExistentDiary = makeDiary(yearMonthDay: makeYearMonthDay())

        // When & Then
        await #expect(throws: PersistencesError.notFound) {
            try await repository.deleteRunningRecord(nonExistentDiary)
        }
    }
}
