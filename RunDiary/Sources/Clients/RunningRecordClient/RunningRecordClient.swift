//
//  RunningRecordClient.swift
//  RunDiary
//
//  Created by Claude on 11/29/25.
//

import ComposableArchitecture
import Foundation
import Models
import PersistencesService

@DependencyClient
struct RunningRecordClient {
    var fetchData: @MainActor @Sendable (_ from: YearMonthDay, _ to: YearMonthDay) async throws -> [YearMonthDay: DailyRecord]
    var saveRecord: @MainActor @Sendable (_ record: Diary) async throws -> Void
    var updateRecord: @MainActor @Sendable (_ record: Diary) async throws -> Void
}

extension RunningRecordClient: DependencyKey {
    static let liveValue: RunningRecordClient = RunningRecordClient(
        fetchData: { from, to in
            @Dependency(\.healthKitClient) var healthKitClient
            @Dependency(\.persistencesClient) var persistencesClient

            try await healthKitClient.ensureAuthorizationIfNeeded()

            // 1. Fetch (캐싱은 Repository가 담당)
            let healthKitWorkouts = try await healthKitClient.fetchRunningDataBetweenDates(
                from.toDate(),
                to.toDate()
            )
            let savedRecords = try await persistencesClient.fetchRecords(
                from.toDate(),
                to.toDate()
            )

            // 2. Migration: 새로운 HealthKit 필드가 nil인 기존 레코드 업데이트
            let migrationOccurred = await Self.migrateHealthKitMetricsIfNeeded(
                savedRecords: savedRecords,
                healthKitWorkouts: healthKitWorkouts,
                persistencesClient: persistencesClient
            )

            // 3. 마이그레이션 발생 시 다시 fetch (struct이므로 DB 변경이 반영되지 않음)
            let finalRecords = migrationOccurred
                ? try await persistencesClient.fetchRecords(from.toDate(), to.toDate())
                : savedRecords

            // 4. Build (비즈니스 로직은 Client가 담당)
            return Self.merge(
                healthKitWorkouts: healthKitWorkouts,
                savedRecords: finalRecords,
                from: from,
                to: to
            )
        },
        saveRecord: { record in
            @Dependency(\.persistencesClient) var persistencesClient
            try await persistencesClient.save(record)
        },
        updateRecord: { record in
            @Dependency(\.persistencesClient) var persistencesClient
            try await persistencesClient.updateRecord(
                recordId: record.id,
                date: record.yearMonthDay,
                distance: record.distanceInKilometers,
                duration: record.durationInSeconds,
                averagePace: record.averagePace,
                averageHeartRate: record.averageHeartRate,
                averageCadence: record.averageCadence,
                painAreas: record.painAreas,
                runningStyle: record.runningStyle,
                condition: record.condition,
                shoes: record.shoes,
                weather: record.weather,
                difficultyLevel: record.difficultyLevel,
                routeData: record.routeData,
                activeEnergyBurned: record.activeEnergyBurned,
                runningVerticalOscillation: record.runningVerticalOscillation,
                runningGroundContactTime: record.runningGroundContactTime,
                walkingStepLength: record.walkingStepLength,
                hasMap: record.hasMap,
                startTime: record.startTime,
                endTime: record.endTime
            )
        }
    )

    static let testValue = RunningRecordClient(
        fetchData: unimplemented("\(Self.self).fetchData"),
        saveRecord: unimplemented("\(Self.self).saveRecord"),
        updateRecord: unimplemented("\(Self.self).updateRecord")
    )

    static let previewValue = RunningRecordClient(
        fetchData: { from, to in
            let dates = Self.generateDateRange(from: from, to: to)
            return Dictionary(uniqueKeysWithValues: dates.map { date in
                (date, DailyRecord(
                    yearMonthDay: date,
                    healthKitWorkouts: [],
                    savedRecords: []
                ))
            })
        },
        saveRecord: { _ in },
        updateRecord: { _ in }
    )

    private static func merge(
        healthKitWorkouts: [HealthKitWorkout],
        savedRecords: [Diary],
        from: YearMonthDay,
        to: YearMonthDay
    ) -> [YearMonthDay: DailyRecord] {
        // 1. 날짜별 그룹핑
        let groupedHK = Dictionary(grouping: healthKitWorkouts, by: \.yearMonthDay)
        let groupedRecords = Dictionary(grouping: savedRecords, by: \.yearMonthDay)

        // 2. 요청 범위의 모든 날짜 생성
        let allDates = Self.generateDateRange(from: from, to: to)

        // 3. 각 날짜별로 DailyRecord 생성
        var result: [YearMonthDay: DailyRecord] = [:]
        for date in allDates {
            let saved = groupedRecords[date] ?? []
            let healthKit = groupedHK[date] ?? []

            // 4. 중복 제거: SwiftData에 저장된 것은 HealthKit에서 제외
            let filteredHealthKit = healthKit.filter { workout in
                !saved.contains(where: { $0.startTime == workout.startTime })
            }

            result[date] = DailyRecord(
                yearMonthDay: date,
                healthKitWorkouts: filteredHealthKit.sorted { $0.startTime < $1.startTime },
                savedRecords: saved
            )
        }

        return result
    }

    private static func generateDateRange(from: YearMonthDay, to: YearMonthDay) -> [YearMonthDay] {
        var dates: [YearMonthDay] = []
        var current = from

        while current <= to {
            dates.append(current)
            guard let next = current.add(day: 1) else { break }
            current = next
        }

        return dates
    }

    /// 새로 추가된 HealthKit 메트릭 필드가 nil인 기존 SwiftData 레코드를 HealthKit 데이터로 마이그레이션
    /// - Returns: 마이그레이션이 발생했는지 여부
    @MainActor
    private static func migrateHealthKitMetricsIfNeeded(
        savedRecords: [Diary],
        healthKitWorkouts: [HealthKitWorkout],
        persistencesClient: PersistencesClient
    ) async -> Bool {
        var migrationOccurred = false

        for savedRecord in savedRecords {
            // 마이그레이션이 필요한지 확인 (새 필드 중 하나라도 nil이면)
            let needsMigration = savedRecord.activeEnergyBurned == nil
                || savedRecord.runningVerticalOscillation == nil
                || savedRecord.runningGroundContactTime == nil
                || savedRecord.walkingStepLength == nil

            guard needsMigration else { continue }

            // startTime으로 매칭되는 HealthKit workout 찾기
            guard let matchingWorkout = healthKitWorkouts.first(where: { $0.startTime == savedRecord.startTime }) else {
                continue
            }

            // 마이그레이션 실행
            do {
                try await persistencesClient.updateRecord(
                    recordId: savedRecord.id,
                    activeEnergyBurned: matchingWorkout.activeEnergyBurned,
                    runningVerticalOscillation: matchingWorkout.runningVerticalOscillation,
                    runningGroundContactTime: matchingWorkout.runningGroundContactTime,
                    walkingStepLength: matchingWorkout.walkingStepLength
                )
                migrationOccurred = true
            } catch {
                // 마이그레이션 실패는 무시하고 계속 진행 (데이터 fetch는 정상 동작해야 함)
                AppLogger.app.warning("HealthKit 메트릭 마이그레이션 실패 - recordId: \(savedRecord.id), error: \(error.localizedDescription)")
            }
        }

        return migrationOccurred
    }
}

extension DependencyValues {
    var runningRecordClient: RunningRecordClient {
        get { self[RunningRecordClient.self] }
        set { self[RunningRecordClient.self] = newValue }
    }
}
