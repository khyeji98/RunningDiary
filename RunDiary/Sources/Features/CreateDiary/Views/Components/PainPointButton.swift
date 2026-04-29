//
//  PainPointButton.swift
//  RunDiary
//

import Models
import SwiftUI

struct PainPointButton: View {
    private let area: PainArea
    private let isSelected: Bool
    private let onTap: () -> Void

    init(area: PainArea, isSelected: Bool, onTap: @escaping () -> Void) {
        self.area = area
        self.isSelected = isSelected
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected {
                    PainPointRippleEffect()
                }

                Circle()
                    .fill(isSelected ? Color.coral : Color.gray300)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
