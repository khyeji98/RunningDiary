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

            // 1. Fetch (캐싱은 Repository가 담당, 권한은 Manager가 내부 처리)
            //    조회 시점에 전체 상세 데이터를 싣는다. (경량/상세 구분 없음)
            let healthKitWorkouts = try await healthKitClient.fetchRunningDataBetweenDates(
                from.toDate(),
                to.toDate()
            )
            let savedRecords = try await persistencesClient.fetchRecords(
                from.toDate(),
                to.toDate()
            )

            // 2. Build (비즈니스 로직은 Client가 담당)
            return Self.merge(
                healthKitWorkouts: healthKitWorkouts,
                savedRecords: savedRecords,
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
                date: record.workout.yearMonthDay,
                distance: record.workout.distance,
                duration: record.workout.duration,
                averagePace: record.workout.averagePace,
                averageHeartRate: record.workout.averageHeartRate,
                averageCadence: record.workout.averageCadence,
                painAreas: record.painAreas,
                runningStyle: record.runningStyle,
                memo: record.memo,
                shoes: record.shoes,
                weather: record.weather,
                difficultyLevel: record.difficultyLevel,
                routeData: record.workout.routeData,
                activeEnergyBurned: record.workout.activeEnergyBurned,
                runningVerticalOscillation: record.workout.runningVerticalOscillation,
                runningGroundContactTime: record.workout.runningGroundContactTime,
                walkingStepLength: record.workout.walkingStepLength,
                startTime: record.workout.startTime,
                endTime: record.workout.endTime
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
        let groupedRecords = Dictionary(grouping: savedRecords, by: \.workout.yearMonthDay)

        // 2. 요청 범위의 모든 날짜 생성
        let allDates = Self.generateDateRange(from: from, to: to)

        // 3. 각 날짜별로 DailyRecord 생성
        var result: [YearMonthDay: DailyRecord] = [:]
        for date in allDates {
            let saved = groupedRecords[date] ?? []
            let healthKit = groupedHK[date] ?? []

            // 4. 중복 제거: SwiftData에 저장된 것은 HealthKit에서 제외
            let filteredHealthKit = healthKit.filter { workout in
                !saved.contains { $0.workout.startTime == workout.startTime }
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
}

extension DependencyValues {
    var runningRecordClient: RunningRecordClient {
        get { self[RunningRecordClient.self] }
        set { self[RunningRecordClient.self] = newValue }
    }
}
