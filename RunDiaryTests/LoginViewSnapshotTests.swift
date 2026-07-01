//
//  LoginViewSnapshotTests.swift
//  RunDiaryTests
//
//  Created by 김혜지 on 7/1/26.
//

import ComposableArchitecture
import Models
import SnapshotTesting
import SwiftUI
import Testing

@testable import RunDiary

@MainActor
@Suite("LoginView 스냅샷")
struct LoginViewSnapshotTests {
    // MARK: - idle (초기 상태)

    @Test("idle 상태 Light")
    func idle_light() {
        // Given
        let controller = makeController(state: .init())

        // When / Then
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone15, traits: makeTraits(style: .light)),
            named: "login-screen-idle-light"
        )
    }

    @Test("idle 상태 Dark")
    func idle_dark() {
        // Given
        let controller = makeController(state: .init())

        // When / Then
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone15, traits: makeTraits(style: .dark)),
            named: "login-screen-idle-dark"
        )
    }

    // MARK: - loading (로딩 중)

    @Test("loading 상태 Light")
    func loading_light() {
        // Given
        let controller = makeController(state: .init(isLoading: true))

        // When / Then
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone15, traits: makeTraits(style: .light)),
            named: "login-screen-loading-light"
        )
    }

    @Test("loading 상태 Dark")
    func loading_dark() {
        // Given
        let controller = makeController(state: .init(isLoading: true))

        // When / Then
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone15, traits: makeTraits(style: .dark)),
            named: "login-screen-loading-dark"
        )
    }

    // MARK: - error (에러 메시지 노출)

    @Test("error 상태 Light")
    func error_light() {
        // Given
        let controller = makeController(state: .init(errorMessage: Self.errorMessage))

        // When / Then
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone15, traits: makeTraits(style: .light)),
            named: "login-screen-error-light"
        )
    }

    @Test("error 상태 Dark")
    func error_dark() {
        // Given
        let controller = makeController(state: .init(errorMessage: Self.errorMessage))

        // When / Then
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone15, traits: makeTraits(style: .dark)),
            named: "login-screen-error-dark"
        )
    }

    // MARK: - success (로그인 성공 정보)

    @Test("success 상태 Light")
    func success_light() {
        // Given
        let controller = makeController(state: .init(session: Self.session))

        // When / Then
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone15, traits: makeTraits(style: .light)),
            named: "login-screen-success-light"
        )
    }

    @Test("success 상태 Dark")
    func success_dark() {
        // Given
        let controller = makeController(state: .init(session: Self.session))

        // When / Then
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone15, traits: makeTraits(style: .dark)),
            named: "login-screen-success-dark"
        )
    }

    // MARK: - 접근성 DynamicType

    @Test("error 상태 접근성 초대형 텍스트")
    func error_accessibilityExtraLarge() {
        // Given
        let controller = makeController(state: .init(errorMessage: Self.errorMessage))

        // When / Then
        assertSnapshot(
            of: controller,
            as: .image(
                on: .iPhone15,
                traits: makeTraits(style: .light, sizeCategory: .accessibilityExtraLarge)
            ),
            named: "login-screen-error-a11yXL"
        )
    }
}

// MARK: - Helpers

private extension LoginViewSnapshotTests {
    static let errorMessage = "로그인에 실패했어요. 잠시 후 다시 시도해 주세요."

    static let session = AuthSession(
        accessToken: "snapshot-access-token",
        tokenType: "bearer",
        user: AuthUser(
            id: "snapshot-user-id",
            email: "runner@example.com",
            provider: .apple,
            name: "러너"
        )
    )

    func makeController(state: LoginFeature.State) -> UIViewController {
        let view = LoginView(
            store: Store(initialState: state) {
                LoginFeature()
            }
        )
        .environment(\.locale, Locale(identifier: "ko_KR"))

        return UIHostingController(rootView: view)
    }

    func makeTraits(
        style: UIUserInterfaceStyle,
        sizeCategory: UIContentSizeCategory = .large
    ) -> UITraitCollection {
        UITraitCollection { traits in
            traits.userInterfaceStyle = style
            traits.preferredContentSizeCategory = sizeCategory
        }
    }
}

// MARK: - iPhone 15 고정 디바이스 구성

private extension ViewImageConfig {
    /// 프로젝트 표준 스냅샷 디바이스: iPhone 15 (393×852 pt, portrait).
    static let iPhone15: ViewImageConfig = {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 393, height: 852)
        let traits = UITraitCollection { traits in
            traits.horizontalSizeClass = .compact
            traits.verticalSizeClass = .regular
            traits.userInterfaceIdiom = .phone
            traits.displayScale = 3
        }

        return ViewImageConfig(safeArea: safeArea, size: size, traits: traits)
    }()
}
