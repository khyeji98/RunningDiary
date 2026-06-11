//
//  RunningRecordSchemaV4.swift
//  PersistencesService
//
//  Created by 김혜지 on 6/9/26.
//
//  V4: 유저 선택 날씨 필드 재추가 (skyConditionRaw, windLevelRaw, feelsLikeRaw, humidityLevelRaw)
//      WeatherKit 자동 조회 수치(temperature/humidity/windSpeed)와 별개로
//      일기 작성 시 유저가 직접 선택한 날씨를 저장한다.

import Foundation
import SwiftData

enum RunningRecordSchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [RunningRecordPersistenceModel.self]
    }
}
