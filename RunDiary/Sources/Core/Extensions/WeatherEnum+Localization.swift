//
//  WeatherEnum+Localization.swift
//  RunDiary
//

import Models

extension SkyCondition {
    var localizedName: String {
        switch self {
        case .sunny: return L10n.weatherSkySunny.value
        case .cloudy: return L10n.weatherSkyCloudy.value
        }
    }
}

extension WindLevel {
    var localizedName: String {
        switch self {
        case .weak: return L10n.weatherWindWeak.value
        case .moderate: return L10n.weatherWindModerate.value
        case .strong: return L10n.weatherWindStrong.value
        }
    }
}

extension FeelsLikeLevel {
    var localizedName: String {
        switch self {
        case .cold: return L10n.weatherFeelsCold.value
        case .neutral: return L10n.weatherFeelsNeutral.value
        case .hot: return L10n.weatherFeelsHot.value
        }
    }
}

extension HumidityLevel {
    var localizedName: String {
        switch self {
        case .dry: return L10n.weatherHumidDry.value
        case .humid: return L10n.weatherHumidHumid.value
        }
    }
}
