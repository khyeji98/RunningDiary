//
//  PainArea+Anchor.swift
//  RunDiary
//

import Models
import SwiftUI

extension PainArea {
    // img_body.png (1504×2800) 기준 해부학적 위치 (비율)
    var anchor: UnitPoint {
        switch self {
        case .neck:     return UnitPoint(x: 0.50, y: 0.13)
        case .shoulder: return UnitPoint(x: 0.27, y: 0.19)
        case .chest:    return UnitPoint(x: 0.50, y: 0.27)
        case .side:     return UnitPoint(x: 0.75, y: 0.31)
        case .waist:    return UnitPoint(x: 0.50, y: 0.38)
        case .hip:      return UnitPoint(x: 0.39, y: 0.48)
        case .knee:     return UnitPoint(x: 0.39, y: 0.67)
        case .shin:     return UnitPoint(x: 0.62, y: 0.76)
        case .calf:     return UnitPoint(x: 0.39, y: 0.76)
        case .achilles: return UnitPoint(x: 0.62, y: 0.89)
        case .ankle:    return UnitPoint(x: 0.39, y: 0.89)
        case .sole:     return UnitPoint(x: 0.50, y: 0.96)
        }
    }
}
