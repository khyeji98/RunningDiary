//
//  HealthKitManager+SeriesExtraction.swift
//  RunDiary
//
//  Created by 김혜지 on 7/13/26.
//

import CoreLocation
import Foundation
import HealthKit
import Models

private enum Constant {
    static let seriesIntervalSec = 5
}

/// 경로 조회 결과. `routeData`는 기존 `[Location]` JSON(좌표만), `samples`는 splits/series 계산용 원시 값(경과초·누적거리·고도).
struct RouteExtractionResult {
    let routeData: Data?
    let samples: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)]
}

extension HealthKitManager {
    /// 시계열이 하나라도 존재하면 `WorkoutSeries`를 구성한다. 전부 비어 있으면 nil.
    func makeWorkoutSeries(
        heartRate: [(offset: TimeInterval, value: Double)],
        pace: [(offset: TimeInterval, value: Double)],
        cadence: [(offset: TimeInterval, value: Double)],
        route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)]
    ) -> WorkoutSeries? {
        guard !heartRate.isEmpty || !pace.isEmpty || !cadence.isEmpty || !route.isEmpty else { return nil }

        let elevation = route.compactMap { sample -> ElevationPoint? in
            guard let altitude = sample.altitude else { return nil }
            return ElevationPoint(distanceM: sample.cumulativeMeters, altitude: altitude)
        }

        return WorkoutSeries(
            sampleIntervalSec: Constant.seriesIntervalSec,
            heartRate: WorkoutSeriesBuilder.downsample(heartRate, intervalSec: Constant.seriesIntervalSec),
            paceSecondsPerKm: WorkoutSeriesBuilder.downsample(pace, intervalSec: Constant.seriesIntervalSec),
            cadence: WorkoutSeriesBuilder.downsample(cadence, intervalSec: Constant.seriesIntervalSec),
            elevation: elevation
        )
    }
}

extension HealthKitManager {
    func fetchRouteData(for workout: HKWorkout) async throws -> RouteExtractionResult {
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
            return RouteExtractionResult(routeData: nil, samples: [])
        }

        var locations: [CLLocation] = []

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let query = HKWorkoutRouteQuery(route: route) { _, batch, done, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let batch = batch {
                    locations.append(contentsOf: batch)
                }

                if done {
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }

        let coordinates = locations.map {
            Location(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude
            )
        }

        // [Location]을 JSON Data로 인코딩
        let routeData = try? JSONEncoder().encode(coordinates)
        let samples = makeRouteSamples(from: locations, workoutStart: workout.startDate)

        return RouteExtractionResult(routeData: routeData, samples: samples)
    }

    /// `CLLocation`의 timestamp·altitude·좌표를 splits/series 계산용 원시 샘플(경과초·누적거리·고도)로 변환한다.
    func makeRouteSamples(
        from locations: [CLLocation],
        workoutStart: Date
    ) -> [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] {
        var samples: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = []
        var cumulativeMeters: Double = 0
        var previousLocation: CLLocation?

        for location in locations {
            if let previousLocation {
                cumulativeMeters += location.distance(from: previousLocation)
            }

            samples.append((
                offset: location.timestamp.timeIntervalSince(workoutStart),
                cumulativeMeters: cumulativeMeters,
                altitude: location.altitude
            ))
            previousLocation = location
        }

        return samples
    }

    /// HR 등 `HKQuantitySample` 시계열을 (경과초, 원시 샘플) 배열로 조회하는 공통 헬퍼.
    func fetchQuantitySamples(
        for workout: HKWorkout,
        identifier: HKQuantityTypeIdentifier
    ) async -> [HKQuantitySample] {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        return await withCheckedContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Never>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, results, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: results as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }
    }

    /// `identifier` 시계열을 `unit`으로 변환해 (경과초, 값) 배열로 반환한다.
    func fetchQuantitySeries(
        for workout: HKWorkout,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> [(offset: TimeInterval, value: Double)] {
        let samples = await fetchQuantitySamples(for: workout, identifier: identifier)
        return samples.map { sample in
            (
                offset: sample.startDate.timeIntervalSince(workout.startDate),
                value: sample.quantity.doubleValue(for: unit)
            )
        }
    }

    /// runningSpeed(m/s) 시계열을 `paceSecondsPerKm = 1000 / speed`로 변환한다. speed가 0 이하이면 제외한다.
    func fetchPaceSeries(for workout: HKWorkout) async -> [(offset: TimeInterval, value: Double)] {
        let speedSeries = await fetchQuantitySeries(
            for: workout,
            identifier: .runningSpeed,
            unit: .meter().unitDivided(by: .second())
        )

        return speedSeries.compactMap { sample in
            guard sample.value > 0 else { return nil }
            return (offset: sample.offset, value: 1000 / sample.value)
        }
    }

    /// stepCount 샘플을 각 샘플 구간(spm)으로 환산해 케이던스 시계열을 만든다.
    func fetchCadenceSeries(for workout: HKWorkout) async -> [(offset: TimeInterval, value: Double)] {
        let stepSamples = await fetchQuantitySamples(for: workout, identifier: .stepCount)

        return stepSamples.compactMap { sample -> (offset: TimeInterval, value: Double)? in
            let durationMinutes = sample.endDate.timeIntervalSince(sample.startDate) / 60
            guard durationMinutes > 0 else { return nil }

            let steps = sample.quantity.doubleValue(for: .count())
            let offset = sample.startDate.timeIntervalSince(workout.startDate)
            return (offset: offset, value: steps / durationMinutes)
        }
    }
}
