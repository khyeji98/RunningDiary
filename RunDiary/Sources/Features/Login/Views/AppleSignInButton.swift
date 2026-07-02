//
//  AppleSignInButton.swift
//  RunDiary
//
//  Created by 김혜지 on 6/11/26.
//

import AuthenticationServices
import SwiftUI

/// HIG를 준수하는 Apple 로그인 버튼.
/// 실제 인증은 탭 시 전달되는 `onTap` 클로저(→ TCA 액션)에서 수행한다.
struct AppleSignInButton: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme

    private let onTap: () -> Void

    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let style: ASAuthorizationAppleIDButton.Style = colorScheme == .dark ? .white : .black
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: style)
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.didTap),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        context.coordinator.onTap = onTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    final class Coordinator {
        var onTap: () -> Void

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        @objc func didTap() {
            onTap()
        }
    }
}
