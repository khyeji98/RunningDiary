//
//  RunningRecordMigrationPlan.swift
//  PersistencesService
//
//  Created by 김혜지 on 5/25/26.
//

import SwiftData

// SwiftData는 lightweight migration(컬럼 추가/삭제)을 stages 없이 자동 처리한다.
// V1~V3 스키마에서 V4로의 마이그레이션은 SwiftData가 스키마 비교 후 자동 적용한다.
public enum RunningRecordMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [RunningRecordSchemaV3.self, RunningRecordSchemaV4.self]
    }

    public static var stages: [MigrationStage] { [] }
}
