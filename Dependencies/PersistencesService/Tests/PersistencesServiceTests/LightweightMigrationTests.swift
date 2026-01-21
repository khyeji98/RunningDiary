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

// MARK: - V1 Schema (테스트용 - hadMeal, hadAlcohol, hasMap 포함)

/// 이전 버전 앱의 스키마를 시뮬레이션합니다.
/// hadMeal, hadAlcohol, hasMap 프로퍼티가 포함되어 있습니다.
enum LegacySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }
    
    static var models: [any PersistentModel.Type] {
        [RunningRecordPersistenceModel.self]
    }
    
    @Model
    final class RunningRecordPersistenceModel {
        @Attribute(.unique)
        var id: UUID
        var date: Date
        var distance: Double
        var duration: TimeInterval
        var averagePace: String
        var averageHeartRate: Int
        var averageCadence: Int
        var painAreasRawData: String?
        var runningStyleRaw: String?
        var sleepHours: Int?
        var hadMeal: Bool          // V2에서 삭제됨
        var hadAlcohol: Bool       // V2에서 삭제됨
        var memo: String?
        var shoes: String?
        var temperature: Double?
        var humidity: Int?
        var windSpeed: Double?
        var difficultyLevelRaw: Int?
        var routeData: Data?
        var hasMap: Bool           // V2에서 삭제됨
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
            self.hadMeal = false
            self.hadAlcohol = false
            self.hasMap = false
            self.startTime = Date.now
            self.endTime = Date.now
        }
    }
}

// MARK: - Tests

@MainActor
struct LightweightMigrationTests {
    
    @Test("V1 스키마로 hadMeal, hadAlcohol, hasMap 필드를 포함한 데이터를 저장할 수 있다")
    func v1Schema_canSaveDataWithLegacyFields() throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let v1Container = try ModelContainer(
            for: LegacySchemaV1.RunningRecordPersistenceModel.self,
            configurations: config
        )
        let v1Context = v1Container.mainContext

        let expectedId = UUID()
        let expectedDistance = 5.0
        let expectedMemo = "Legacy Schema Test"

        // When
        let v1Record = LegacySchemaV1.RunningRecordPersistenceModel()
        v1Record.id = expectedId
        v1Record.distance = expectedDistance
        v1Record.duration = 1800
        v1Record.hadMeal = true
        v1Record.hadAlcohol = true
        v1Record.hasMap = true
        v1Record.memo = expectedMemo
        
        v1Context.insert(v1Record)
        try v1Context.save()

        // Then
        let descriptor = FetchDescriptor<LegacySchemaV1.RunningRecordPersistenceModel>()
        let records = try v1Context.fetch(descriptor)

        #expect(records.count == 1)
        #expect(records.first?.id == expectedId)
        #expect(records.first?.distance == expectedDistance)
        #expect(records.first?.hadMeal == true)
        #expect(records.first?.hadAlcohol == true)
        #expect(records.first?.hasMap == true)
    }

    @Test("V1 데이터를 V2 모델로 읽으면 SwiftData가 자동으로 마이그레이션한다")
    func v1ToV2_lightweightMigration_preservesExistingData() throws {
        // Given - 임시 파일 URL 생성
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("migration_test_\(UUID().uuidString).store")
        
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let expectedId = UUID()
        let expectedDistance = 10.0
        let expectedDuration: TimeInterval = 3600
        let expectedMemo = "Before Migration"

        // Step 1: V1 스키마로 데이터 저장
        let v1Config = ModelConfiguration(url: url)
        let v1Container = try ModelContainer(
            for: LegacySchemaV1.RunningRecordPersistenceModel.self,
            configurations: v1Config
        )
        
        let v1Record = LegacySchemaV1.RunningRecordPersistenceModel()
        v1Record.id = expectedId
        v1Record.distance = expectedDistance
        v1Record.duration = expectedDuration
        v1Record.hadMeal = true
        v1Record.hadAlcohol = false
        v1Record.hasMap = true
        v1Record.memo = expectedMemo
        
        v1Container.mainContext.insert(v1Record)
        try v1Container.mainContext.save()

        // Step 2: V2 스키마(현재 모델)로 같은 파일 열기 - 자동 마이그레이션 발생
        let v2Config = ModelConfiguration(url: url)
        let v2Container = try ModelContainer(
            for: RunningRecordPersistenceModel.self,
            configurations: v2Config
        )
        
        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>()
        let v2Records = try v2Container.mainContext.fetch(descriptor)

        // Then - 기존 데이터가 보존되어야 함
        #expect(v2Records.count == 1)

        let migratedRecord = v2Records.first!
        #expect(migratedRecord.id == expectedId)
        #expect(migratedRecord.distance == expectedDistance)
        #expect(migratedRecord.duration == expectedDuration)
        #expect(migratedRecord.memo == expectedMemo)
        
        // 새로운 프로퍼티들은 nil 또는 기본값
        #expect(migratedRecord.activeEnergyBurned == nil)
        #expect(migratedRecord.runningVerticalOscillation == nil)
        #expect(migratedRecord.runningPower == nil)
    }
    
    @Test("V1에서 V2로 마이그레이션 후 새 프로퍼티에 값을 저장할 수 있다")
    func v1ToV2_canSaveNewPropertiesAfterMigration() throws {
        // Given
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("migration_update_test_\(UUID().uuidString).store")
        
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let recordId = UUID()

        // Step 1: V1 데이터 저장
        let v1Config = ModelConfiguration(url: url)
        let v1Container = try ModelContainer(
            for: LegacySchemaV1.RunningRecordPersistenceModel.self,
            configurations: v1Config
        )
        
        let v1Record = LegacySchemaV1.RunningRecordPersistenceModel()
        v1Record.id = recordId
        v1Record.distance = 5.0
        v1Record.duration = 1800
        v1Record.hadMeal = true
        v1Record.hadAlcohol = true
        
        v1Container.mainContext.insert(v1Record)
        try v1Container.mainContext.save()

        // Step 2: V2로 열고 새 프로퍼티 업데이트
        let v2Config = ModelConfiguration(url: url)
        let v2Container = try ModelContainer(
            for: RunningRecordPersistenceModel.self,
            configurations: v2Config
        )
        
        let predicate = #Predicate<RunningRecordPersistenceModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(predicate: predicate)
        let records = try v2Container.mainContext.fetch(descriptor)
        
        let record = records.first!
        record.activeEnergyBurned = 450.0
        record.runningPower = 250.0
        record.runningVerticalOscillation = 8.5
        
        try v2Container.mainContext.save()

        // Step 3: 다시 읽어서 확인
        let verifyContainer = try ModelContainer(
            for: RunningRecordPersistenceModel.self,
            configurations: v2Config
        )
        let verifyRecords = try verifyContainer.mainContext.fetch(descriptor)
        
        // Then
        let verifiedRecord = verifyRecords.first!
        #expect(verifiedRecord.activeEnergyBurned == 450.0)
        #expect(verifiedRecord.runningPower == 250.0)
        #expect(verifiedRecord.runningVerticalOscillation == 8.5)
    }
}
