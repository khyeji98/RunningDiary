//
//  AuthClient.swift
//  RunDiary
//
//  Created by 김혜지 on 6/11/26.
//

import AuthService
import ComposableArchitecture
import Foundation
import Models

@DependencyClient
struct AuthClient {
    var signInWithApple: @MainActor @Sendable () async throws -> AuthSession
    var signInWithGoogle: @MainActor @Sendable () async throws -> AuthSession
}

extension AuthClient: DependencyKey {
    static let liveValue: AuthClient = {
        let appleService = AppleLoginService(baseURL: AppConfig.baseURL)
        let googleService = GoogleLoginService()

        return AuthClient(
            signInWithApple: {
                try await appleService.login()
            },
            signInWithGoogle: {
                try await googleService.login()
            }
        )
    }()

    static let testValue = AuthClient(
        signInWithApple: unimplemented("\(Self.self).signInWithApple"),
        signInWithGoogle: unimplemented("\(Self.self).signInWithGoogle")
    )

    static let previewValue = AuthClient(
        signInWithApple: {
            AuthSession(
                accessToken: "preview-apple-access-token",
                tokenType: "bearer",
                user: AuthUser(
                    id: "preview-apple-user-id",
                    email: "apple@example.com",
                    provider: .apple,
                    name: "Apple User"
                )
            )
        },
        signInWithGoogle: {
            AuthSession(
                accessToken: "preview-google-access-token",
                tokenType: "bearer",
                user: AuthUser(
                    id: "preview-google-user-id",
                    email: "google@example.com",
                    provider: .google,
                    name: "Google User"
                )
            )
        }
    )
}

extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}
