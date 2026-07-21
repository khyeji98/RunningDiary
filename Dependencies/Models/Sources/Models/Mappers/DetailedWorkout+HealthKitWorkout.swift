//
//  DetailedWorkout+HealthKitWorkout.swift
//  Models
//
//  Created by 김혜지 on 7/16/26.
//

public extension DetailedWorkout {
    /// 표시·저장 경로(`Diary.workout`, SwiftData 왕복)로 넘기기 위한 변환.
    /// 시계열에서 파생된 평균 지표가 이 시점에 스칼라 스냅샷으로 고정된다.
    func toHealthKitWorkout() -> HealthKitWorkout {
        HealthKitWorkout(
            id: id,
            distance: distance,
            duration: duration,
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
            startDate: startTime,
            endDate: endTime,
            splits: splits,
            series: series
        )
    }
}
