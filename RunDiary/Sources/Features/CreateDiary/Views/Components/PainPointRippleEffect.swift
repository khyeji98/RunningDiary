//
//  PainPointRippleEffect.swift
//  RunDiary
//

import SwiftUI

struct PainBurstEffect: View {
    var body: some View {
        ZStack {
            PainBurstRing(delay: 0)
            PainBurstRing(delay: 0.45)
        }
    }
}

private struct PainBurstRing: View {
    let delay: Double
    @State private var scale: CGFloat = 0.15
    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 1.0, green: 0.27, blue: 0.15).opacity(0.9), location: 0),
                        .init(color: Color(red: 1.0, green: 0.27, blue: 0.15).opacity(0.45), location: 0.45),
                        .init(color: Color.clear, location: 1),
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 25
                )
            )
            .frame(width: 50, height: 50)
            .blur(radius: 8)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 0.85)) {
                        scale = 3.5
                        opacity = 0
                    }
                }
            }
    }
}
