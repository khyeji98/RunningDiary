//
//  HealthKitClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import ComposableArchitecture
import Foundation
import HealthKitService
import Models

@DependencyClient
struct HealthKitClient {
    var fetchRunningDataBetweenDates: @MainActor @Sendable (Date, Date) async throws -> [HealthKitWorkout]
    var fetchDetailedRunningData: @MainActor @Sendable (Date, Date) async throws -> DetailedWorkout?
}

extension HealthKitClient: DependencyKey {
    static let liveValue: HealthKitClient = .live()

    static func live(
        manager: HealthKitManagerProtocol = HealthKitManager()
    ) -> HealthKitClient {
        HealthKitClient(
            fetchRunningDataBetweenDates: { startDate, endDate in
                try await manager.fetchWeeklyRunningData(from: startDate, to: endDate)
            },
            fetchDetailedRunningData: { startDate, endDate in
                try await manager.fetchDetailedRunningData(from: startDate, to: endDate)
            }
        )
    }

    static let testValue = HealthKitClient(
        fetchRunningDataBetweenDates: unimplemented("\(Self.self).fetchRunningDataBetweenDates"),
        fetchDetailedRunningData: unimplemented("\(Self.self).fetchDetailedRunningData")
    )

    static let previewValue = HealthKitClient(
        fetchRunningDataBetweenDates: { _, _ in
            // Mock 주간 데이터 반환 (7일)
            (0..<7).map { index in
                // 일부 날짜는 데이터가 없도록 nil 반환
                let duration = Double.random(in: 1800...5400)
                return index % 3 == 0 ? nil : HealthKitWorkout(
                    distance: Double.random(in: 3.0...10.0),
                    duration: duration,
                    averagePace: "5'30\"",
                    averageHeartRate: Int.random(in: 140...170),
                    averageCadence: Int.random(in: 170...185),
                    activeEnergyBurned: Double.random(in: 300...600),
                    runningVerticalOscillation: Double.random(in: 7.0...9.0),
                    runningGroundContactTime: Double.random(in: 230...260),
                    walkingStepLength: Double.random(in: 0.9...1.2),
                    restingHeartRate: Double.random(in: 50...80),
                    runningPower: Double.random(in: 200...400),
                    runningStrideLength: Double.random(in: 0.9...1.2),
                    heartRateRecoveryOneMinute: Double.random(in: 15...30),
                    routeData: nil,
                    startDate: Calendar.current.date(byAdding: .second, value: Int(-duration), to: .now)!,
                    endDate: .now
                )
            }.compactMap { $0 }
        },
        fetchDetailedRunningData: { startDate, endDate in
            // 평균은 시계열에서 파생되므로, 원하는 평균값을 내려면 그 값 1개짜리 샘플을 주입한다.
            DetailedWorkout(
                distance: 5.2,
                duration: endDate.timeIntervalSince(startDate),
                averagePace: "5'30\"",
                heartRateSamples: [MetricSample(offsetSec: 0, value: 155)],
                cadenceSamples: [MetricSample(offsetSec: 0, value: 180)],
                runningVerticalOscillationSamples: [MetricSample(offsetSec: 0, value: 8.2)],
                runningGroundContactTimeSamples: [MetricSample(offsetSec: 0, value: 240)],
                walkingStepLengthSamples: [MetricSample(offsetSec: 0, value: 1.1)],
                runningPowerSamples: [MetricSample(offsetSec: 0, value: 300)],
                runningStrideLengthSamples: [MetricSample(offsetSec: 0, value: 1.1)],
                activeEnergyBurned: 450.0,
                restingHeartRate: 60.0,
                heartRateRecoveryOneMinute: 20.0,
                routeData: nil,
                startDate: startDate,
                endDate: endDate
            )
        }
    )
}

extension DependencyValues {
    var healthKitClient: HealthKitClient {
        get { self[HealthKitClient.self] }
        set { self[HealthKitClient.self] = newValue }
    }
}
