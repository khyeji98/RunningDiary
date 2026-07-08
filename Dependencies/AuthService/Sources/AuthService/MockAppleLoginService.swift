//
//  MockAppleLoginService.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

import Models

public final class MockAppleLoginService: AppleLoginProviding {
    public init() {}

    public func login() async throws -> AuthSession {
        AuthSession(
            accessToken: "mock-apple-access-token",
            tokenType: "bearer",
            user: AuthUser(
                id: "mock-apple-user-id",
                email: "apple@example.com",
                provider: .apple,
                name: "Apple User"
            )
        )
    }
}
