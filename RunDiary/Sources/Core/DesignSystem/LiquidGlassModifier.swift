//
//  LiquidGlassModifier.swift
//  RunDiary
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

// MARK: - Liquid Glass Modifier
struct LiquidGlassModifier: ViewModifier {
    private let cornerRadius: CGFloat
    private let isInteractive: Bool

    init(cornerRadius: CGFloat,
         isInteractive: Bool
    ) {
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(isInteractive), in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial)
                .cornerRadius(cornerRadius)
        }
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, isInteractive: Bool = false) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, isInteractive: isInteractive))
    }
}

#Preview {
    VStack {
        Spacer()
        Capsule()
            .fill(.white)
            .frame(width: 200, height: 40)
            .liquidGlass()
        Spacer()
    }
    .frame(maxWidth: .infinity)
    .background(Color.gray50)
}
