//
//  PainArea+Anchor.swift
//  RunDiary
//

import Models
import SwiftUI

extension PainArea {
    var anchor: UnitPoint {
        switch self {
        case .neck: return UnitPoint(x: 0.5, y: 0.08)
        case .shoulder: return UnitPoint(x: 0.32, y: 0.16)
        case .chest: return UnitPoint(x: 0.5, y: 0.22)
        case .side: return UnitPoint(x: 0.65, y: 0.30)
        case .waist: return UnitPoint(x: 0.5, y: 0.36)
        case .hip: return UnitPoint(x: 0.42, y: 0.46)
        case .knee: return UnitPoint(x: 0.45, y: 0.66)
        case .shin: return UnitPoint(x: 0.55, y: 0.74)
        case .calf: return UnitPoint(x: 0.4, y: 0.78)
        case .achilles: return UnitPoint(x: 0.55, y: 0.88)
        case .ankle: return UnitPoint(x: 0.45, y: 0.92)
        case .sole: return UnitPoint(x: 0.5, y: 0.98)
        }
    }
}
