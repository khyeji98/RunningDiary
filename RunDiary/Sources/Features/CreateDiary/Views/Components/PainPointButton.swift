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
            Text(area.localizedName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Color.gray700)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.coral : Color.white.opacity(0.88))
                    Capsule()
                        .stroke(isSelected ? Color.coral : Color.gray300, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
