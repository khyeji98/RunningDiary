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
    var fetch: @MainActor @Sendable (Date) async throws -> RunningRecord?
    var fetchRecords: @MainActor @Sendable (Date, Date) async throws -> [RunningRecord]
    var save: @MainActor @Sendable (RunningRecord) async throws -> Void
    var update: @MainActor @Sendable (RunningRecord) async throws -> Void
    var delete: @MainActor @Sendable (RunningRecord) async throws -> Void
    var migrateHealthKitMetrics: @MainActor @Sendable (
        _ recordId: UUID,
        _ activeEnergyBurned: Double,
        _ runningVerticalOscillation: Double,
        _ runningGroundContactTime: Double,
        _ walkingStepLength: Double
    ) async throws -> Void
    var clearCache: @MainActor @Sendable () -> Void
    var clearCacheForMonth: @MainActor @Sendable (YearMonth) -> Void
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
        update: { _ in
            fatalError("RepositoryClient.update must be overridden with live implementation")
        },
        delete: { _ in
            fatalError("RepositoryClient.delete must be overridden with live implementation")
        },
        migrateHealthKitMetrics: { _, _, _, _, _ in
            fatalError("RepositoryClient.migrateHealthKitMetrics must be overridden with live implementation")
        },
        clearCache: {
            fatalError("RepositoryClient.clearCache must be overridden with live implementation")
        },
        clearCacheForMonth: { _ in
            fatalError("RepositoryClient.clearCacheForMonth must be overridden with live implementation")
        }
    )

    static let testValue = PersistencesClient(
        fetch: unimplemented("\(Self.self).fetch"),
        fetchRecords: unimplemented("\(Self.self).fetchRecords"),
        save: unimplemented("\(Self.self).save"),
        update: unimplemented("\(Self.self).update"),
        delete: unimplemented("\(Self.self).delete"),
        migrateHealthKitMetrics: unimplemented("\(Self.self).migrateHealthKitMetrics"),
        clearCache: unimplemented("\(Self.self).clearCache"),
        clearCacheForMonth: unimplemented("\(Self.self).clearCacheForMonth")
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
        update: { _ in },
        delete: { _ in },
        migrateHealthKitMetrics: { _, _, _, _, _ in },
        clearCache: { },
        clearCacheForMonth: { _ in }
    )
}

extension DependencyValues {
    var persistencesClient: PersistencesClient {
        get { self[PersistencesClient.self] }
        set { self[PersistencesClient.self] = newValue }
    }
}

// MARK: - Helper

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
            update: { record in
                try await repository.updateRunningRecord(record)
            },
            delete: { record in
                try await repository.deleteRunningRecord(record)
            },
            migrateHealthKitMetrics: { recordId, activeEnergyBurned, runningVerticalOscillation, runningGroundContactTime, walkingStepLength in
                try await repository.migrateHealthKitMetrics(
                    recordId: recordId,
                    activeEnergyBurned: activeEnergyBurned,
                    runningVerticalOscillation: runningVerticalOscillation,
                    runningGroundContactTime: runningGroundContactTime,
                    walkingStepLength: walkingStepLength
                )
            },
            clearCache: {
                repository.clearCache()
            },
            clearCacheForMonth: { yearMonth in
                repository.clearCache(for: yearMonth)
            }
        )
    }
}
