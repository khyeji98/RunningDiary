//
//  LivePersistencesRepository.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models
import SwiftData

public final class LivePersistencesRepository: PersistencesRepository {
    // ModelContext : 데이터 변경을 추적하고 저장/조회/삭제를 실행하는 중심 객체
    private let modelContext: ModelContext
    private var cache: [YearMonthDay: [Diary]] = [:]

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func fetchRunningRecord(for date: Date) async throws -> Diary? {
        let yearMonthDay = YearMonthDay(date: date)

        // 1. 캐시 확인
        if let cachedRecords = cache[yearMonthDay] {
            return cachedRecords.first
        }

        // 2. 캐시 미스: DB 조회
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        let predicate = #Predicate<RunningRecordPersistenceModel> { record in
            record.date >= startOfDay && record.date < endOfDay
        }

        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
            predicate: predicate
        )

        let models = try modelContext.fetch(descriptor)
        let records = models.map { $0.toDomain() }

        // 3. 캐시에 저장
        cache[yearMonthDay] = records

        return records.first
    }

    public func fetchRunningRecords(from startDate: Date, to endDate: Date) async throws -> [Diary] {
        // 1. 요청 범위의 날짜들 추출
        let requestedDates = generateDateRange(from: startDate, to: endDate)

        // 2. 캐시 히트 확인
        let missingDates = requestedDates.filter { !cache.keys.contains($0) }

        // 3. 캐시 미스인 날짜만 DB 조회
        if !missingDates.isEmpty {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: startDate)
            let end = calendar.startOfDay(for: endDate)

            let predicate = #Predicate<RunningRecordPersistenceModel> { record in
                record.date >= start && record.date <= end
            }

            let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            let models = try modelContext.fetch(descriptor)
            let fetchedRecords = models.map { $0.toDomain() }

            // 4. 날짜별로 그룹핑하여 캐시에 저장
            let groupedRecords = Dictionary(grouping: fetchedRecords, by: \.yearMonthDay)
            for date in missingDates {
                cache[date] = groupedRecords[date] ?? []
            }
        }

        // 5. 캐시에서 결과 추출
        let result = requestedDates.flatMap { cache[$0] ?? [] }

        return result
    }

    public func saveRunningRecord(_ record: Diary) async throws {
        let model = RunningRecordPersistenceModel.fromDomain(record)
        modelContext.insert(model)

        do {
            try modelContext.save()
            // 캐시 invalidate
            cache.removeValue(forKey: record.yearMonthDay)
        } catch {
            throw PersistencesError.saveFailed
        }
    }

    public func updateRunningRecord(_ record: Diary) async throws {
        // 기존 레코드 찾기
        let recordId = record.id
        let predicate = #Predicate<RunningRecordPersistenceModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
            predicate: predicate
        )

        guard let existingModel = try modelContext.fetch(descriptor).first else {
            throw PersistencesError.notFound
        }

        // 업데이트
        existingModel.date = record.yearMonthDay.toDate()
        existingModel.distance = record.distanceInKilometers
        existingModel.duration = record.durationInSeconds
        existingModel.averagePace = record.averagePace
        existingModel.averageHeartRate = record.averageHeartRate
        existingModel.averageCadence = record.averageCadence
        existingModel.painAreasRawData = PainAreasMapper.encode(
            record.painAreas
        )
        existingModel.runningStyleRaw = record.runningStyle?.rawValue
        existingModel.sleepHours = record.condition.sleep
        existingModel.hadMeal = record.condition.meal
        existingModel.hadAlcohol = record.condition.alcohol
        existingModel.memo = record.condition.memo
        existingModel.shoes = record.shoes
        existingModel.temperature = record.weather?.temperature
        existingModel.humidity = record.weather?.humidity
        existingModel.windSpeed = record.weather?.windSpeed
        existingModel.difficultyLevelRaw = record.difficultyLevel?.rawValue
        existingModel.routeData = record.routeData
        existingModel.activeEnergyBurned = record.activeEnergyBurned
        existingModel.runningVerticalOscillation = record.runningVerticalOscillation
        existingModel.runningGroundContactTime = record.runningGroundContactTime
        existingModel.walkingStepLength = record.walkingStepLength
        existingModel.hasMap = record.hasMap
        existingModel.startTime = record.startTime
        existingModel.endTime = record.endTime

        do {
            try modelContext.save()
            // 캐시 invalidate
            cache.removeValue(forKey: record.yearMonthDay)
        } catch {
            throw PersistencesError.updateFailed
        }
    }

    public func deleteRunningRecord(_ record: Diary) async throws {
        let recordId = record.id
        let predicate = #Predicate<RunningRecordPersistenceModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
            predicate: predicate
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            throw PersistencesError.notFound
        }

        modelContext.delete(model)

        do {
            try modelContext.save()

            // 캐시 invalidate
            cache.removeValue(forKey: record.yearMonthDay)
        } catch {
            throw PersistencesError.deleteFailed
        }
    }

    public func migrateHealthKitMetrics(
        recordId: UUID,
        activeEnergyBurned: Double,
        runningVerticalOscillation: Double,
        runningGroundContactTime: Double,
        walkingStepLength: Double
    ) async throws {
        // 기존 레코드 찾기
        let predicate = #Predicate<RunningRecordPersistenceModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(predicate: predicate)

        guard let existingModel = try modelContext.fetch(descriptor).first else {
            throw PersistencesError.notFound
        }

        // nil인 필드만 업데이트
        var updated = false

        if existingModel.activeEnergyBurned == nil {
            existingModel.activeEnergyBurned = activeEnergyBurned
            updated = true
        }

        if existingModel.runningVerticalOscillation == nil {
            existingModel.runningVerticalOscillation = runningVerticalOscillation
            updated = true
        }

        if existingModel.runningGroundContactTime == nil {
            existingModel.runningGroundContactTime = runningGroundContactTime
            updated = true
        }

        if existingModel.walkingStepLength == nil {
            existingModel.walkingStepLength = walkingStepLength
            updated = true
        }

        guard updated else { return }

        do {
            try modelContext.save()

            // 캐시 invalidate
            let yearMonthDay = YearMonthDay(date: existingModel.date)
            cache.removeValue(forKey: yearMonthDay)
        } catch {
            throw PersistencesError.updateFailed
        }
    }

    // MARK: - Cache Management

    public func clearCache() {
        cache.removeAll()
    }

    public func clearCache(for yearMonth: YearMonth) {
        let datesToRemove = cache.keys.filter { $0.toYearMonth() == yearMonth }
        for date in datesToRemove {
            cache.removeValue(forKey: date)
        }
    }

    // MARK: - Helper Methods

    private func generateDateRange(from startDate: Date, to endDate: Date) -> [YearMonthDay] {
        var dates: [YearMonthDay] = []
        let calendar = Calendar.current

        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        while current <= end {
            dates.append(YearMonthDay(date: current))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        return dates
    }
}
