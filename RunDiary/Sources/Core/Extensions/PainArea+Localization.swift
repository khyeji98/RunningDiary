//
//  PainArea+Localization.swift
//  RunDiary
//
//  Created by Claude on 11/26/25.
//

import Foundation
import Models

extension PainArea {
    var localizedName: String {
        switch self {
        case .knee:
            return String(localized: "pain_area.knee")
        case .sole:
            return String(localized: "pain_area.sole")
        case .shin:
            return String(localized: "pain_area.shin")
        case .achilles:
            return String(localized: "pain_area.achilles")
        case .hip:
            return String(localized: "pain_area.hip")
        case .shoulder:
            return String(localized: "pain_area.shoulder")
        case .neck:
            return String(localized: "pain_area.neck")
        case .waist:
            return String(localized: "pain_area.waist")
        case .chest:
            return String(localized: "pain_area.chest")
        }
    }
}
