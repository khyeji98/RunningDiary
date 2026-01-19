//
//  PersistencesRepository.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models

public protocol PersistencesRepository {
    func fetchRunningRecord(for date: Date) async throws -> Diary?
    func fetchRunningRecords(from startDate: Date, to endDate: Date) async throws -> [Diary]
    func saveRunningRecord(_ record: Diary) async throws
    func updateRunningRecord(_ record: Diary) async throws
    func deleteRunningRecord(_ record: Diary) async throws
    func migrateHealthKitMetrics(
        recordId: UUID,
        activeEnergyBurned: Double,
        runningVerticalOscillation: Double,
        runningGroundContactTime: Double,
        walkingStepLength: Double
    ) async throws
    func clearCache()
    func clearCache(for yearMonth: YearMonth)
}
