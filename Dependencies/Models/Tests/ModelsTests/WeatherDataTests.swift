@testable import Models
import Testing

@Suite("WeatherData.classify")
struct WeatherDataClassifyTests {

    @Test
    func sky_isCloudy_whenCloudCoverAtLeast60Percent() {
        let result = WeatherData.classify(
            temperature: 20, humidity: 50, windSpeed: 1, cloudCover: 0.7
        )
        #expect(result.sky == .cloudy)
    }

    @Test
    func sky_isSunny_whenCloudCoverBelow60Percent() {
        let result = WeatherData.classify(
            temperature: 20, humidity: 50, windSpeed: 1, cloudCover: 0.5
        )
        #expect(result.sky == .sunny)
    }

    @Test
    func sky_defaultsToSunny_whenCloudCoverUnknown() {
        let result = WeatherData.classify(temperature: 20, humidity: 50, windSpeed: 1)
        #expect(result.sky == .sunny)
    }

    @Test
    func wind_isWeak_whenBelow2() {
        let result = WeatherData.classify(temperature: 20, humidity: 50, windSpeed: 1.9)
        #expect(result.wind == .weak)
    }

    @Test
    func wind_isModerate_whenBelow5() {
        let result = WeatherData.classify(temperature: 20, humidity: 50, windSpeed: 4.9)
        #expect(result.wind == .moderate)
    }

    @Test
    func wind_isStrong_when5OrMore() {
        let result = WeatherData.classify(temperature: 20, humidity: 50, windSpeed: 5)
        #expect(result.wind == .strong)
    }

    @Test
    func feels_usesApparentTemperature_whenProvided() {
        let cold = WeatherData.classify(
            temperature: 25, humidity: 50, windSpeed: 1, apparentTemperature: 5
        )
        let hot = WeatherData.classify(
            temperature: 5, humidity: 50, windSpeed: 1, apparentTemperature: 30
        )
        #expect(cold.feels == .cold)
        #expect(hot.feels == .hot)
    }

    @Test
    func feels_fallsBackToTemperature_whenApparentMissing() {
        #expect(WeatherData.classify(temperature: 5, humidity: 50, windSpeed: 1).feels == .cold)
        #expect(WeatherData.classify(temperature: 18, humidity: 50, windSpeed: 1).feels == .neutral)
        #expect(WeatherData.classify(temperature: 28, humidity: 50, windSpeed: 1).feels == .hot)
    }

    @Test
    func humid_isHumid_whenHumidityAtLeast70() {
        #expect(WeatherData.classify(temperature: 20, humidity: 69, windSpeed: 1).humid == .dry)
        #expect(WeatherData.classify(temperature: 20, humidity: 70, windSpeed: 1).humid == .humid)
    }
}

@Suite("WeatherData init")
struct WeatherDataInitTests {

    @Test
    func convenienceInit_autoClassifiesFromRawValues() {
        let data = WeatherData(temperature: 25, humidity: 80, windSpeed: 6)
        #expect(data.skyCondition == .sunny)
        #expect(data.windLevel == .strong)
        #expect(data.feelsLike == .hot)
        #expect(data.humidityLevel == .humid)
    }

    @Test
    func convenienceInit_usesProvidedCloudCoverAndApparentTemperature() {
        let data = WeatherData(
            temperature: 25,
            humidity: 50,
            windSpeed: 1,
            cloudCover: 0.8,
            apparentTemperature: 5
        )
        #expect(data.skyCondition == .cloudy)
        #expect(data.feelsLike == .cold)
    }

    @Test
    func fullInit_preservesAllValues() {
        let data = WeatherData(
            temperature: 25,
            humidity: 80,
            windSpeed: 6,
            skyCondition: .cloudy,
            windLevel: .weak,
            feelsLike: .cold,
            humidityLevel: .dry
        )
        #expect(data.skyCondition == .cloudy)
        #expect(data.windLevel == .weak)
        #expect(data.feelsLike == .cold)
        #expect(data.humidityLevel == .dry)
    }
}
