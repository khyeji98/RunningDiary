//
//  PersistencesClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import Dependencies
import DependenciesMacros
import Foundation
import SwiftData
import Models
import PersistencesService

@DependencyClient
struct PersistencesClient {
    var fetch: @MainActor @Sendable (Date) async throws -> Diary?
    var fetchRecords: @MainActor @Sendable (Date, Date) async throws -> [Diary]
    var save: @MainActor @Sendable (Diary) async throws -> Void
    var update: @MainActor @Sendable (
        _ recordId: UUID,
        _ date: YearMonthDay?,
        _ distance: Double?,
        _ duration: TimeInterval?,
        _ averagePace: String?,
        _ averageHeartRate: Int?,
        _ averageCadence: Int?,
        _ painAreas: [PainArea]?,
        _ runningStyle: RunninStyle?,
        _ memo: String?,
        _ shoes: String?,
        _ weather: WeatherData?,
        _ difficultyLevel: DifficultyLevel?,
        _ routeData: Data?,
        _ activeEnergyBurned: Double?,
        _ runningVerticalOscillation: Double?,
        _ runningGroundContactTime: Double?,
        _ walkingStepLength: Double?,
        _ restingHeartRate: Double?,
        _ runningPower: Double?,
        _ runningStrideLength: Double?,
        _ heartRateRecoveryOneMinute: Double?,
        _ startTime: Date?,
        _ endTime: Date?
    ) async throws -> Void
    var delete: @MainActor @Sendable (Diary) async throws -> Void
}

extension PersistencesClient {
    /// Convenience method with default nil values for optional parameters
    func updateRecord(
        recordId: UUID,
        date: YearMonthDay? = nil,
        distance: Double? = nil,
        duration: TimeInterval? = nil,
        averagePace: String? = nil,
        averageHeartRate: Int? = nil,
        averageCadence: Int? = nil,
        painAreas: [PainArea]? = nil,
        runningStyle: RunninStyle? = nil,
        memo: String? = nil,
        shoes: String? = nil,
        weather: WeatherData? = nil,
        difficultyLevel: DifficultyLevel? = nil,
        routeData: Data? = nil,
        activeEnergyBurned: Double? = nil,
        runningVerticalOscillation: Double? = nil,
        runningGroundContactTime: Double? = nil,
        walkingStepLength: Double? = nil,
        restingHeartRate: Double? = nil,
        runningPower: Double? = nil,
        runningStrideLength: Double? = nil,
        heartRateRecoveryOneMinute: Double? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) async throws {
        try await self.update(
            recordId, date, distance, duration, averagePace,
            averageHeartRate, averageCadence, painAreas, runningStyle,
            memo, shoes, weather, difficultyLevel, routeData,
            activeEnergyBurned, runningVerticalOscillation,
            runningGroundContactTime, walkingStepLength,
            restingHeartRate, runningPower, runningStrideLength,
            heartRateRecoveryOneMinute, startTime, endTime
        )
    }
}

extension PersistencesClient {
    static func live(modelContext: ModelContext) -> PersistencesClient {
        let repository = LivePersistencesRepository(modelContext: modelContext)

        return PersistencesClient(
            fetch: { date in
                try await repository.fetchRunningRecord(for: date)
            },
            fetchRecords: { startDate, endDate in
                try await repository.fetchRunningRecords(from: startDate, to: endDate)
            },
            save: { record in
                try await repository.saveRunningRecord(record)
            },
            update: { recordId, date, distance, duration, averagePace, averageHeartRate, averageCadence, painAreas, runningStyle, memo, shoes, weather, difficultyLevel, routeData, activeEnergyBurned, runningVerticalOscillation, runningGroundContactTime, walkingStepLength, restingHeartRate, runningPower, runningStrideLength, heartRateRecoveryOneMinute, startTime, endTime in
                try await repository.updateRunningRecord(
                    recordId: recordId,
                    date: date,
                    distance: distance,
                    duration: duration,
                    averagePace: averagePace,
                    averageHeartRate: averageHeartRate,
                    averageCadence: averageCadence,
                    painAreas: painAreas,
                    runningStyle: runningStyle,
                    memo: memo,
                    shoes: shoes,
                    weather: weather,
                    difficultyLevel: difficultyLevel,
                    routeData: routeData,
                    activeEnergyBurned: activeEnergyBurned,
                    runningVerticalOscillation: runningVerticalOscillation,
                    runningGroundContactTime: runningGroundContactTime,
                    walkingStepLength: walkingStepLength,
                    restingHeartRate: restingHeartRate,
                    runningPower: runningPower,
                    runningStrideLength: runningStrideLength,
                    heartRateRecoveryOneMinute: heartRateRecoveryOneMinute,
                    startTime: startTime,
                    endTime: endTime
                )
            },
            delete: { record in
                try await repository.deleteRunningRecord(record)
            }
        )
    }
}

extension PersistencesClient: DependencyKey {
    static let liveValue: PersistencesClient = PersistencesClient(
        fetch: { _ in
            fatalError("RepositoryClient.fetch must be overridden with live implementation")
        },
        fetchRecords: { _, _ in
            fatalError("RepositoryClient.fetchRecords must be overridden with live implementation")
        },
        save: { _ in
            fatalError("RepositoryClient.save must be overridden with live implementation")
        },
        update: { _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ in
            fatalError("RepositoryClient.update must be overridden with live implementation")
        },
        delete: { _ in
            fatalError("RepositoryClient.delete must be overridden with live implementation")
        }
    )

    static let testValue = PersistencesClient(
        fetch: unimplemented("\(Self.self).fetch"),
        fetchRecords: unimplemented("\(Self.self).fetchRecords"),
        save: unimplemented("\(Self.self).save"),
        update: unimplemented("\(Self.self).update"),
        delete: unimplemented("\(Self.self).delete")
    )

    static let previewValue = PersistencesClient(
        fetch: { date in
            // RunningRecordModel.previewRecords에서 날짜가 일치하는 레코드 찾기
            let calendar = Calendar.current
            return RunningRecordPersistenceModel.previewRecords
                .first { calendar.isDate($0.date, inSameDayAs: date) }?
                .toDomain()
        },
        fetchRecords: { startDate, endDate in
            // 날짜 범위에 맞는 레코드들 반환
            RunningRecordPersistenceModel.previewRecords
                .filter { $0.date >= startDate && $0.date <= endDate }
                .map { $0.toDomain() }
        },
        save: { _ in },
        update: { _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ in },
        delete: { _ in }
    )
}

extension DependencyValues {
    var persistencesClient: PersistencesClient {
        get { self[PersistencesClient.self] }
        set { self[PersistencesClient.self] = newValue }
    }
}
