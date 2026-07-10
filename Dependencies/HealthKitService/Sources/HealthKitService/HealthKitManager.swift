//
//  HealthKitManager.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import CoreLocation
import Foundation
import HealthKit
import Models

public final class HealthKitManager: HealthKitManagerProtocol, @unchecked Sendable {
    private let healthStore = HKHealthStore()

    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),                                                               // workout 타입
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,                       // 걷기/달리기 거리
        HKObjectType.quantityType(forIdentifier: .heartRate)!,                                    // 심박수
        HKObjectType.quantityType(forIdentifier: .runningSpeed)!,                                 // 달리기 속도
        HKObjectType.quantityType(forIdentifier: .stepCount)!,                                    // 걸음 수
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,                           // 활동 에너지 소모량
        HKObjectType.quantityType(forIdentifier: .runningVerticalOscillation)!,                   // 달리기 수직 진폭
        HKObjectType.quantityType(forIdentifier: .runningGroundContactTime)!,                     // 달리기 지면 접촉 시간
        HKObjectType.quantityType(forIdentifier: .walkingStepLength)!,                            // 걷기 보폭 길이
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,                             // 휴식 심박수
        HKObjectType.quantityType(forIdentifier: .runningPower)!,                                 // 달리기 파워
        HKObjectType.quantityType(forIdentifier: .runningStrideLength)!,                          // 달리기 보폭 길이
        HKObjectType.quantityType(forIdentifier: .heartRateRecoveryOneMinute)!,                   // 1분 심박수 회복
        HKSeriesType.workoutRoute(),                                                              // 경로
    ]

    public init() {}

    public func ensureAuthorizationIfNeeded() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let statuses = currentAuthorizationStatuses()
        let notDetermined = statuses.filter { $0.value == .notDetermined }.map { $0.key }

        guard !notDetermined.isEmpty else { return }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        } catch {
            throw HealthKitError.authorizationFailed
        }
    }

    private func currentAuthorizationStatuses() -> [HKObjectType: HKAuthorizationStatus] {
        var result: [HKObjectType: HKAuthorizationStatus] = [:]
        for type in typesToRead {
            result[type] = healthStore.authorizationStatus(for: type)
        }
        return result
    }

    // 단일 Date에 대한 피트니스 기록을 가져옵니다. (목록 노출용 경량 데이터)
    public func fetchRunningData(for date: Date) async throws -> [HealthKitWorkout] {
        try await ensureAuthorizationIfNeeded()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.endOfDay(for: date) else {
            return []
        }

        let workouts = try await queryWorkouts(start: startOfDay, end: endOfDay)

        var results: [HealthKitWorkout] = []
        for workout in workouts {
            if let lightweight = await makeLightweightWorkout(from: workout) {
                results.append(lightweight)
            }
        }
        return results
    }

    // 특정 워크아웃(startDate ~ endDate)에 대한 전체 상세 데이터를 추출합니다. (일기 저장용)
    public func fetchDetailedRunningData(from startDate: Date, to endDate: Date) async throws -> HealthKitWorkout? {
        try await ensureAuthorizationIfNeeded()

        let workouts = try await queryWorkouts(start: startDate, end: endDate)
        guard let workout = workouts.first(where: { $0.startDate == startDate }) ?? workouts.first else {
            return nil
        }

        return await makeDetailedWorkout(from: workout)
    }

    /// 러닝 워크아웃을 날짜 범위로 조회하는 공통 쿼리
    private func queryWorkouts(start: Date, end: Date) async throws -> [HKWorkout] {
        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [runningPredicate, datePredicate])

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    ),
                ]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKWorkout] ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    /// 목록 노출에 필요한 최소 데이터(거리·시간·페이스·케이던스)만 추출한다.
    private func makeLightweightWorkout(from workout: HKWorkout) async -> HealthKitWorkout? {
        guard let distance = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)),
              let averagePace = calculateAveragePace(from: workout),
              let averageCadence = await fetchAverageCadence(for: workout)
        else { return nil }

        return HealthKitWorkout(
            distance: distance,
            duration: workout.duration,
            averagePace: averagePace,
            averageHeartRate: 0,
            averageCadence: averageCadence,
            activeEnergyBurned: 0,
            runningVerticalOscillation: 0,
            runningGroundContactTime: 0,
            walkingStepLength: 0,
            restingHeartRate: 0,
            runningPower: 0,
            runningStrideLength: 0,
            heartRateRecoveryOneMinute: 0,
            routeData: nil,
            startDate: workout.startDate,
            endDate: workout.endDate
        )
    }

    /// 일기 저장 시 필요한 전체 상세 데이터를 추출한다.
    private func makeDetailedWorkout(from workout: HKWorkout) async -> HealthKitWorkout? {
        guard let distance = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)),
              let averagePace = calculateAveragePace(from: workout),
              let averageCadence = await fetchAverageCadence(for: workout)
        else { return nil }

        let averageHeartRate = await fetchAverageHeartRate(for: workout) ?? 0
        let activeEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        let runningVerticalOscillation = await fetchAverageVerticalOscillation(for: workout) ?? 0
        let runningGroundContactTime = await fetchAverageGroundContactTime(for: workout) ?? 0
        let walkingStepLength = await fetchAverageStepLength(for: workout) ?? 0
        let restingHeartRate = await fetchAverageRestingHeartRate(for: workout) ?? 0
        let runningPower = await fetchAverageRunningPower(for: workout) ?? 0
        let runningStrideLength = await fetchAverageRunningStrideLength(for: workout) ?? 0
        let heartRateRecoveryOneMinute = await fetchHeartRateRecoveryOneMinute(for: workout) ?? 0
        let routeData = try? await fetchRouteData(for: workout)

        return HealthKitWorkout(
            distance: distance,
            duration: workout.duration,
            averagePace: averagePace,
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            activeEnergyBurned: activeEnergyBurned,
            runningVerticalOscillation: runningVerticalOscillation,
            runningGroundContactTime: runningGroundContactTime,
            walkingStepLength: walkingStepLength,
            restingHeartRate: restingHeartRate,
            runningPower: runningPower,
            runningStrideLength: runningStrideLength,
            heartRateRecoveryOneMinute: heartRateRecoveryOneMinute,
            routeData: routeData,
            startDate: workout.startDate,
            endDate: workout.endDate
        )
    }

    private func calculateAveragePace(from workout: HKWorkout) -> String? {
        guard let distance = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)),
              distance > 0
        else {
            return nil
        }

        let durationInMinutes = workout.duration / 60.0
        let paceMinPerKm = durationInMinutes / distance

        let minutes = Int(paceMinPerKm)
        let seconds = Int((paceMinPerKm - Double(minutes)) * 60)

        return String(format: "%d'%02d\"", minutes, seconds)
    }

    private func fetchAverageHeartRate(for workout: HKWorkout) async -> Int? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let unit = HKUnit.count().unitDivided(by: .minute())
        guard let average = await fetchAverageQuantity(for: workout, type: type, unit: unit) else { return nil }
        return Int(average)
    }

    private func fetchAverageCadence(for workout: HKWorkout) async -> Int? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        let totalSteps = await withCheckedContinuation { (continuation: CheckedContinuation<Double, Never>) in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if error != nil {
                    continuation.resume(returning: 0)
                    return
                }
                let sum = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: sum)
            }
            healthStore.execute(query)
        }

        let durationInMinutes = workout.duration / 60.0

        guard durationInMinutes > 0 && totalSteps > 0 else {
            return nil
        }

        return Int(totalSteps / durationInMinutes)
    }

    private func fetchAverageVerticalOscillation(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningVerticalOscillation) else { return nil }
        return await fetchAverageQuantity(for: workout, type: type, unit: .meterUnit(with: .centi))
    }

    private func fetchAverageGroundContactTime(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningGroundContactTime) else { return nil }
        return await fetchAverageQuantity(for: workout, type: type, unit: .secondUnit(with: .milli))
    }

    private func fetchAverageStepLength(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingStepLength) else { return nil }
        return await fetchAverageQuantity(for: workout, type: type, unit: .meter())
    }

    /// 휴식 심박수는 하루 단위로 기록되므로 workout 날짜의 전체 하루를 조회
    private func fetchAverageRestingHeartRate(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: workout.startDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        let unit = HKUnit.count().unitDivided(by: .minute())
        return await fetchAverageQuantityForDateRange(from: startOfDay, to: endOfDay, type: type, unit: unit)
    }

    private func fetchAverageRunningPower(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningPower) else { return nil }
        return await fetchAverageQuantity(for: workout, type: type, unit: .watt())
    }

    private func fetchAverageRunningStrideLength(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningStrideLength) else { return nil }
        return await fetchAverageQuantity(for: workout, type: type, unit: .meter())
    }

    /// 1분 심박수 회복은 운동 종료 후 측정되므로 종료 시간부터 5분까지 확장 조회
    private func fetchHeartRateRecoveryOneMinute(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateRecoveryOneMinute) else { return nil }

        let extendedEnd = workout.endDate.addingTimeInterval(5 * 60) // 운동 종료 후 5분
        let unit = HKUnit.count().unitDivided(by: .minute())
        return await fetchAverageQuantityForDateRange(from: workout.endDate, to: extendedEnd, type: type, unit: unit)
    }

    private func fetchAverageQuantity(for workout: HKWorkout, type: HKQuantityType, unit: HKUnit) async -> Double? {
        return await fetchAverageQuantityForDateRange(from: workout.startDate, to: workout.endDate, type: type, unit: unit)
    }

    /// 특정 날짜 범위에 대해 평균값을 조회하는 공통 헬퍼
    private func fetchAverageQuantityForDateRange(
        from startDate: Date, to endDate: Date, type: HKQuantityType, unit: HKUnit
    ) async -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                // 에러 발생 시 (데이터 없음 포함) nil 반환
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }

                let average = statistics?.averageQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: average)
            }
            healthStore.execute(query)
        }
    }

    // startDate ~ endDate 기간에 대한 피트니스 기록을 가져옵니다.
    public func fetchWeeklyRunningData(from startDate: Date, to endDate: Date) async throws -> [HealthKitWorkout] {
        try await ensureAuthorizationIfNeeded()

        let calendar = Calendar.current

        // 시작일부터 종료일까지의 날짜 배열 생성
        var dates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let normalizedEndDate = calendar.startOfDay(for: endDate)

        while currentDate <= normalizedEndDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        // 각 날짜에 대해 병렬로 데이터 조회
        return await withTaskGroup(of: [HealthKitWorkout].self) { group in
            for date in dates {
                group.addTask { [self] in
                    return (try? await self.fetchRunningData(for: date)) ?? []
                }
            }

            // 결과를 하나의 배열로 합침
            var results: [HealthKitWorkout] = []
            for await result in group {
                results.append(contentsOf: result)
            }

            return results
        }
    }
}

private extension HealthKitManager {
    func fetchRouteData(for workout: HKWorkout) async throws -> Data? {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        let routes = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkoutRoute], Error>) in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(
                        returning: samples as? [HKWorkoutRoute] ?? []
                    )
                }
            }
            healthStore.execute(query)
        }

        guard let route = routes.first else {
            return nil
        }

        var coordinates: [CLLocationCoordinate2D] = []

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let locations = locations {
                    coordinates.append(contentsOf: locations.map { $0.coordinate })
                }

                if done {
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }

        let locations = coordinates.map {
            Location(
                latitude: $0.latitude,
                longitude: $0.longitude
            )
        }

        // [Location]을 JSON Data로 인코딩
        return try? JSONEncoder().encode(locations)
    }
}
