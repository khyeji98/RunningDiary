//
//  PainArea+Anchor.swift
//  RunDiary
//

import Models
import SwiftUI

extension PainArea {
    // SVG viewBox 512×512 기준 해부학적 위치 (비율)
    // 머리: 원 중심(256, 56) r=56 → y:0~0.219
    // 어깨 라인: y=128 → 0.25
    // 겨드랑이: y=182 → 0.355
    // 다리 갈림: y=320 → 0.625
    var anchor: UnitPoint {
        switch self {
        case .neck:     return UnitPoint(x: 0.50, y: 0.24)
        case .shoulder: return UnitPoint(x: 0.22, y: 0.30)
        case .chest:    return UnitPoint(x: 0.50, y: 0.40)
        case .side:     return UnitPoint(x: 0.78, y: 0.45)
        case .waist:    return UnitPoint(x: 0.50, y: 0.52)
        case .hip:      return UnitPoint(x: 0.38, y: 0.62)
        case .knee:     return UnitPoint(x: 0.37, y: 0.79)
        case .shin:     return UnitPoint(x: 0.62, y: 0.87)
        case .calf:     return UnitPoint(x: 0.37, y: 0.87)
        case .achilles: return UnitPoint(x: 0.62, y: 0.94)
        case .ankle:    return UnitPoint(x: 0.37, y: 0.94)
        case .sole:     return UnitPoint(x: 0.50, y: 0.99)
        }
    }
}
