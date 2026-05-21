//
//  PainPointRippleEffect.swift
//  RunDiary
//

import SwiftUI

struct PainRippleEffect: View {
    var body: some View {
        ZStack {
            RippleRing(delay: 0.0)
            RippleRing(delay: 0.3)
            RippleRing(delay: 0.85)
            RippleRing(delay: 1.15)
        }
    }
}

private struct RippleRing: View {
    let delay: Double
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0.85

    var body: some View {
        Circle()
            .stroke(Color.coral, lineWidth: 2)
            .frame(width: 18, height: 18)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 0.75)) {
                        scale = 3.8
                        opacity = 0
                    }
                }
            }
    }
}
