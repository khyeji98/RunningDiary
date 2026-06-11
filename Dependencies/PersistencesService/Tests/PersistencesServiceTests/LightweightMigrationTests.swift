//
//  LightweightMigrationTests.swift
//  PersistencesService
//
//  Created by 김혜지 on 1/20/26.
//

import Foundation
import SwiftData
import Testing

@testable import PersistencesService

// MARK: - V2 Schema (테스트용 — skyConditionRaw 등 날씨 재분류 필드 포함)
//
// 일기 작성 플로우가 단순화(단계별 → 단일 폼)되면서 사용자가 날씨를 수동 재분류하는
// 스텝이 제거되었다. 이에 따라 V2의 skyConditionRaw 등 4개 필드가 V3에서 삭제되었다.

enum LegacySchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

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
        var skyConditionRaw: String?    // V3에서 제거
        var windLevelRaw: String?       // V3에서 제거
        var feelsLikeRaw: String?       // V3에서 제거
        var humidityLevelRaw: String?   // V3에서 제거
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
struct LightweightMigrationTests {

    // MARK: - V2 Schema Tests

    @Test("V2 스키마로 skyConditionRaw 등 날씨 분류 필드를 포함한 데이터를 저장할 수 있다")
    func v2Schema_canSaveDataWithWeatherClassificationFields() throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let v2Container = try ModelContainer(
            for: LegacySchemaV2.RunningRecordPersistenceModel.self,
            configurations: config
        )
        let context = v2Container.mainContext

        let expectedId = UUID()
        let expectedSkyCondition = "clear"
        let expectedWindLevel = "calm"

        // When
        let v2Record = LegacySchemaV2.RunningRecordPersistenceModel()
        v2Record.id = expectedId
        v2Record.distance = 5.0
        v2Record.duration = 1800
        v2Record.temperature = 22.0
        v2Record.humidity = 55
        v2Record.windSpeed = 2.5
        v2Record.skyConditionRaw = expectedSkyCondition
        v2Record.windLevelRaw = expectedWindLevel
        v2Record.feelsLikeRaw = "comfortable"
        v2Record.humidityLevelRaw = "moderate"

        context.insert(v2Record)
        try context.save()

        // Then
        let records = try context.fetch(
            FetchDescriptor<LegacySchemaV2.RunningRecordPersistenceModel>()
        )

        #expect(records.count == 1)
        #expect(records.first?.id == expectedId)
        #expect(records.first?.skyConditionRaw == expectedSkyCondition)
        #expect(records.first?.windLevelRaw == expectedWindLevel)
    }

    @Test("V2 데이터를 V3 모델로 읽으면 날씨 분류 필드가 제거되고 핵심 데이터는 보존된다")
    func v2ToV3_lightweightMigration_preservesExistingData() throws {
        // Given
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("v2_to_v3_test_\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        let expectedId = UUID()
        let expectedDistance = 8.5
        let expectedMemo = "Before V2→V3 Migration"
        let expectedActiveEnergy = 550.0

        // Step 1: V2 스키마로 날씨 분류 필드 포함 데이터 저장
        let v2Container = try ModelContainer(
            for: LegacySchemaV2.RunningRecordPersistenceModel.self,
            configurations: ModelConfiguration(url: url)
        )

        let v2Record = LegacySchemaV2.RunningRecordPersistenceModel()
        v2Record.id = expectedId
        v2Record.distance = expectedDistance
        v2Record.duration = 2400
        v2Record.memo = expectedMemo
        v2Record.temperature = 18.0
        v2Record.humidity = 60
        v2Record.windSpeed = 3.0
        v2Record.skyConditionRaw = "partlyCloudy"
        v2Record.windLevelRaw = "light"
        v2Record.feelsLikeRaw = "cool"
        v2Record.humidityLevelRaw = "moderate"
        v2Record.activeEnergyBurned = expectedActiveEnergy
        v2Record.runningPower = 280.0

        v2Container.mainContext.insert(v2Record)
        try v2Container.mainContext.save()

        // Step 2: V3(현재) 모델로 같은 파일 열기 — lightweight migration 자동 적용
        let v3Container = try ModelContainer(
            for: RunningRecordPersistenceModel.self,
            configurations: ModelConfiguration(url: url)
        )

        let v3Records = try v3Container.mainContext.fetch(
            FetchDescriptor<RunningRecordPersistenceModel>()
        )

        // Then — 핵심 데이터 보존, 날씨 원시 데이터(temperature/humidity/windSpeed) 유지
        #expect(v3Records.count == 1)
        let migrated = v3Records.first!
        #expect(migrated.id == expectedId)
        #expect(migrated.distance == expectedDistance)
        #expect(migrated.memo == expectedMemo)
        #expect(migrated.temperature == 18.0)
        #expect(migrated.humidity == 60)
        #expect(migrated.windSpeed == 3.0)
        #expect(migrated.activeEnergyBurned == expectedActiveEnergy)
        #expect(migrated.runningPower == 280.0)
    }

    @Test("V2→V3 마이그레이션 후 V3 모델로 새 데이터를 정상 저장할 수 있다")
    func v2ToV3_canSaveNewRecordsAfterMigration() throws {
        // Given
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("v2_to_v3_save_test_\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        // Step 1: V2 데이터 저장
        let v2Container = try ModelContainer(
            for: LegacySchemaV2.RunningRecordPersistenceModel.self,
            configurations: ModelConfiguration(url: url)
        )

        let v2Record = LegacySchemaV2.RunningRecordPersistenceModel()
        v2Record.distance = 5.0
        v2Record.duration = 1800
        v2Record.skyConditionRaw = "sunny"

        v2Container.mainContext.insert(v2Record)
        try v2Container.mainContext.save()

        // Step 2: V3으로 마이그레이션 후 신규 레코드 저장
        let v3Container = try ModelContainer(
            for: RunningRecordPersistenceModel.self,
            configurations: ModelConfiguration(url: url)
        )

        let newRecordId = UUID()
        let newRecord = RunningRecordPersistenceModel(
            id: newRecordId,
            distance: 10.0,
            duration: 3600,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 168,
            runningStyleRaw: "midfoot",
            startTime: .now,
            endTime: .now
        )
        v3Container.mainContext.insert(newRecord)
        try v3Container.mainContext.save()

        // Then
        let saved = try v3Container.mainContext.fetch(
            FetchDescriptor<RunningRecordPersistenceModel>(
                predicate: #Predicate { $0.id == newRecordId }
            )
        )

        #expect(saved.count == 1)
        #expect(saved.first?.distance == 10.0)
        #expect(saved.first?.averagePace == "6'00\"")
    }
}
