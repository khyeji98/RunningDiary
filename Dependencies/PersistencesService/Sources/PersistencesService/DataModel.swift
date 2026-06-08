//
//  DataModel.swift
//  RunDiary
//
//  Created by 김혜지 on 10/23/25.
//

import Models
import SwiftData

public final class DataModel {
    @MainActor
    public static let shared = DataModel()

    // ModelContainer : 실제 데이터 저장소 역할
    public let container: ModelContainer

    @MainActor
    private init() {
        do {
            self.container = try ModelContainer(
                for: RunningRecordPersistenceModel.self,
                migrationPlan: RunningRecordMigrationPlan.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
}
