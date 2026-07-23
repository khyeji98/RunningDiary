//
//  Diary.swift
//  Models
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

public struct Diary: Identifiable, Equatable, Sendable {
    public let id: UUID                                 // 다이어리 고유 id
    public let workout: HealthKitWorkout
    public let painAreas: [PainArea]                    // 통증 부위
    public let runningStyle: RunninStyle?               // 달리기 스타일
    public let memo: String?                            // 메모
    public let shoes: String?                           // 신발
    public let weather: WeatherData?                    // 날씨 (WeatherKit 자동 조회 수치)
    public let userWeather: UserWeather?                // 유저가 선택한 날씨
    public let difficultyLevel: DifficultyLevel?        // 달리기 난이도

    public init(
        id: UUID = UUID(),
        workout: HealthKitWorkout,
        painAreas: [PainArea] = [],
        runningStyle: RunninStyle?,
        memo: String? = nil,
        shoes: String? = nil,
        weather: WeatherData? = nil,
        userWeather: UserWeather? = nil,
        difficultyLevel: DifficultyLevel? = nil
    ) {
        self.id = id
        self.workout = workout
        self.painAreas = painAreas
        self.runningStyle = runningStyle
        self.memo = memo
        self.shoes = shoes
        self.weather = weather
        self.userWeather = userWeather
        self.difficultyLevel = difficultyLevel
    }
}
