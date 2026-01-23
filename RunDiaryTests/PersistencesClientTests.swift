//
//  PersistencesClientTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/23/25.
//

import Foundation
import Models
import Testing

@testable import RunDiary

@Suite("PersistencesClient")
struct PersistencesClientTests {

    // MARK: - Test Helpers

    private func makeYearMonthDay(year: Int = 2025, month: Int = 11, day: Int = 27) -> YearMonthDay {
        YearMonthDay(year: year, month: month, day: day)
    }

    private func makeDate(year: Int = 2025, month: Int = 11, day: Int = 27, hour: Int = 9, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    private func makeTestClient(
        fetch: @escaping @MainActor @Sendable (Date) async throws -> Diary? = { _ in nil },
        fetchRecords: @escaping @MainActor @Sendable (Date, Date) async throws -> [Diary] = { _, _ in [] },
        save: @escaping @MainActor @Sendable (Diary) async throws -> Void = { _ in },
        update: @escaping @MainActor @Sendable (UUID, YearMonthDay?, Double?, TimeInterval?, String?, Int?, Int?, [PainArea]?, RunninStyle?, String?, String?, WeatherData?, DifficultyLevel?, Data?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Date?, Date?) async throws -> Void = { _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ in },
        delete: @escaping @MainActor @Sendable (Diary) async throws -> Void = { _ in }
    ) -> PersistencesClient {
        PersistencesClient(
            fetch: fetch,
            fetchRecords: fetchRecords,
            save: save,
            update: update,
            delete: delete
        )
    }

    // MARK: - fetch Tests

    @Test("fetch: 특정 날짜의 기록 조회 성공")
    @MainActor
    func fetchReturnsRecordForDate() async throws {
        let testDate = makeYearMonthDay()
        let startTime = makeDate()
        let endTime = startTime.addingTimeInterval(1800)

        let expectedRecord = Diary(
            workout: HealthKitWorkout(
                distance: 5.2,
                duration: 1800,
                averagePace: "5'46\"",
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
                startDate: startTime,
                endDate: endTime
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        let client = makeTestClient(
            fetch: { date in
                #expect(Calendar.current.isDate(date, inSameDayAs: testDate.toDate()))
                return expectedRecord
            }
        )

        let result = try await client.fetch(testDate.toDate())

        #expect(result != nil)
        #expect(result?.id == expectedRecord.id)
        #expect(result?.workout.yearMonthDay == testDate)
        #expect(result?.workout.distance == 5.2)
        #expect(result?.workout.duration == 1800)
        #expect(result?.workout.averagePace == "5'46\"")
        #expect(result?.workout.averageHeartRate == 150)
        #expect(result?.workout.averageCadence == 170)
        #expect(result?.runningStyle == .midfoot)
    }

    @Test("fetch: 기록이 없을 때 nil 반환")
    @MainActor
    func fetchReturnsNilWhenNoRecord() async throws {
        let testDate = makeYearMonthDay()

        let client = makeTestClient(
            fetch: { date in
                #expect(Calendar.current.isDate(date, inSameDayAs: testDate.toDate()))
                return nil
            }
        )

        let result = try await client.fetch(testDate.toDate())
        #expect(result == nil)
    }

    @Test("fetch: 에러 발생 시 throw")
    @MainActor
    func fetchThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case fetchFailed
        }

        let client = makeTestClient(
            fetch: { _ in
                throw TestError.fetchFailed
            }
        )

        await #expect(throws: TestError.fetchFailed) {
            try await client.fetch(Date.now)
        }
    }

    // MARK: - fetchRecords Tests

    @Test("fetchRecords: 날짜 범위의 여러 기록 조회")
    @MainActor
    func fetchRecordsReturnsMultipleRecords() async throws {
        let startDate = makeDate()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        let day1 = makeYearMonthDay()
        let day2 = makeYearMonthDay(day: 30)

        let time1Start = makeDate()
        let time1End = time1Start.addingTimeInterval(1500)
        let time2Start = makeDate(day: 30)
        let time2End = time2Start.addingTimeInterval(2250)

        let expectedRecords = [
            Diary(
                workout: HealthKitWorkout(
                    distance: 5.0,
                    duration: 1500,
                    averagePace: "5'00\"",
                    averageHeartRate: 145,
                    averageCadence: 165,
                    activeEnergyBurned: 0,
                    runningVerticalOscillation: 0,
                    runningGroundContactTime: 0,
                    walkingStepLength: 0,
                    restingHeartRate: 0,
                    runningPower: 0,
                    runningStrideLength: 0,
                    heartRateRecoveryOneMinute: 0,
                    routeData: nil,
                    startDate: time1Start,
                    endDate: time1End
                ),
                painAreas: [],
                runningStyle: .forefoot,
                memo: nil
            ),
            Diary(
                workout: HealthKitWorkout(
                    distance: 7.5,
                    duration: 2250,
                    averagePace: "5'00\"",
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
                    startDate: time2Start,
                    endDate: time2End
                ),
                painAreas: [],
                runningStyle: .midfoot,
                memo: nil
            ),
        ]

        let client = makeTestClient(
            fetchRecords: { start, end in
                #expect(Calendar.current.isDate(start, inSameDayAs: startDate))
                #expect(Calendar.current.isDate(end, inSameDayAs: endDate))
                return expectedRecords
            }
        )

        let result = try await client.fetchRecords(startDate, endDate)

        #expect(result.count == 2)
        #expect(result[0].workout.distance == 5.0)
        #expect(result[0].runningStyle == .forefoot)
        #expect(result[1].workout.distance == 7.5)
        #expect(result[1].runningStyle == .midfoot)
    }

    @Test("fetchRecords: 기록이 없을 때 빈 배열 반환")
    @MainActor
    func fetchRecordsReturnsEmptyArray() async throws {
        let startDate = makeDate()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        let client = makeTestClient()

        let result = try await client.fetchRecords(startDate, endDate)
        #expect(result.isEmpty)
    }

    @Test("fetchRecords: 에러 발생 시 throw")
    @MainActor
    func fetchRecordsThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case fetchFailed
        }

        let client = makeTestClient(
            fetchRecords: { _, _ in
                throw TestError.fetchFailed
            }
        )

        let startDate = makeDate()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        await #expect(throws: TestError.fetchFailed) {
            try await client.fetchRecords(startDate, endDate)
        }
    }

    // MARK: - save Tests

    @Test("save: 새 기록 저장 성공")
    @MainActor
    func saveStoresNewRecord() async throws {
        let yearMonthDay = makeYearMonthDay()
        let startTime = makeDate()
        let endTime = startTime.addingTimeInterval(3000)

        let newRecord = Diary(
            workout: HealthKitWorkout(
                distance: 10.0,
                duration: 3000,
                averagePace: "5'00\"",
                averageHeartRate: 160,
                averageCadence: 180,
                activeEnergyBurned: 0,
                runningVerticalOscillation: 0,
                runningGroundContactTime: 0,
                walkingStepLength: 0,
                restingHeartRate: 0,
                runningPower: 0,
                runningStrideLength: 0,
                heartRateRecoveryOneMinute: 0,
                routeData: nil,
                startDate: startTime,
                endDate: endTime
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        var savedRecord: Diary?

        let client = makeTestClient(
            save: { record in
                savedRecord = record
            }
        )

        try await client.save(newRecord)

        #expect(savedRecord != nil)
        #expect(savedRecord?.id == newRecord.id)
        #expect(savedRecord?.workout.distance == 10.0)
        #expect(savedRecord?.workout.duration == 3000)
        #expect(savedRecord?.workout.averageHeartRate == 160)
    }

    @Test("save: 에러 발생 시 throw")
    @MainActor
    func saveThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case saveFailed
        }

        let client = makeTestClient(
            save: { _ in
                throw TestError.saveFailed
            }
        )

        let yearMonthDay = makeYearMonthDay()
        let startTime = makeDate()
        let newRecord = Diary(
            workout: HealthKitWorkout(
                distance: 5.0,
                duration: 1500,
                averagePace: "5'00\"",
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
                startDate: startTime,
                endDate: startTime.addingTimeInterval(1500)
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        await #expect(throws: TestError.saveFailed) {
            try await client.save(newRecord)
        }
    }

    // MARK: - update Tests

    @Test("update: 기존 기록 업데이트 성공")
    @MainActor
    func updateModifiesExistingRecord() async throws {
        let recordId = UUID()
        let yearMonthDay = makeYearMonthDay()
        let startTime = makeDate()
        let endTime = startTime.addingTimeInterval(1800)

        var updatedRecordId: UUID?
        var updatedDistance: Double?
        var updatedMemo: String?

        let client = makeTestClient(
            update: { id, _, distance, _, _, _, _, _, _, memo, _, _, _, _, _, _, _, _, _, _, _, _, _, _ in
                updatedRecordId = id
                updatedDistance = distance
                updatedMemo = memo
            }
        )

        try await client.updateRecord(
            recordId: recordId,
            distance: 6.0,
            memo: "updated"
        )

        #expect(updatedRecordId == recordId)
        #expect(updatedDistance == 6.0)
        #expect(updatedMemo == "updated")
    }

    @Test("update: 에러 발생 시 throw")
    @MainActor
    func updateThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case updateFailed
        }

        let client = makeTestClient(
            update: { _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ in
                throw TestError.updateFailed
            }
        )

        let recordId = UUID()

        await #expect(throws: TestError.updateFailed) {
            try await client.updateRecord(recordId: recordId, distance: 5.0)
        }
    }

    // MARK: - delete Tests

    @Test("delete: 기록 삭제 성공")
    @MainActor
    func deleteRemovesRecord() async throws {
        let yearMonthDay = makeYearMonthDay()
        let startTime = makeDate()
        let endTime = startTime.addingTimeInterval(1200)

        let recordToDelete = Diary(
            workout: HealthKitWorkout(
                distance: 3.0,
                duration: 1200,
                averagePace: "6'40\"",
                averageHeartRate: 140,
                averageCadence: 160,
                activeEnergyBurned: 0,
                runningVerticalOscillation: 0,
                runningGroundContactTime: 0,
                walkingStepLength: 0,
                restingHeartRate: 0,
                runningPower: 0,
                runningStrideLength: 0,
                heartRateRecoveryOneMinute: 0,
                routeData: nil,
                startDate: startTime,
                endDate: endTime
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        var deletedRecord: Diary?

        let client = makeTestClient(
            delete: { record in
                deletedRecord = record
            }
        )

        try await client.delete(recordToDelete)

        #expect(deletedRecord != nil)
        #expect(deletedRecord?.id == recordToDelete.id)
        #expect(deletedRecord?.workout.distance == 3.0)
    }

    @Test("delete: 에러 발생 시 throw")
    @MainActor
    func deleteThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case deleteFailed
        }

        let client = makeTestClient(
            delete: { _ in
                throw TestError.deleteFailed
            }
        )

        let yearMonthDay = makeYearMonthDay()
        let startTime = makeDate()
        let record = Diary(
            id: UUID(),
            workout: HealthKitWorkout(
                distance: 5.0,
                duration: 1500,
                averagePace: "5'00\"",
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
                startDate: startTime,
                endDate: startTime.addingTimeInterval(1500)
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        await #expect(throws: TestError.deleteFailed) {
            try await client.delete(record)
        }
    }

    // MARK: - Integration Tests

    @Test("통합: fetch -> update -> fetch 흐름")
    @MainActor
    func integrationFetchUpdateFetch() async throws {
        let testDate = makeDate()
        let originalId = UUID()
        let yearMonthDay = makeYearMonthDay()
        let startTime = makeDate()
        let endTime = startTime.addingTimeInterval(1500)

        var storage: [UUID: Diary] = [
            originalId: Diary(
                id: originalId,
                workout: HealthKitWorkout(
                    distance: 5.0,
                    duration: 1500,
                    averagePace: "5'00\"",
                    averageHeartRate: 145,
                    averageCadence: 165,
                    activeEnergyBurned: 0,
                    runningVerticalOscillation: 0,
                    runningGroundContactTime: 0,
                    walkingStepLength: 0,
                    restingHeartRate: 0,
                    runningPower: 0,
                    runningStrideLength: 0,
                    heartRateRecoveryOneMinute: 0,
                    routeData: nil,
                    startDate: startTime,
                    endDate: endTime
                ),
                painAreas: [],
                runningStyle: .forefoot,
                memo: nil
            )
        ]

        let client = makeTestClient(
            fetch: { date in
                storage.values.first { Calendar.current.isDate($0.workout.yearMonthDay.toDate(), inSameDayAs: date) }
            },
            fetchRecords: { _, _ in Array(storage.values) },
            save: { record in
                storage[record.id] = record
            },
            update: { recordId, date, distance, duration, averagePace, averageHeartRate, averageCadence, painAreas, runningStyle, memo, shoes, weather, difficultyLevel, routeData, activeEnergyBurned, runningVerticalOscillation, runningGroundContactTime, walkingStepLength, restingHeartRate, runningPower, runningStrideLength, heartRateRecoveryOneMinute, startTimeParam, endTimeParam in
                guard var existingRecord = storage[recordId] else { return }
                // Update only non-nil values
                if let distance {
                    let oldWorkout = existingRecord.workout
                    let newWorkout = HealthKitWorkout(
                        distance: distance,
                        duration: oldWorkout.duration,
                        averagePace: oldWorkout.averagePace,
                        averageHeartRate: oldWorkout.averageHeartRate,
                        averageCadence: oldWorkout.averageCadence,
                        activeEnergyBurned: oldWorkout.activeEnergyBurned,
                        runningVerticalOscillation: oldWorkout.runningVerticalOscillation,
                        runningGroundContactTime: oldWorkout.runningGroundContactTime,
                        walkingStepLength: oldWorkout.walkingStepLength,
                        restingHeartRate: oldWorkout.restingHeartRate,
                        runningPower: oldWorkout.runningPower,
                        runningStrideLength: oldWorkout.runningStrideLength,
                        heartRateRecoveryOneMinute: oldWorkout.heartRateRecoveryOneMinute,
                        routeData: oldWorkout.routeData,
                        startDate: oldWorkout.startTime,
                        endDate: oldWorkout.endTime
                    )
                    existingRecord = Diary(
                        id: existingRecord.id,
                        workout: newWorkout,
                        painAreas: existingRecord.painAreas,
                        runningStyle: existingRecord.runningStyle,
                        memo: existingRecord.memo,
                        shoes: existingRecord.shoes,
                        weather: existingRecord.weather,
                        difficultyLevel: existingRecord.difficultyLevel
                    )
                }
                storage[recordId] = existingRecord
            },
            delete: { record in
                storage.removeValue(forKey: record.id)
            }
        )

        let fetched = try await client.fetch(testDate)
        #expect(fetched != nil)
        #expect(fetched?.workout.distance == 5.0)

        try await client.updateRecord(recordId: originalId, distance: 7.5)

        let fetchedAgain = try await client.fetch(testDate)
        #expect(fetchedAgain?.workout.distance == 7.5)
    }

    @Test("통합: save -> fetchRecords 흐름")
    @MainActor
    func integrationSaveFetchRecords() async throws {
        let startDate = makeDate()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        var storage: [UUID: Diary] = [:]

        let day1 = makeYearMonthDay()
        let day2 = makeYearMonthDay(day: 30)
        let time1Start = makeDate()
        let time1End = time1Start.addingTimeInterval(1500)
        let time2Start = makeDate(day: 30)
        let time2End = time2Start.addingTimeInterval(2100)

        let client = makeTestClient(
            fetch: { date in
                storage.values.first { Calendar.current.isDate($0.workout.yearMonthDay.toDate(), inSameDayAs: date) }
            },
            fetchRecords: { start, end in
                storage.values.filter { $0.workout.startTime >= start && $0.workout.startTime <= end }.sorted { $0.workout.startTime < $1.workout.startTime }
            },
            save: { record in
                storage[record.id] = record
            }
        )

        let record1 = Diary(
            workout: HealthKitWorkout(
                distance: 5.0,
                duration: 1500,
                averagePace: "5'00\"",
                averageHeartRate: 145,
                averageCadence: 165,
                activeEnergyBurned: 0,
                runningVerticalOscillation: 0,
                runningGroundContactTime: 0,
                walkingStepLength: 0,
                restingHeartRate: 0,
                runningPower: 0,
                runningStrideLength: 0,
                heartRateRecoveryOneMinute: 0,
                routeData: nil,
                startDate: time1Start,
                endDate: time1End
            ),
            painAreas: [],
            runningStyle: .forefoot,
            memo: nil
        )

        let record2 = Diary(
            workout: HealthKitWorkout(
                distance: 7.0,
                duration: 2100,
                averagePace: "5'00\"",
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
                startDate: time2Start,
                endDate: time2End
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        try await client.save(record1)
        try await client.save(record2)

        let records = try await client.fetchRecords(startDate, endDate)
        #expect(records.count == 2)
        #expect(records[0].workout.distance == 5.0)
        #expect(records[1].workout.distance == 7.0)
    }

    @Test("통합: save -> delete -> fetch 흐름")
    @MainActor
    func integrationSaveDeleteFetch() async throws {
        let testDate = makeDate()
        var storage: [UUID: Diary] = [:]

        let yearMonthDay = makeYearMonthDay()
        let startTime = makeDate()
        let endTime = startTime.addingTimeInterval(1800)

        let client = makeTestClient(
            fetch: { date in
                storage.values.first { Calendar.current.isDate($0.workout.yearMonthDay.toDate(), inSameDayAs: date) }
            },
            fetchRecords: { _, _ in Array(storage.values) },
            save: { record in
                storage[record.id] = record
            },
            delete: { record in
                storage.removeValue(forKey: record.id)
            }
        )

        let newRecord = Diary(
            workout: HealthKitWorkout(
                distance: 6.0,
                duration: 1800,
                averagePace: "5'00\"",
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
                startDate: startTime,
                endDate: endTime
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        try await client.save(newRecord)

        let fetched = try await client.fetch(testDate)
        #expect(fetched != nil)

        try await client.delete(fetched!)

        let fetchedAgain = try await client.fetch(testDate)
        #expect(fetchedAgain == nil)
    }
}
