//
//  HealthKitWorkout+Preview.swift
//  RunDiary
//

import Foundation
import Models

extension HealthKitWorkout {
    static var preview: HealthKitWorkout {
        HealthKitWorkout(
            distance: 5.32,
            duration: 1860,
            averagePace: "5'50\"",
            averageHeartRate: 148,
            averageCadence: 172,
            activeEnergyBurned: 450.0,
            runningVerticalOscillation: 8.2,
            runningGroundContactTime: 240.0,
            walkingStepLength: 1.1,
            restingHeartRate: 58.0,
            runningPower: 245.0,
            runningStrideLength: 1.2,
            heartRateRecoveryOneMinute: 22.0,
            routeData: nil,
            startDate: .now,
            endDate: Calendar.current.date(byAdding: .second, value: 1860, to: .now)!
        )
    }
}
