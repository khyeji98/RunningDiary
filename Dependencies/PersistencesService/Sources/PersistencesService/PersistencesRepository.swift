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
    func updateRunningRecord(
        recordId: UUID,
        date: YearMonthDay?,
        distance: Double?,
        duration: TimeInterval?,
        averagePace: String?,
        averageHeartRate: Int?,
        averageCadence: Int?,
        painAreas: [PainArea]?,
        runningStyle: RunninStyle?,
        condition: RunningCondition?,
        shoes: String?,
        weather: WeatherData?,
        difficultyLevel: DifficultyLevel?,
        routeData: Data?,
        activeEnergyBurned: Double?,
        runningVerticalOscillation: Double?,
        runningGroundContactTime: Double?,
        walkingStepLength: Double?,
        restingHeartRate: Double?,
        runningPower: Double?,
        runningStrideLength: Double?,
        heartRateRecoveryOneMinute: Double?,
        startTime: Date?,
        endTime: Date?
    ) async throws
    func deleteRunningRecord(_ record: Diary) async throws
}
