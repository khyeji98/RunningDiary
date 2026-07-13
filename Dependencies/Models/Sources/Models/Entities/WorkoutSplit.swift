//
//  WorkoutSplit.swift
//  Models
//
//  Created by 김혜지 on 7/12/26.
//

public struct WorkoutSplit: Equatable, Sendable, Codable {
    public let index: Int                    // 1부터
    public let distanceKm: Double            // 마지막 구간 <1.0 가능
    public let durationSec: Double
    public let paceSecondsPerKm: Int
    public let averageHeartRate: Int?        // 구간 내 샘플 없으면 nil
    public let averageCadence: Int?
    public let elevationGainM: Double?

    public init(
        index: Int,
        distanceKm: Double,
        durationSec: Double,
        paceSecondsPerKm: Int,
        averageHeartRate: Int?,
        averageCadence: Int?,
        elevationGainM: Double?
    ) {
        self.index = index
        self.distanceKm = distanceKm
        self.durationSec = durationSec
        self.paceSecondsPerKm = paceSecondsPerKm
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.elevationGainM = elevationGainM
    }
}
