//
//  WorkoutSeries.swift
//  Models
//
//  Created by 김혜지 on 7/12/26.
//

public struct WorkoutSeries: Equatable, Sendable, Codable {
    public let sampleIntervalSec: Int?
    public let heartRate: [SeriesPoint]
    public let paceSecondsPerKm: [SeriesPoint]
    public let cadence: [SeriesPoint]
    public let elevation: [ElevationPoint]

    public init(
        sampleIntervalSec: Int?,
        heartRate: [SeriesPoint],
        paceSecondsPerKm: [SeriesPoint],
        cadence: [SeriesPoint],
        elevation: [ElevationPoint]
    ) {
        self.sampleIntervalSec = sampleIntervalSec
        self.heartRate = heartRate
        self.paceSecondsPerKm = paceSecondsPerKm
        self.cadence = cadence
        self.elevation = elevation
    }
}
