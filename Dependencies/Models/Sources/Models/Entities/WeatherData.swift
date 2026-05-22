//
//  WeatherData.swift
//  Models
//
//  Created by 김혜지 on 10/31/25.
//

public struct WeatherData: Equatable, Sendable {
    public let temperature: Double  // 기온 (°C)
    public let humidity: Int        // 습도 (%)
    public let windSpeed: Double    // 풍속 (m/s)

    public let skyCondition: SkyCondition
    public let windLevel: WindLevel
    public let feelsLike: FeelsLikeLevel
    public let humidityLevel: HumidityLevel

    public init(
        temperature: Double,
        humidity: Int,
        windSpeed: Double,
        skyCondition: SkyCondition,
        windLevel: WindLevel,
        feelsLike: FeelsLikeLevel,
        humidityLevel: HumidityLevel
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.skyCondition = skyCondition
        self.windLevel = windLevel
        self.feelsLike = feelsLike
        self.humidityLevel = humidityLevel
    }

    public init(
        temperature: Double,
        humidity: Int,
        windSpeed: Double
    ) {
        self.init(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed,
            cloudCover: nil,
            apparentTemperature: nil
        )
    }

    public init(
        temperature: Double,
        humidity: Int,
        windSpeed: Double,
        cloudCover: Double?,
        apparentTemperature: Double?
    ) {
        let classified = Self.classify(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed,
            cloudCover: cloudCover,
            apparentTemperature: apparentTemperature
        )
        self.init(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed,
            skyCondition: classified.sky,
            windLevel: classified.wind,
            feelsLike: classified.feels,
            humidityLevel: classified.humid
        )
    }

    public struct Classification: Equatable, Sendable {
        public let sky: SkyCondition
        public let wind: WindLevel
        public let feels: FeelsLikeLevel
        public let humid: HumidityLevel

        public init(
            sky: SkyCondition,
            wind: WindLevel,
            feels: FeelsLikeLevel,
            humid: HumidityLevel
        ) {
            self.sky = sky
            self.wind = wind
            self.feels = feels
            self.humid = humid
        }
    }

    public static func classify(
        temperature: Double,
        humidity: Int,
        windSpeed: Double,
        cloudCover: Double? = nil,
        apparentTemperature: Double? = nil
    ) -> Classification {
        let sky: SkyCondition = (cloudCover ?? 0) >= 0.6 ? .cloudy : .sunny

        let wind: WindLevel = windSpeed < 2
            ? .weak
            : (windSpeed < 5 ? .moderate : .strong)

        let feelsTemp = apparentTemperature ?? temperature
        let feels: FeelsLikeLevel = feelsTemp < 12
            ? .cold
            : (feelsTemp < 24 ? .neutral : .hot)

        let humid: HumidityLevel = humidity >= 70 ? .humid : .dry

        return Classification(sky: sky, wind: wind, feels: feels, humid: humid)
    }
}
