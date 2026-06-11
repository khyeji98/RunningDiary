//
//  UserWeatherMigrationTests.swift
//  PersistencesService
//
//  Created by 김혜지 on 6/9/26.
//

import Foundation
import Models
import SwiftData
import Testing

@testable import PersistencesService

// MARK: - V3 Schema (테스트용 — 유저 선택 날씨 필드가 없는 상태)
//
// V3은 날씨 재분류 필드를 모두 제거한 스키마다. V4에서 "유저가 직접 선택하는 날씨"
// 용도로 4개 필드(skyConditionRaw 등)가 다시 추가되었으므로,
// V3로 저장한 데이터가 V4로 lightweight migration 되는지 검증한다.

enum LegacySchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [RunningRecordPersistenceModel.self]
    }

    @Model
    final class RunningRecordPersistenceModel {
        @Attribute(.unique) var id: UUID
        var date: Date
        var distance: Double
        var duration: TimeInterval
        var averagePace: String
        var averageHeartRate: Int
        var averageCadence: Int
        var painAreasRawData: String?
        var runningStyleRaw: String?
        var memo: String?
        var shoes: String?
        var temperature: Double?
        var humidity: Int?
        var windSpeed: Double?
        var difficultyLevelRaw: Int?
        var routeData: Data?
        var activeEnergyBurned: Double?
        var runningVerticalOscillation: Double?
        var runningGroundContactTime: Double?
        var walkingStepLength: Double?
        var restingHeartRate: Double?
        var runningPower: Double?
        var runningStrideLength: Double?
        var heartRateRecoveryOneMinute: Double?
        var startTime: Date
        var endTime: Date

        init() {
            self.id = UUID()
            self.date = Date.now
            self.distance = 0
            self.duration = 0
            self.averagePace = ""
            self.averageHeartRate = 0
            self.averageCadence = 0
            self.startTime = Date.now
            self.endTime = Date.now
        }
    }
}

// MARK: - Tests

@MainActor
struct UserWeatherMigrationTests {

    @Test("V3 데이터를 V4 모델로 읽으면 기존 데이터는 보존되고 유저 선택 날씨 필드는 nil이다")
    func v3ToV4_lightweightMigration_preservesDataAndAddsNilWeatherFields() throws {
        // Given
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("v3_to_v4_test_\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        let expectedId = UUID()
        let expectedDistance = 6.4
        let expectedMemo = "Before V3→V4 Migration"

        // Step 1: V3 스키마(유저 선택 날씨 필드 없음)로 데이터 저장
        let v3Container = try ModelContainer(
            for: LegacySchemaV3.RunningRecordPersistenceModel.self,
            configurations: ModelConfiguration(url: url)
        )

        let v3Record = LegacySchemaV3.RunningRecordPersistenceModel()
        v3Record.id = expectedId
        v3Record.distance = expectedDistance
        v3Record.duration = 2100
        v3Record.memo = expectedMemo
        v3Record.temperature = 16.0
        v3Record.humidity = 50
        v3Record.windSpeed = 1.5

        v3Container.mainContext.insert(v3Record)
        try v3Container.mainContext.save()

        // Step 2: V4(현재) 모델로 같은 파일 열기 — lightweight migration 자동 적용
        let v4Container = try ModelContainer(
            for: RunningRecordPersistenceModel.self,
            configurations: ModelConfiguration(url: url)
        )

        let v4Records = try v4Container.mainContext.fetch(
            FetchDescriptor<RunningRecordPersistenceModel>()
        )

        // Then — 기존 데이터 보존, 새로 추가된 유저 선택 날씨 필드는 nil
        #expect(v4Records.count == 1)
        let migrated = v4Records.first!
        #expect(migrated.id == expectedId)
        #expect(migrated.distance == expectedDistance)
        #expect(migrated.memo == expectedMemo)
        #expect(migrated.temperature == 16.0)
        #expect(migrated.skyConditionRaw == nil)
        #expect(migrated.windLevelRaw == nil)
        #expect(migrated.feelsLikeRaw == nil)
        #expect(migrated.humidityLevelRaw == nil)
    }

    @Test("V4 모델로 유저 선택 날씨 필드를 포함한 데이터를 저장하고 조회할 수 있다")
    func v4Schema_canSaveAndReadUserSelectedWeatherFields() throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: RunningRecordPersistenceModel.self,
            configurations: config
        )
        let context = container.mainContext

        let expectedId = UUID()
        let expectedSkyCondition = "sunny"
        let expectedWindLevel = "moderate"
        let expectedFeelsLike = "neutral"
        let expectedHumidityLevel = "humid"

        // When
        let record = RunningRecordPersistenceModel(
            id: expectedId,
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            runningStyleRaw: "midfoot",
            skyConditionRaw: expectedSkyCondition,
            windLevelRaw: expectedWindLevel,
            feelsLikeRaw: expectedFeelsLike,
            humidityLevelRaw: expectedHumidityLevel,
            startTime: .now,
            endTime: .now
        )
        context.insert(record)
        try context.save()

        // Then
        let saved = try context.fetch(
            FetchDescriptor<RunningRecordPersistenceModel>(
                predicate: #Predicate { $0.id == expectedId }
            )
        )

        #expect(saved.count == 1)
        #expect(saved.first?.skyConditionRaw == expectedSkyCondition)
        #expect(saved.first?.windLevelRaw == expectedWindLevel)
        #expect(saved.first?.feelsLikeRaw == expectedFeelsLike)
        #expect(saved.first?.humidityLevelRaw == expectedHumidityLevel)
    }

    @Test("toDomain/fromDomain 변환 시 유저 선택 날씨가 보존된다")
    func userWeather_roundTripsThroughDomainConversion() throws {
        // Given
        let expectedUserWeather = UserWeather(
            skyCondition: .cloudy,
            windLevel: .strong,
            feelsLike: .cold,
            humidityLevel: .dry
        )
        let diary = Diary(
            workout: makeWorkout(),
            runningStyle: .midfoot,
            userWeather: expectedUserWeather
        )

        // When
        let model = RunningRecordPersistenceModel.fromDomain(diary)
        let restored = model.toDomain()

        // Then
        #expect(restored.userWeather == expectedUserWeather)
    }
}

// MARK: - Helpers

private extension UserWeatherMigrationTests {
    func makeWorkout() -> HealthKitWorkout {
        HealthKitWorkout(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            activeEnergyBurned: 0,
            runningVerticalOscillation: 0,
            runningGroundContactTime: 0,
            walkingStepLength: 0,
            restingHeartRate: 0,
            runningPower: 0,
            runningStrideLength: 0,
            heartRateRecoveryOneMinute: 0,
            routeData: nil,
            startDate: .now,
            endDate: .now
        )
    }
}
