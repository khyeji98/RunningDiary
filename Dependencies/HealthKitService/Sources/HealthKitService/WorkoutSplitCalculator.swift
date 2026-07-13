//
//  WorkoutSplitCalculator.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/13/26.
//

import Foundation
import Models

/// route(경과초·누적거리·고도) 샘플과 HR/cadence 샘플로 구간(split) 요약을 산출하는 순수 계산 타입.
/// HealthKit 타입에 의존하지 않고 원시 값만 입출력하여 단위 테스트가 가능하다.
public enum WorkoutSplitCalculator {
    /// route 샘플(경과초·누적거리m·고도m)과 HR/cadence 샘플로 `splitDistanceKm` 단위 구간 요약을 산출한다.
    public static func makeSplits(
        route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)],
        heartRate: [(offset: TimeInterval, value: Double)],
        cadence: [(offset: TimeInterval, value: Double)],
        splitDistanceKm: Double = 1.0
    ) -> [WorkoutSplit] {
        guard !route.isEmpty, splitDistanceKm > 0 else { return [] }

        let sortedRoute = route.sorted { $0.offset < $1.offset }
        let sortedHeartRate = heartRate.sorted { $0.offset < $1.offset }
        let sortedCadence = cadence.sorted { $0.offset < $1.offset }

        guard let firstPoint = sortedRoute.first, let lastPoint = sortedRoute.last else { return [] }

        let splitDistanceM = splitDistanceKm * 1000
        let boundaryMeters = makeBoundaryMeters(totalMeters: lastPoint.cumulativeMeters, splitDistanceM: splitDistanceM)
        guard !boundaryMeters.isEmpty else { return [] }

        var splits: [WorkoutSplit] = []
        var previousBoundaryMeters = firstPoint.cumulativeMeters
        var previousOffset = firstPoint.offset

        for (index, boundary) in boundaryMeters.enumerated() {
            let boundaryOffset = offsetForDistance(boundary, in: sortedRoute)
            let distanceKm = (boundary - previousBoundaryMeters) / 1000
            let durationSec = boundaryOffset - previousOffset
            let paceSecondsPerKm = distanceKm > 0 ? Int((durationSec / distanceKm).rounded()) : 0

            let split = WorkoutSplit(
                index: index + 1,
                distanceKm: distanceKm,
                durationSec: durationSec,
                paceSecondsPerKm: paceSecondsPerKm,
                averageHeartRate: averageValue(of: sortedHeartRate, from: previousOffset, to: boundaryOffset),
                averageCadence: averageValue(of: sortedCadence, from: previousOffset, to: boundaryOffset),
                elevationGainM: elevationGain(in: sortedRoute, from: previousOffset, to: boundaryOffset)
            )
            splits.append(split)

            previousBoundaryMeters = boundary
            previousOffset = boundaryOffset
        }

        return splits
    }

    /// `splitDistanceM` 단위 경계 누적거리 목록을 산출한다. 마지막 1km 미만 잔여 구간도 포함한다.
    private static func makeBoundaryMeters(totalMeters: Double, splitDistanceM: Double) -> [Double] {
        guard totalMeters > 0 else { return [] }

        var boundaries: [Double] = []
        var multiplier = 1

        while Double(multiplier) * splitDistanceM <= totalMeters {
            boundaries.append(Double(multiplier) * splitDistanceM)
            multiplier += 1
        }

        let lastBoundary = boundaries.last ?? 0
        if totalMeters - lastBoundary > .ulpOfOne {
            boundaries.append(totalMeters)
        }

        return boundaries
    }

    /// 누적거리 `meters` 지점의 경과초를 route 샘플 사이 선형 보간으로 구한다.
    private static func offsetForDistance(
        _ meters: Double,
        in route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)]
    ) -> TimeInterval {
        guard let first = route.first else { return 0 }
        guard meters > first.cumulativeMeters else { return first.offset }

        for index in 1..<route.count {
            let previous = route[index - 1]
            let current = route[index]
            guard current.cumulativeMeters >= meters else { continue }

            let segmentDistance = current.cumulativeMeters - previous.cumulativeMeters
            guard segmentDistance > 0 else { return current.offset }

            let fraction = (meters - previous.cumulativeMeters) / segmentDistance
            return previous.offset + fraction * (current.offset - previous.offset)
        }

        return route.last?.offset ?? first.offset
    }

    /// `[startOffset, endOffset]` 구간에 속한 샘플의 평균을 반올림한 Int로 반환한다. 샘플 없으면 nil.
    private static func averageValue(
        of samples: [(offset: TimeInterval, value: Double)],
        from startOffset: TimeInterval,
        to endOffset: TimeInterval
    ) -> Int? {
        let values = samples
            .filter { $0.offset >= startOffset && $0.offset <= endOffset }
            .map { $0.value }

        guard !values.isEmpty else { return nil }

        let average = values.reduce(0, +) / Double(values.count)
        return Int(average.rounded())
    }

    /// `[startOffset, endOffset]` 구간에 속한 고도 샘플의 양(+)의 변화량 합을 반환한다. 고도 샘플이 없으면 nil.
    private static func elevationGain(
        in route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)],
        from startOffset: TimeInterval,
        to endOffset: TimeInterval
    ) -> Double? {
        let altitudes = route
            .filter { $0.offset >= startOffset && $0.offset <= endOffset }
            .compactMap { $0.altitude }

        guard !altitudes.isEmpty else { return nil }

        var gain = 0.0
        for index in 1..<altitudes.count {
            let delta = altitudes[index] - altitudes[index - 1]
            if delta > 0 {
                gain += delta
            }
        }
        return gain
    }
}
