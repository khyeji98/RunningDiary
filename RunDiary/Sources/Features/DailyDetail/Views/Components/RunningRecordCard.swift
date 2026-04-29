//
//  RunningRecordCard.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import CommonFoundation
import MapKit
import Models
import SwiftUI

struct RunningRecordCard: View {
    let record: Diary
    let onEdit: () -> Void

    init(
        record: Diary,
        onEdit: @escaping () -> Void
    ) {
        self.record = record
        self.onEdit = onEdit
    }

    var body: some View {
        VStack(spacing: 16) {
            TopSection(record: record)
            ExpandedContentView(record: record)
        }
        .padding(20)
        .liquidGlass()
    }
}

// MARK: - Private Subviews

private struct TopSection: View {
    let record: Diary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. Header: Time
            HStack {
                Spacer()

                Text(record.workout.startTime.formattedString(formatter: .hourMinutes))
                    .font(.subheadline)
                    .foregroundStyle(.gray500)
            }

            // 2. Hero: Distance & Summary (The Title)
            L10n.recordHeroSummary.text(
                record.workout.distance.to2f,
                record.workout.formattedDuration
            )
            .font(.system(size: 30))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 8)

        }
    }
}

private struct ExpandedContentView: View {
    let record: Diary

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    private var hasEnvironmentData: Bool {
        record.weather != nil ||
        record.shoes != nil ||
        record.runningStyle != nil ||
        record.difficultyLevel != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 1. Detailed Performance (Grid) - Moved to top
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: L10n.recordSectionPerformance.value)

                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                    RecordVerticalRow(
                        title: L10n.recordFieldPace.value,
                        value: record.workout.averagePace
                    )
                    RecordVerticalRow(
                        title: L10n.recordFieldHeartRate.value,
                        value: "\(record.workout.averageHeartRate) bpm"
                    )
                    RecordVerticalRow(
                        title: L10n.recordFieldCadence.value,
                        value: "\(record.workout.averageCadence) spm"
                    )

                    if record.workout.activeEnergyBurned > 0 {
                        RecordVerticalRow(
                            title: L10n.recordFieldActiveEnergy.value,
                            value: String(format: "%.0f kcal", record.workout.activeEnergyBurned)
                        )
                    }

                    if record.workout.runningPower > 0 {
                        RecordVerticalRow(
                            title: L10n.recordFieldRunningPower.value,
                            value: "\(Int(record.workout.runningPower))W"
                        )
                    }

                    if record.workout.runningVerticalOscillation > 0 {
                        RecordVerticalRow(
                            title: L10n.recordFieldVerticalOscillation.value,
                            value: "\(String(format: "%.1f", record.workout.runningVerticalOscillation)) cm"
                        )
                    }

                    if record.workout.runningGroundContactTime > 0 {
                        RecordVerticalRow(
                            title: L10n.recordFieldGroundContactTime.value,
                            value: "\(Int(record.workout.runningGroundContactTime)) ms"
                        )
                    }
                }
            }

            // 3. Pain Area Stickers - Only show if pain areas exist
            if !record.painAreas.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: L10n.recordSectionPain.value)
                    DynamicGridLayout(items: record.painAreas, spacing: 8) { area in
                        StickerView(text: area.localizedName, color: .red)
                    }
                }
            }

            // 4. Environment - Combined Sentence
            if hasEnvironmentData {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: L10n.recordSectionHowRun.value)

                    // Build combined sentence
                    EnvironmentSentenceView(record: record)
                }
            }

            // 5. Diary Entry (Memo) - Moved to bottom
            if let memo = record.memo, !memo.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .foregroundStyle(.gray300)

                    Text(memo)
                        .font(.custom("Georgia", size: 17)) // Serif font for diary feel
                        .lineSpacing(6)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "quote.closing")
                        .foregroundStyle(.gray300)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(16)
                .background(Color.yellow.opacity(0.05)) // Pale yellow paper look
                .cornerRadius(12)
            }

            // 6. Route Map Section (경로 데이터가 있을 때만)
            if let routeData = record.workout.routeData,
               let locations = try? JSONDecoder().decode([Location].self, from: routeData),
               !locations.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                RouteMapSection(
                    weather: record.weather,
                    locations: locations
                )
            }
        }
    }
}

// MARK: - Route Map Section

private struct RouteMapSection: View {
    let weather: WeatherData?
    let locations: [Location]

    private var coordinates: [CLLocationCoordinate2D] {
        locations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 날씨 라벨 (기온, 습도, 풍속)
            if let weather = weather {
                HStack(spacing: 12) {
                    Label("\(Int(weather.temperature))°", systemImage: "thermometer.medium")
                    Label("\(Int(weather.humidity))%", systemImage: "humidity")
                    Label("\(Int(weather.windSpeed))m/s", systemImage: "wind")
                }
                .font(.subheadline)
                .foregroundStyle(.gray500)
            }

            // 지도
            RouteMapView(coordinates: coordinates)
                .frame(height: 200)
                .cornerRadius(12)
        }
    }
}

private struct EnvironmentSentenceView: View {
    let record: Diary

    @Environment(\.locale) private var locale
    @State private var shoesName: String?

    private var isEnglish: Bool {
        locale.language.languageCode?.identifier == "en"
    }

    private var styleName: String? {
        record.runningStyle?.localizedName
    }

    private var difficultyAdverb: String? {
        record.difficultyLevel?.adverbText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let shoes = shoesName {
                ShoesRow(shoes: shoes, isEnglish: isEnglish)
            }

            if let style = styleName {
                StyleRow(style: style, isEnglish: isEnglish)
            }

            if let difficulty = difficultyAdverb {
                DifficultyRow(difficulty: difficulty, isEnglish: isEnglish)
            }
        }
        .font(.body)
        .task(id: record.shoes) {
            guard let id = record.shoes, !id.isEmpty else {
                shoesName = nil
                return
            }
            shoesName = await ShoeCache.shared.shoe(id: id)?.name
        }
    }
}

// MARK: - EnvironmentSentenceView Subviews

private struct ShoesRow: View {
    let shoes: String
    let isEnglish: Bool

    var body: some View {
        if isEnglish {
            // English: "Wearing [shoes],"
            HStack(spacing: 4) {
                Text(L10n.recordSentenceWearing.value)
                    .foregroundStyle(.primary)
                StickerView(text: shoes, color: .green)
            }
        } else {
            // Korean/Japanese: "[shoes]을 신고," / "[shoes]を履いて、"
            HStack(spacing: 4) {
                StickerView(text: shoes, color: .green)
                Text(L10n.recordSentenceWearing.value)
                    .foregroundStyle(.primary)
            }
        }
    }
}

private struct StyleRow: View {
    let style: String
    let isEnglish: Bool

    var body: some View {
        if isEnglish {
            // English: "with [style],"
            HStack(spacing: 4) {
                Text(L10n.recordSentenceStyle.value)
                    .foregroundStyle(.primary)
                StickerView(text: style, color: .teal)
            }
        } else {
            // Korean/Japanese: "[style]으로," / "[style]で、"
            HStack(spacing: 4) {
                StickerView(text: style, color: .teal)
                Text(L10n.recordSentenceStyle.value)
                    .foregroundStyle(.primary)
            }
        }
    }
}

private struct DifficultyRow: View {
    let difficulty: String
    let isEnglish: Bool

    var body: some View {
        if isEnglish {
            // English: "I ran [difficulty]!"
            HStack(spacing: 4) {
                Text(L10n.recordSummaryEnding.value)
                    .foregroundStyle(.primary)
                StickerView(text: difficulty, color: .orange)
            }
        } else {
            // Korean: "[difficulty] 달렸어요!" / Japanese: "[difficulty]走りました！"
            HStack(spacing: 4) {
                StickerView(text: difficulty, color: .orange)
                Text(L10n.recordSummaryEnding.value)
                    .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - Sticker View
struct StickerView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Extensions

extension DifficultyLevel {
    var adverbText: String {
        switch self {
        case .veryEasy: return L10n.difficultyAdverbVeryEasy.value
        case .easy: return L10n.difficultyAdverbEasy.value
        case .medium: return L10n.difficultyAdverbMedium.value
        case .hard: return L10n.difficultyAdverbHard.value
        case .veryHard: return L10n.difficultyAdverbVeryHard.value
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .bold()
            .foregroundStyle(.gray700)
            .padding(.bottom, 2)
    }
}

#Preview {
    // 샘플 경로 데이터 (서울 올림픽공원 주변)
    let sampleLocations = [
        Location(latitude: 37.5209, longitude: 127.1230),
        Location(latitude: 37.5215, longitude: 127.1240),
        Location(latitude: 37.5220, longitude: 127.1255),
        Location(latitude: 37.5225, longitude: 127.1270),
        Location(latitude: 37.5218, longitude: 127.1285),
        Location(latitude: 37.5210, longitude: 127.1275),
        Location(latitude: 37.5205, longitude: 127.1260),
        Location(latitude: 37.5209, longitude: 127.1230),
    ]
    let routeData = try? JSONEncoder().encode(sampleLocations)

    return ScrollView(.vertical) {
        VStack {
            RunningRecordCard(
                record: Diary(
                    workout: HealthKitWorkout(
                        distance: 5.23,
                        duration: 1935,
                        averagePace: "6'10\"",
                        averageHeartRate: 156,
                        averageCadence: 178,
                        activeEnergyBurned: 450.0,
                        runningVerticalOscillation: 8.2,
                        runningGroundContactTime: 240.0,
                        walkingStepLength: 1.1,
                        restingHeartRate: 55.0,
                        runningPower: 280.0,
                        runningStrideLength: 1.25,
                        heartRateRecoveryOneMinute: 25.0,
                        routeData: routeData,
                        startDate: Date(),
                        endDate: Date().addingTimeInterval(1935)
                    ),
                    painAreas: [.knee, .shin],
                    runningStyle: .midfoot,
                    memo: "Good run!",
                    shoes: "nike-alphafly-3",
                    weather: WeatherData(temperature: 18, humidity: 60, windSpeed: 32),
                    difficultyLevel: .hard
                )
            ) {}
            .padding()
        }
    }
    .background(Color.gray50)
}
