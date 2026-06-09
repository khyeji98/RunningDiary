//
//  UserWeather.swift
//  Models
//
//  Created by 김혜지 on 6/9/26.
//

/// 일기 작성 시 유저가 직접 선택하는 날씨 데이터
/// (WeatherKit으로 자동 조회되는 수치 데이터 `WeatherData`와 구분)
public struct UserWeather: Equatable, Sendable {
    public let skyCondition: SkyCondition?    // 하늘 상태
    public let windLevel: WindLevel?          // 바람 세기
    public let feelsLike: FeelsLikeLevel?     // 체감 온도
    public let humidityLevel: HumidityLevel?  // 습도 체감

    public init(
        skyCondition: SkyCondition? = nil,
        windLevel: WindLevel? = nil,
        feelsLike: FeelsLikeLevel? = nil,
        humidityLevel: HumidityLevel? = nil
    ) {
        self.skyCondition = skyCondition
        self.windLevel = windLevel
        self.feelsLike = feelsLike
        self.humidityLevel = humidityLevel
    }
}
