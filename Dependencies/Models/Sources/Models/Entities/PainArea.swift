//
//  PainArea.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import Foundation

/// 러닝 중 발생할 수 있는 통증 부위
public enum PainArea: String, CaseIterable, Sendable, Equatable {
    case knee
    case sole
    case shin
    case achilles
    case hip
    case shoulder
    case neck
    case waist
    case chest
    case calf
    case ankle
    case side
}
