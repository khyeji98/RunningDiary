//
//  DetailedWorkout.swift
//  Models
//
//  Created by 김혜지 on 7/16/26.
//

import Foundation

/// HealthKit 상세 조회 결과. 평균 지표를 저장하지 않고 원시 시계열에서 파생한다.
/// SwiftData 영속 왕복 타입인 `HealthKitWorkout`과 달리 원시 샘플을 보유하며,
/// 표시·저장 경로로 넘길 때 `toHealthKitWorkout()`으로 변환한다.
public struct DetailedWorkout: Equatable, Identifiable, Sendable {
    public let id: UUID                                          // 고유 식별자 (HKWorkout.uuid)
    public let distance: Double                                 // 달리기 거리 (km)
    public let duration: TimeInterval                           // 달리기 시간 (sec)
    public let averagePace: String                             // 평균 페이스 (min/km, "5'30\"")

    // MARK: 시계열 (평균은 computed로 파생)
    public let heartRateSamples: [MetricSample]                     // bpm
    public let cadenceSamples: [MetricSample]                       // spm
    public let runningVerticalOscillationSamples: [MetricSample]    // cm
    public let runningGroundContactTimeSamples: [MetricSample]      // ms
    public let walkingStepLengthSamples: [MetricSample]             // m
    public let runningPowerSamples: [MetricSample]                  // watts
    public let runningStrideLengthSamples: [MetricSample]           // m

    // MARK: 비시계열 스칼라 (워크아웃 구간 밖 집계라 시계열화 대상 아님)
    public let activeEnergyBurned: Double                       // 활동 에너지 소모량 (kcal)
    public let restingHeartRate: Double                        // 휴식 심박수 (bpm, 해당 날짜 하루 집계)
    public let heartRateRecoveryOneMinute: Double              // 1분 심박수 회복 (bpm, 종료 후 5분 구간 집계)

    public let routeData: Data?                                 // 달리기 경로 데이터 ([Location] JSON)
    public let startTime: Date                                 // 달리기 시작 시간
    public let endTime: Date                                   // 달리기 종료 시간
    public let splits: [WorkoutSplit]                          // 구간별 요약
    public let series: WorkoutSeries?                          // 서버 전송용 다운샘플 시계열

    // MARK: - 파생 평균

    /// 심박수 시계열의 산술평균. `Int.init`은 소수부를 버림한다(반올림 아님). 샘플이 없으면 0.
    public var averageHeartRate: Int {
        MetricSample.average(of: heartRateSamples).map(Int.init) ?? 0
    }

    /// 케이던스 시계열의 산술평균. `Int.init`은 소수부를 버림한다(반올림 아님). 샘플이 없으면 0.
    public var averageCadence: Int {
        MetricSample.average(of: cadenceSamples).map(Int.init) ?? 0
    }

    public var runningVerticalOscillation: Double {
        MetricSample.average(of: runningVerticalOscillationSamples) ?? 0
    }

    public var runningGroundContactTime: Double {
        MetricSample.average(of: runningGroundContactTimeSamples) ?? 0
    }

    public var walkingStepLength: Double {
        MetricSample.average(of: walkingStepLengthSamples) ?? 0
    }

    public var runningPower: Double {
        MetricSample.average(of: runningPowerSamples) ?? 0
    }

    public var runningStrideLength: Double {
        MetricSample.average(of: runningStrideLengthSamples) ?? 0
    }

    public init(
        id: UUID = UUID(),
        distance: Double,
        duration: TimeInterval,
        averagePace: String,
        heartRateSamples: [MetricSample] = [],
        cadenceSamples: [MetricSample] = [],
        runningVerticalOscillationSamples: [MetricSample] = [],
        runningGroundContactTimeSamples: [MetricSample] = [],
        walkingStepLengthSamples: [MetricSample] = [],
        runningPowerSamples: [MetricSample] = [],
        runningStrideLengthSamples: [MetricSample] = [],
        activeEnergyBurned: Double = 0,
        restingHeartRate: Double = 0,
        heartRateRecoveryOneMinute: Double = 0,
        routeData: Data? = nil,
        startDate: Date,
        endDate: Date,
        splits: [WorkoutSplit] = [],
        series: WorkoutSeries? = nil
    ) {
        self.id = id
        self.distance = distance
        self.duration = duration
        self.averagePace = averagePace
        self.heartRateSamples = heartRateSamples
        self.cadenceSamples = cadenceSamples
        self.runningVerticalOscillationSamples = runningVerticalOscillationSamples
        self.runningGroundContactTimeSamples = runningGroundContactTimeSamples
        self.walkingStepLengthSamples = walkingStepLengthSamples
        self.runningPowerSamples = runningPowerSamples
        self.runningStrideLengthSamples = runningStrideLengthSamples
        self.activeEnergyBurned = activeEnergyBurned
        self.restingHeartRate = restingHeartRate
        self.heartRateRecoveryOneMinute = heartRateRecoveryOneMinute
        self.routeData = routeData
        self.startTime = startDate
        self.endTime = endDate
        self.splits = splits
        self.series = series
    }
}
