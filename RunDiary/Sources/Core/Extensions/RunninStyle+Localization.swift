//
//  RunninStyle+Localization.swift
//  RunDiary
//
//  Created by Claude on 11/26/25.
//

import Foundation
import Models

extension RunninStyle {
    var localizedName: String {
        switch self {
        case .forefoot:
            return L10n.runningStyleForefoot.value
        case .midfoot:
            return L10n.runningStyleMidfoot.value
        case .heelfoot:
            return L10n.runningStyleHeelfoot.value
        }
    }
}
