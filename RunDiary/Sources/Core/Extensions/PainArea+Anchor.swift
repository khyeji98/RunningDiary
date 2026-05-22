//
//  PainArea+Anchor.swift
//  RunDiary
//

import Models
import SwiftUI

extension PainArea {
    // img_body.png (1504×2800) 기준 세로 위치 비율
    private var anchorY: CGFloat {
        switch self {
        case .neck:     return 0.13
        case .shoulder: return 0.19
        case .chest:    return 0.27
        case .side:     return 0.31
        case .waist:    return 0.38
        case .hip:      return 0.48
        case .knee:     return 0.67
        case .shin:     return 0.76
        case .calf:     return 0.76
        case .achilles: return 0.89
        case .ankle:    return 0.89
        case .sole:     return 0.96
        }
    }

    // 단일 ripple은 center(0.5)에, 양측 ripple은 center ± xOffset에 배치
    private var xOffset: CGFloat {
        switch self {
        case .shoulder:                           return 0.23
        case .side:                               return 0.25
        case .hip, .knee, .calf, .ankle, .sole:   return 0.11
        case .shin, .achilles:                    return 0.12
        case .neck, .chest, .waist:               return 0.00
        }
    }

    // 단일 부위: [center], 양측 부위: [center - offset, center + offset]
    var anchors: [UnitPoint] {
        guard xOffset > 0 else {
            return [UnitPoint(x: 0.5, y: anchorY)]
        }
        return [
            UnitPoint(x: 0.5 - xOffset, y: anchorY),
            UnitPoint(x: 0.5 + xOffset, y: anchorY),
        ]
    }
}
