//
//  WorkoutSeriesBuilder.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/13/26.
//

import Foundation
import Models

/// 시작 후 경과초(offset)·값 샘플을 시계열 포인트로 가공하는 순수 계산 타입.
/// HealthKit 타입에 의존하지 않고 원시 값(offset, value)만 입출력하여 단위 테스트가 가능하다.
public enum WorkoutSeriesBuilder {
    /// 샘플을 `intervalSec` 버킷 단위로 평균낸 뒤 `maxPoints` 이하로 균등 축소한다.
    public static func downsample(
        _ samples: [(offset: TimeInterval, value: Double)],
        intervalSec: Int,
        maxPoints: Int = 500
    ) -> [SeriesPoint] {
        guard !samples.isEmpty, intervalSec > 0 else { return [] }

        var bucketSums: [Int: (sum: Double, count: Int)] = [:]
        for sample in samples {
            let bucket = Int(sample.offset / Double(intervalSec))
            var entry = bucketSums[bucket] ?? (sum: 0, count: 0)
            entry.sum += sample.value
            entry.count += 1
            bucketSums[bucket] = entry
        }

        let points = bucketSums.keys.sorted().compactMap { bucket -> SeriesPoint? in
            guard let entry = bucketSums[bucket] else { return nil }

            let average = entry.sum / Double(entry.count)
            return SeriesPoint(t: bucket * intervalSec, v: Int(average.rounded()))
        }

        return reduceToMaxPoints(points, maxPoints: maxPoints)
    }

    /// `points`가 `maxPoints`를 초과하면 균등 간격으로 골라 결정적으로 축소한다.
    private static func reduceToMaxPoints(_ points: [SeriesPoint], maxPoints: Int) -> [SeriesPoint] {
        guard points.count > maxPoints, maxPoints > 0 else { return points }

        let stride = Double(points.count) / Double(maxPoints)
        var reduced: [SeriesPoint] = []
        for index in 0..<maxPoints {
            let sourceIndex = min(Int(Double(index) * stride), points.count - 1)
            reduced.append(points[sourceIndex])
        }
        return reduced
    }
}
