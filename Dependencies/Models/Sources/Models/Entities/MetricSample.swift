//
//  MetricSample.swift
//  Models
//
//  Created by 김혜지 on 7/16/26.
//

import Foundation

/// 워크아웃 구간 내 단일 지표 샘플. 값의 단위는 이 샘플을 보유한 `HealthKitWorkout`의 각 프로퍼티 주석이 정의한다.
/// 서버 전송용 `SeriesPoint`(Int, 다운샘플 결과)와 달리 원본 Double 정밀도를 보존한다.
public struct MetricSample: Equatable, Sendable {
    public let offsetSec: TimeInterval    // 워크아웃 시작 후 경과 초
    public let value: Double

    public init(offsetSec: TimeInterval, value: Double) {
        self.offsetSec = offsetSec
        self.value = value
    }

    /// 샘플 값의 산술평균. 비어 있으면 nil.
    /// `offsetSec`은 가중치로 쓰이지 않으며, `HKStatisticsQuery(.discreteAverage)`와 동일한 정의다.
    public static func average(of samples: [MetricSample]) -> Double? {
        guard !samples.isEmpty else { return nil }

        let total = samples.reduce(0) { $0 + $1.value }
        return total / Double(samples.count)
    }
}
