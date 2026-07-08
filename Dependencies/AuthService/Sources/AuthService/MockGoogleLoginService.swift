//
//  MockGoogleLoginService.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

import Models

public final class MockGoogleLoginService: GoogleLoginProviding {
    public init() {}

    public func login() async throws -> AuthSession {
        AuthSession(
            accessToken: "mock-google-access-token",
            tokenType: "bearer",
            user: AuthUser(
                id: "mock-google-user-id",
                email: "google@example.com",
                provider: .google,
                name: "Google User"
            )
        )
    }
}
