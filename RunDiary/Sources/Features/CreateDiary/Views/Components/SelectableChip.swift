//
//  SelectableChip.swift
//  RunDiary
//

import SwiftUI

struct SelectableChip: View {
    private let title: String
    private let isSelected: Bool
    private let onTap: () -> Void

    init(title: String, isSelected: Bool, onTap: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue300 : Color.white)
                .foregroundStyle(isSelected ? Color.white : Color.blue700)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue300, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
