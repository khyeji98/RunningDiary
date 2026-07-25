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
    // 시계열/구간 추출 확장(HealthKitManager+SeriesExtraction)에서 접근하므로 internal
    let healthStore = HKHealthStore()

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

    // 단일 Date에 대한 피트니스 기록을 전체 상세 데이터로 가져옵니다.
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
            if let result = await makeWorkout(from: workout) {
                results.append(result)
            }
        }
        return results
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

    /// 워크아웃 하나에 대한 전체 상세 데이터를 추출해 `HealthKitWorkout`으로 구성한다.
    /// 평균 스칼라는 워크아웃 통계 쿼리를 우선 사용하고 통계가 없으면 시계열 산술평균으로 폴백한다. (경량/상세 조회 구분 없이 단일 경로)
    private func makeWorkout(from workout: HKWorkout) async -> HealthKitWorkout? {
        guard let distance = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)),
              let averagePace = calculateAveragePace(from: workout)
        else { return nil }

        // HR/cadence/pace는 splits·series 빌더가 튜플 시계열을 요구하므로 튜플로 조회한 뒤 MetricSample로 변환한다.
        let heartRateSeries = await fetchQuantitySeries(
            for: workout,
            identifier: .heartRate,
            unit: HKUnit.count().unitDivided(by: .minute())
        )
        let cadenceSeries = await fetchCadenceSeries(for: workout)
        let paceSeries = await fetchPaceSeries(for: workout)

        let heartRateSamples = makeMetricSamples(heartRateSeries)
        let cadenceSamples = makeMetricSamples(cadenceSeries)

        // 나머지 5종은 각 1회 쿼리로 시계열을 그대로 보유한다.
        let verticalOscillationSamples = await fetchMetricSamples(
            for: workout, identifier: .runningVerticalOscillation, unit: .meterUnit(with: .centi)
        )
        let groundContactTimeSamples = await fetchMetricSamples(
            for: workout, identifier: .runningGroundContactTime, unit: .secondUnit(with: .milli)
        )
        let walkingStepLengthSamples = await fetchMetricSamples(
            for: workout, identifier: .walkingStepLength, unit: .meter()
        )
        let runningPowerSamples = await fetchMetricSamples(
            for: workout, identifier: .runningPower, unit: .watt()
        )
        let runningStrideLengthSamples = await fetchMetricSamples(
            for: workout, identifier: .runningStrideLength, unit: .meter()
        )

        // restingHeartRate / heartRateRecoveryOneMinute는 워크아웃 구간 밖을 집계하므로 스칼라로 조회한다.
        let activeEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        let restingHeartRate = await fetchAverageRestingHeartRate(for: workout) ?? 0
        let heartRateRecoveryOneMinute = await fetchHeartRateRecoveryOneMinute(for: workout) ?? 0
        let routeExtraction = try? await fetchRouteData(for: workout)
        let routeSamples = routeExtraction?.samples ?? []

        let splits = WorkoutSplitCalculator.makeSplits(
            route: routeSamples,
            heartRate: heartRateSeries,
            cadence: cadenceSeries
        )
        let series = makeWorkoutSeries(
            heartRate: heartRateSeries,
            pace: paceSeries,
            cadence: cadenceSeries,
            route: routeSamples
        )

        // 평균 스칼라는 워크아웃 통계 쿼리(.discreteAverage)를 우선 사용하고, 통계가 없으면 시계열 산술평균으로 폴백한다.
        // (Int.init은 소수부 버림) cadence는 stepCount(cumulative) 기반이라 통계 평균이 없어 시계열 산술평균을 유지한다.
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let averageHeartRate = averageQuantity(
            from: workout, identifier: .heartRate, unit: heartRateUnit, fallbackSamples: heartRateSamples
        ).map(Int.init) ?? 0
        let averageCadence = MetricSample.average(of: cadenceSamples).map(Int.init) ?? 0
        let runningVerticalOscillation = averageQuantity(
            from: workout,
            identifier: .runningVerticalOscillation,
            unit: .meterUnit(with: .centi),
            fallbackSamples: verticalOscillationSamples
        ) ?? 0
        let runningGroundContactTime = averageQuantity(
            from: workout,
            identifier: .runningGroundContactTime,
            unit: .secondUnit(with: .milli),
            fallbackSamples: groundContactTimeSamples
        ) ?? 0
        let walkingStepLength = averageQuantity(
            from: workout, identifier: .walkingStepLength, unit: .meter(), fallbackSamples: walkingStepLengthSamples
        ) ?? 0
        let runningPower = averageQuantity(
            from: workout, identifier: .runningPower, unit: .watt(), fallbackSamples: runningPowerSamples
        ) ?? 0
        let runningStrideLength = averageQuantity(
            from: workout, identifier: .runningStrideLength, unit: .meter(), fallbackSamples: runningStrideLengthSamples
        ) ?? 0

        return HealthKitWorkout(
            id: workout.uuid,
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
            routeData: routeExtraction?.routeData,
            startDate: workout.startDate,
            endDate: workout.endDate,
            splits: splits,
            series: series,
            heartRateSamples: heartRateSamples,
            cadenceSamples: cadenceSamples,
            runningVerticalOscillationSamples: verticalOscillationSamples,
            runningGroundContactTimeSamples: groundContactTimeSamples,
            walkingStepLengthSamples: walkingStepLengthSamples,
            runningPowerSamples: runningPowerSamples,
            runningStrideLengthSamples: runningStrideLengthSamples
        )
    }

    /// 워크아웃에 연관된 discrete 지표의 평균을 HealthKit이 저장 시 산출한 통계에서 조회한다.
    /// 통계가 없으면(일부 서드파티 소스) 이미 조회한 시계열의 산술평균으로 폴백한다.
    private func averageQuantity(
        from workout: HKWorkout,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        fallbackSamples: [MetricSample]
    ) -> Double? {
        if let type = HKQuantityType.quantityType(forIdentifier: identifier),
           let average = workout.statistics(for: type)?.averageQuantity()?.doubleValue(for: unit) {
            return average
        }

        return MetricSample.average(of: fallbackSamples)
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

    /// 휴식 심박수는 하루 단위로 기록되므로 workout 날짜의 전체 하루를 조회
    private func fetchAverageRestingHeartRate(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: workout.startDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        let unit = HKUnit.count().unitDivided(by: .minute())
        return await fetchAverageQuantityForDateRange(from: startOfDay, to: endOfDay, type: type, unit: unit)
    }

    /// 1분 심박수 회복은 운동 종료 후 측정되므로 종료 시간부터 5분까지 확장 조회
    private func fetchHeartRateRecoveryOneMinute(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateRecoveryOneMinute) else { return nil }

        let extendedEnd = workout.endDate.addingTimeInterval(5 * 60) // 운동 종료 후 5분
        let unit = HKUnit.count().unitDivided(by: .minute())
        return await fetchAverageQuantityForDateRange(from: workout.endDate, to: extendedEnd, type: type, unit: unit)
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
