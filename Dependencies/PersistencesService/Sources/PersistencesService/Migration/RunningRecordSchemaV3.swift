//
//  RunningRecordSchemaV3.swift
//  PersistencesService
//
//  Created by 김혜지 on 5/25/26.
//
//  V3: 날씨 수동 재분류 필드 제거 (skyConditionRaw, windLevelRaw, feelsLikeRaw, humidityLevelRaw)
//      일기 작성 플로우 단순화로 날씨는 WeatherKit 자동 조회만 사용

import Foundation
import SwiftData

enum RunningRecordSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [RunningRecordPersistenceModel.self]
    }
}
