//
//  PainPointRippleEffect.swift
//  RunDiary
//

import SwiftUI

struct PainPointRippleEffect: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .stroke(Color.coral.opacity(isAnimating ? 0 : 0.6), lineWidth: 3)
            .frame(width: 24, height: 24)
            .scaleEffect(isAnimating ? 2.4 : 1.0)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 0.8)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}
