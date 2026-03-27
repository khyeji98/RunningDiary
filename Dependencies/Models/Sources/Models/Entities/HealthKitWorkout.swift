//
//  HealthKitWorkout.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import Foundation

public struct HealthKitWorkout: Equatable, Identifiable, Sendable {
    public let id = UUID()
    public let yearMonthDay: YearMonthDay               // 달리기 날짜
    public let distance: Double                         // 달리기 거리 (km)
    public let duration: TimeInterval                   // 달리기 시간 (sec)
    public let averagePace: String                      // 평균 페이스 (min/km)
    public let averageHeartRate: Int                    // 평균 심박수 (bpm)
    public let averageCadence: Int                      // 평균 케이던스 (spm)
    public let activeEnergyBurned: Double               // 활동 에너지 소모량 (kcal)
    public let runningVerticalOscillation: Double       // 수직 진폭 (cm)
    public let runningGroundContactTime: Double         // 지면 접촉 시간 (ms)
    public let walkingStepLength: Double                // 보폭 (m)
    public let restingHeartRate: Double                 // 휴식 심박수 (bpm)
    public let runningPower: Double                     // 러닝 파워 (watts)
    public let runningStrideLength: Double              // 러닝 보폭 길이 (m)
    public let heartRateRecoveryOneMinute: Double       // 1분 심박수 회복 (bpm)
    public let routeData: Data?                         // 달리기 경로 데이터
    public let startTime: Date                          // 달리기 시작 시간
    public let endTime: Date                            // 달리기 종료 시간

    public var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    public var formattedDistance: String {
        distance == 0 ? "" : distance.to2f
    }

    public var formattedAverageHeartRate: String {
        averageHeartRate == 0 ? "" : averageHeartRate.toString
    }

    public var formattedAverageCadence: String {
        averageCadence == 0 ? "" : averageCadence.toString
    }

    public var formattedActiveEnergyBurned: String {
        activeEnergyBurned == 0 ? "" : activeEnergyBurned.to1f
    }

    public var formattedRunningPower: String {
        runningPower == 0 ? "" : runningPower.to0f
    }

    public var formattedVerticalOscillation: String {
        runningVerticalOscillation == 0 ? "" : runningVerticalOscillation.to1f
    }

    public var formattedGroundContactTime: String {
        runningGroundContactTime == 0 ? "" : runningGroundContactTime.to0f
    }

    public init(
        distance: Double,
        duration: TimeInterval,
        averagePace: String,
        averageHeartRate: Int,
        averageCadence: Int,
        activeEnergyBurned: Double,
        runningVerticalOscillation: Double,
        runningGroundContactTime: Double,
        walkingStepLength: Double,
        restingHeartRate: Double,
        runningPower: Double,
        runningStrideLength: Double,
        heartRateRecoveryOneMinute: Double,
        routeData: Data?,
        startDate: Date,
        endDate: Date
    ) {
        self.distance = distance
        self.yearMonthDay = YearMonthDay(date: startDate)
        self.duration = duration
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.activeEnergyBurned = activeEnergyBurned
        self.runningVerticalOscillation = runningVerticalOscillation
        self.runningGroundContactTime = runningGroundContactTime
        self.walkingStepLength = walkingStepLength
        self.restingHeartRate = restingHeartRate
        self.runningPower = runningPower
        self.runningStrideLength = runningStrideLength
        self.heartRateRecoveryOneMinute = heartRateRecoveryOneMinute
        self.routeData = routeData
        self.startTime = startDate
        self.endTime = endDate
    }

    /// routeData를 [Location] 배열로 디코딩합니다.
    public func decodeRouteData() -> [Location]? {
        guard let routeData = routeData else { return nil }
        return try? JSONDecoder().decode([Location].self, from: routeData)
    }
}
