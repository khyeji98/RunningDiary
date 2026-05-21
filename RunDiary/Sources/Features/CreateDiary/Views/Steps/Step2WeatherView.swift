//
//  Step2WeatherView.swift
//  RunDiary
//

import ComposableArchitecture
import Models
import SwiftUI

struct Step2WeatherView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>

    var body: some View {
        VStack(spacing: 0) {
            StepTitleLabel(L10n.recordStepTitleWeather)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let weather = store.weather {
                        WeatherRawSummary(weather: weather)
                    }

                    SkyChipGroup(
                        selected: store.skyCondition
                    ) {
                        store.send(.updateSkyCondition($0))
                    }

                    WindChipGroup(
                        selected: store.windLevel
                    ) {
                        store.send(.updateWindLevel($0))
                    }

                    FeelsChipGroup(
                        selected: store.feelsLike
                    ) {
                        store.send(.updateFeelsLike($0))
                    }

                    HumidityChipGroup(
                        selected: store.humidityLevel
                    ) {
                        store.send(.updateHumidityLevel($0))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct WeatherRawSummary: View {
    let weather: WeatherData

    var body: some View {
        HStack(spacing: 12) {
            WeatherRawItem(label: L10n.weatherFieldTemperature.value, value: "\(Int(weather.temperature.rounded()))°")
            WeatherRawItem(label: L10n.weatherFieldHumidity.value, value: "\(weather.humidity)%")
            WeatherRawItem(label: L10n.weatherFieldWindSpeed.value, value: "\(Int(weather.windSpeed.rounded()))m/s")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray100.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct WeatherRawItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray500)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue700)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SkyChipGroup: View {
    let selected: SkyCondition?
    let onSelect: (SkyCondition) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("☁️")
                .font(.subheadline)
            HStack(spacing: 8) {
                ForEach(SkyCondition.allCases, id: \.self) { condition in
                    SelectableChip(
                        title: condition.localizedName,
                        isSelected: selected == condition
                    ) {
                        onSelect(condition)
                    }
                }
            }
        }
    }
}

private struct WindChipGroup: View {
    let selected: WindLevel?
    let onSelect: (WindLevel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💨")
                .font(.subheadline)
            HStack(spacing: 8) {
                ForEach(WindLevel.allCases, id: \.self) { level in
                    SelectableChip(
                        title: level.localizedName,
                        isSelected: selected == level
                    ) {
                        onSelect(level)
                    }
                }
            }
        }
    }
}

private struct FeelsChipGroup: View {
    let selected: FeelsLikeLevel?
    let onSelect: (FeelsLikeLevel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🌡️")
                .font(.subheadline)
            HStack(spacing: 8) {
                ForEach(FeelsLikeLevel.allCases, id: \.self) { level in
                    SelectableChip(
                        title: level.localizedName,
                        isSelected: selected == level
                    ) {
                        onSelect(level)
                    }
                }
            }
        }
    }
}

private struct HumidityChipGroup: View {
    let selected: HumidityLevel?
    let onSelect: (HumidityLevel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💧")
                .font(.subheadline)
            HStack(spacing: 8) {
                ForEach(HumidityLevel.allCases, id: \.self) { level in
                    SelectableChip(
                        title: level.localizedName,
                        isSelected: selected == level
                    ) {
                        onSelect(level)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("날씨 없음") {
    Step2WeatherView(
        store: Store(
            initialState: CreateDiaryFeature.State(healthKitWorkout: .preview)
        ) {
            CreateDiaryFeature()
        }
    )
}

#Preview("날씨 있음") {
    var state = CreateDiaryFeature.State(healthKitWorkout: .preview)
    let weather = WeatherData(temperature: 18, humidity: 60, windSpeed: 2)
    state.weather = weather
    state.skyCondition = weather.skyCondition
    state.windLevel = weather.windLevel
    state.feelsLike = weather.feelsLike
    state.humidityLevel = weather.humidityLevel

    return Step2WeatherView(
        store: Store(initialState: state) {
            CreateDiaryFeature()
        }
    )
}
