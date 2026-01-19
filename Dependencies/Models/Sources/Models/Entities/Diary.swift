//
//  RunningRecord.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

public struct Diary: Identifiable, Equatable, Sendable {
    public let id: UUID                                 // 다이어리 고유 id
    public let yearMonthDay: YearMonthDay               // 다이어리 날짜
    public let distanceInKilometers: Double             // 달리기 거리 (km)
    public let durationInSeconds: TimeInterval          // 달리기 시간 (sec)
    public let averagePace: String                      // 평균 페이스 (min/km)
    public let averageHeartRate: Int                    // 평균 심박수 (bpm)
    public let averageCadence: Int                      // 평균 케이던스 (spm)
    public let painAreas: [PainArea]                    // 통증 부위
    public let runningStyle: RunninStyle?               // 달리기 스타일
    public let condition: RunningCondition              // 달리기 컨디션
    public let shoes: String?                           // 신발
    public let weather: WeatherData?                    // 날씨
    public let difficultyLevel: DifficultyLevel?        // 달리기 난이도
    public let routeData: Data?                         // 달리기 경로 데이터
    public let activeEnergyBurned: Double?              // 활동 에너지 소모량 (kcal)
    public let runningVerticalOscillation: Double?      // 수직 진폭 (cm)
    public let runningGroundContactTime: Double?        // 지면 접촉 시간 (ms)
    public let walkingStepLength: Double?               // 보폭 (m)
    public let hasMap: Bool                             // 지도 데이터 유무
    public let startTime: Date                          // 달리기 시작 시간
    public let endTime: Date                            // 달리기 종료 시간

    public var distanceInMiles: Double {
        durationInSeconds * 0.621371
    }

    public var formattedDuration: String {
        let hours = Int(durationInSeconds) / 3600
        let minutes = (Int(durationInSeconds) % 3600) / 60
        let seconds = Int(durationInSeconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    public init(
        id: UUID = UUID(),
        yearMonthDay: YearMonthDay,
        distanceInKilometers: Double,
        durationInSeconds: TimeInterval,
        averagePace: String,
        averageHeartRate: Int,
        averageCadence: Int,
        painAreas: [PainArea] = [],
        runningStyle: RunninStyle?,
        condition: RunningCondition = RunningCondition(),
        shoes: String? = nil,
        weather: WeatherData? = nil,
        difficultyLevel: DifficultyLevel? = nil,
        routeData: Data? = nil,
        activeEnergyBurned: Double? = nil,
        runningVerticalOscillation: Double? = nil,
        runningGroundContactTime: Double? = nil,
        walkingStepLength: Double? = nil,
        hasMap: Bool = false,
        startTime: Date,
        endTime: Date
    ) {
        self.id = id
        self.yearMonthDay = yearMonthDay
        self.distanceInKilometers = distanceInKilometers
        self.durationInSeconds = durationInSeconds
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.painAreas = painAreas
        self.runningStyle = runningStyle
        self.condition = condition
        self.shoes = shoes
        self.weather = weather
        self.difficultyLevel = difficultyLevel
        self.routeData = routeData
        self.activeEnergyBurned = activeEnergyBurned
        self.runningVerticalOscillation = runningVerticalOscillation
        self.runningGroundContactTime = runningGroundContactTime
        self.walkingStepLength = walkingStepLength
        self.hasMap = hasMap
        self.startTime = startTime
        self.endTime = endTime
    }
}
