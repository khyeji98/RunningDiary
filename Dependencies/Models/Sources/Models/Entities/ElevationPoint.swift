//
//  ElevationPoint.swift
//  Models
//
//  Created by 김혜지 on 7/12/26.
//

public struct ElevationPoint: Equatable, Sendable, Codable {
    public let distanceM: Double
    public let altitude: Double

    public init(distanceM: Double, altitude: Double) {
        self.distanceM = distanceM
        self.altitude = altitude
    }
}
