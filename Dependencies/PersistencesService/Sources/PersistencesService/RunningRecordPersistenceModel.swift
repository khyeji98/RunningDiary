//
//  RunningRecordPersistenceModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models
import SwiftData

@Model
public final class RunningRecordPersistenceModel {
    @Attribute(.unique)
    public var id: UUID
    public var date: Date                               // 달리기 날짜
    public var distance: Double                         // 달리기 거리 (km)
    public var duration: TimeInterval                   // 달리기 시간 (sec)
    public var averagePace: String                      // 평균 페이스 (min/km)
    public var averageHeartRate: Int                    // 평균 심박수 (bpm)
    public var averageCadence: Int                      // 평균 케이던스 (spm)
    public var painAreasRawData: String?                // 통증 부위 (raw)
    public var runningStyleRaw: String?                 // 달리기 스타일 (raw)
    public var memo: String?                            // 메모
    public var shoes: String?                           // 신발
    public var temperature: Double?                     // 온도 (ºC)
    public var humidity: Int?                           // 습도 (%)
    public var windSpeed: Double?                       // 풍속 (m/s)
    public var difficultyLevelRaw: Int?                 // 달리기 난이도 (raw)
    public var routeData: Data?                         // 달리기 경로 데이터
    public var activeEnergyBurned: Double?              // 활동 에너지 소모량 (kcal)
    public var runningVerticalOscillation: Double?      // 수직 진폭 (cm)
    public var runningGroundContactTime: Double?        // 지면 접촉 시간 (ms)
    public var walkingStepLength: Double?               // 보폭 (m)
    public var restingHeartRate: Double?                // 휴식 심박수 (bpm)
    public var runningPower: Double?                    // 러닝 파워 (watts)
    public var runningStrideLength: Double?             // 러닝 보폭 길이 (m)
    public var heartRateRecoveryOneMinute: Double?      // 1분 심박수 회복 (bpm)
    public var startTime: Date                          // 달리기 시작 시간
    public var endTime: Date                            // 달리기 종료 시간

    public init(
        id: UUID = UUID(),
        date: Date = Date.now,
        distance: Double,
        duration: TimeInterval,
        averagePace: String,
        averageHeartRate: Int,
        averageCadence: Int,
        painAreasRaw: [String] = [],
        runningStyleRaw: String?,
        memo: String? = nil,
        shoes: String? = nil,
        temperature: Double? = nil,
        humidity: Int? = nil,
        windSpeed: Double? = nil,
        difficultyLevelRaw: Int? = nil,
        routeData: Data? = nil,
        activeEnergyBurned: Double? = nil,
        runningVerticalOscillation: Double? = nil,
        runningGroundContactTime: Double? = nil,
        walkingStepLength: Double? = nil,
        restingHeartRate: Double? = nil,
        runningPower: Double? = nil,
        runningStrideLength: Double? = nil,
        heartRateRecoveryOneMinute: Double? = nil,
        startTime: Date,
        endTime: Date
    ) {
        self.id = id
        self.date = date
        self.distance = distance
        self.duration = duration
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.runningStyleRaw = runningStyleRaw
        self.memo = memo
        self.shoes = shoes
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.difficultyLevelRaw = difficultyLevelRaw
        self.routeData = routeData
        self.activeEnergyBurned = activeEnergyBurned
        self.runningVerticalOscillation = runningVerticalOscillation
        self.runningGroundContactTime = runningGroundContactTime
        self.walkingStepLength = walkingStepLength
        self.restingHeartRate = restingHeartRate
        self.runningPower = runningPower
        self.runningStrideLength = runningStrideLength
        self.heartRateRecoveryOneMinute = heartRateRecoveryOneMinute
        self.startTime = startTime
        self.endTime = endTime

        self.painAreasRawData = PainAreasMapper.encodeRaw(painAreasRaw)
    }
}

// MARK: - Conversion Methods

public extension RunningRecordPersistenceModel {
    func toDomain() -> Diary {
        let weather: WeatherData?
        if let temp = temperature, let hum = humidity, let wind = windSpeed {
            weather = WeatherData(
                temperature: temp,
                humidity: hum,
                windSpeed: wind
            )
        } else {
            weather = nil
        }

        // Convert raw values to enums
        let painAreas = PainAreasMapper.decode(painAreasRawData)
        let runningStyle = runningStyleRaw.flatMap { RunninStyle(rawValue: $0) }
        let difficultyLevel = difficultyLevelRaw.flatMap { DifficultyLevel(rawValue: $0) }

        return Diary(
            id: id,
            workout: HealthKitWorkout(
                distance: distance,
                duration: duration,
                averagePace: averagePace,
                averageHeartRate: averageHeartRate,
                averageCadence: averageCadence,
                activeEnergyBurned: activeEnergyBurned ?? 0,
                runningVerticalOscillation: runningVerticalOscillation ?? 0,
                runningGroundContactTime: runningGroundContactTime ?? 0,
                walkingStepLength: walkingStepLength ?? 0,
                restingHeartRate: restingHeartRate ?? 0,
                runningPower: runningPower ?? 0,
                runningStrideLength: runningStrideLength ?? 0,
                heartRateRecoveryOneMinute: heartRateRecoveryOneMinute ?? 0,
                routeData: routeData,
                startDate: startTime,
                endDate: endTime
            ),
            painAreas: painAreas,
            runningStyle: runningStyle,
            memo: memo,
            shoes: shoes,
            weather: weather,
            difficultyLevel: difficultyLevel
        )
    }

    static func fromDomain(_ record: Diary) -> RunningRecordPersistenceModel {
        RunningRecordPersistenceModel(
            id: record.id,
            date: record.workout.yearMonthDay.toDate(),
            distance: record.workout.distance,
            duration: record.workout.duration,
            averagePace: record.workout.averagePace,
            averageHeartRate: record.workout.averageHeartRate,
            averageCadence: record.workout.averageCadence,
            painAreasRaw: record.painAreas.map { $0.rawValue },
            runningStyleRaw: record.runningStyle?.rawValue,
            memo: record.memo,
            shoes: record.shoes,
            temperature: record.weather?.temperature,
            humidity: record.weather?.humidity,
            windSpeed: record.weather?.windSpeed,
            difficultyLevelRaw: record.difficultyLevel?.rawValue,
            routeData: record.workout.routeData,
            activeEnergyBurned: record.workout.activeEnergyBurned,
            runningVerticalOscillation: record.workout.runningVerticalOscillation,
            runningGroundContactTime: record.workout.runningGroundContactTime,
            walkingStepLength: record.workout.walkingStepLength,
            restingHeartRate: record.workout.restingHeartRate,
            runningPower: record.workout.runningPower,
            runningStrideLength: record.workout.runningStrideLength,
            heartRateRecoveryOneMinute: record.workout.heartRateRecoveryOneMinute,
            startTime: record.workout.startTime,
            endTime: record.workout.endTime
        )
    }
}

// MARK: - Preview

public extension RunningRecordPersistenceModel {
    private static func date(
        calendar: Calendar = Calendar.current,
        timeZone: TimeZone = TimeZone(identifier: "Asia/Seoul")!,
        year: Int, month: Int, day: Int
    ) -> Date {
        let dateComponent = DateComponents(
            calendar: calendar, timeZone: timeZone, year: year, month: month, day: day)
        let date = calendar.date(from: dateComponent)
        return date ?? Date.now
    }

    static var preview: RunningRecordPersistenceModel {
        RunningRecordPersistenceModel(
            id: UUID(),
            distance: 5.32,
            duration: 1800,
            averagePace: "5'40\"",
            averageHeartRate: 148,
            averageCadence: 172,
            painAreasRaw: ["무릎", "종아리"],
            runningStyleRaw: "Midfoot",
            memo: "상쾌한 아침 러닝이었음. 후반부에 약간 무릎 통증.",
            shoes: "Nike Zoom Fly 5",
            temperature: 18.5,
            humidity: 62,
            windSpeed: 3.2,
            difficultyLevelRaw: 4,
            routeData: nil,
            activeEnergyBurned: 450.0,
            runningVerticalOscillation: 8.2,
            runningGroundContactTime: 240.0,
            walkingStepLength: 1.1,
            startTime: .now,
            endTime: Calendar.current.date(byAdding: .second, value: 1800, to: .now)!
        )
    }

    static var previewRecords: [RunningRecordPersistenceModel] {
        [
            RunningRecordPersistenceModel(
                id: UUID(),
                date: date(year: 2025, month: 10, day: 15),
                distance: 5.0,
                duration: 1780,
                averagePace: "5'55\"",
                averageHeartRate: 152,
                averageCadence: 170,
                painAreasRaw: ["발목"],
                runningStyleRaw: "Forefoot",
                memo: "기온이 약간 높았지만 페이스 유지에 성공.",
                shoes: "ASICS Metaspeed Sky",
                temperature: 21.0,
                humidity: 58,
                windSpeed: 2.1,
                difficultyLevelRaw: 4,
                routeData: nil,
                activeEnergyBurned: 380.0,
                runningVerticalOscillation: 8.0,
                runningGroundContactTime: 235.0,
                walkingStepLength: 1.0,
                startTime: date(year: 2025, month: 10, day: 15),
                endTime: Calendar.current.date(byAdding: .second, value: 1780, to: date(year: 2025, month: 10, day: 15))!
            ),
            RunningRecordPersistenceModel(
                id: UUID(),
                date: date(year: 2025, month: 10, day: 18),
                distance: 7.8,
                duration: 2600,
                averagePace: "5'20\"",
                averageHeartRate: 155,
                averageCadence: 176,
                painAreasRaw: [],
                runningStyleRaw: "Midfoot",
                memo: "페이스 좋았음. 마지막 1km에서 스퍼트.",
                shoes: "Nike Pegasus 40",
                temperature: 17.2,
                humidity: 65,
                windSpeed: 3.4,
                difficultyLevelRaw: 5,
                routeData: nil,
                activeEnergyBurned: 620.0,
                runningVerticalOscillation: 8.5,
                runningGroundContactTime: 230.0,
                walkingStepLength: 1.2,
                startTime: date(year: 2025, month: 10, day: 18),
                endTime: Calendar.current.date(byAdding: .second, value: 2600, to: date(year: 2025, month: 10, day: 18))!
            ),
            RunningRecordPersistenceModel(
                id: UUID(),
                distance: 3.5,
                duration: 1200,
                averagePace: "5'45\"",
                averageHeartRate: 140,
                averageCadence: 168,
                painAreasRaw: ["허벅지"],
                runningStyleRaw: "Rearfoot",
                memo: "전날 술 때문에 컨디션이 안 좋았음.",
                shoes: "Adidas Adizero Boston 12",
                temperature: 19.5,
                humidity: 70,
                windSpeed: 2.8,
                difficultyLevelRaw: 2,
                routeData: nil,
                activeEnergyBurned: 280.0,
                runningVerticalOscillation: 7.5,
                runningGroundContactTime: 250.0,
                walkingStepLength: 0.95,
                startTime: .now,
                endTime: Calendar.current.date(byAdding: .second, value: 1200, to: .now)!
            ),
            RunningRecordPersistenceModel.preview,
            RunningRecordPersistenceModel(
                id: UUID(),
                distance: 10.0,
                duration: 3600,
                averagePace: "6'00\"",
                averageHeartRate: 150,
                averageCadence: 165,
                painAreasRaw: [],
                runningStyleRaw: nil,
                memo: nil,
                shoes: nil,
                temperature: nil,
                humidity: nil,
                windSpeed: nil,
                difficultyLevelRaw: nil,
                routeData: nil,
                activeEnergyBurned: nil,
                runningVerticalOscillation: nil,
                runningGroundContactTime: nil,
                walkingStepLength: nil,
                startTime: date(year: 2025, month: 11, day: 1),
                endTime: Calendar.current.date(byAdding: .second, value: 3600, to: date(year: 2025, month: 11, day: 1))!
            ),
        ]
    }
}
