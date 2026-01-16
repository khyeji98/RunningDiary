//
//  DataModel.swift
//  RunDiary
//
//  Created by 김혜지 on 10/23/25.
//

import Models
import SwiftData

public actor DataModel {
    public static let shared = DataModel()

    // ModelContainer : 실제 데이터 저장소 역할
    private static let container: ModelContainer = {
        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: RunningRecordPersistenceModel.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        return modelContainer
    }()

    nonisolated public var modelContainer: ModelContainer {
        Self.container
    }
}
