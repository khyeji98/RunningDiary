//
//  AuthClientTests.swift
//  RunDiaryTests
//
//  Created by 김혜지 on 6/11/26.
//

import AuthService
import Foundation
import Models

import Testing

@testable import RunDiary

@Suite("AuthClient")
struct AuthClientTests {

    @Test("signInWithApple: Apple 로그인 세션을 반환한다")
    func signInWithApple_returnsSession() async throws {
        // Given
        let expectedSession = makeSession(provider: .apple)
        let client = AuthClient(
            signInWithApple: { expectedSession },
            signInWithGoogle: { self.makeSession(provider: .google) }
        )

        // When
        let result = try await client.signInWithApple()

        // Then
        #expect(result == expectedSession)
    }

    @Test("signInWithGoogle: Google 로그인 세션을 반환한다")
    func signInWithGoogle_returnsSession() async throws {
        // Given
        let expectedSession = makeSession(provider: .google)
        let client = AuthClient(
            signInWithApple: { self.makeSession(provider: .apple) },
            signInWithGoogle: { expectedSession }
        )

        // When
        let result = try await client.signInWithGoogle()

        // Then
        #expect(result == expectedSession)
    }

    @Test("signInWithApple: 로그인 실패 시 에러를 던진다")
    func signInWithApple_throwsError() async {
        // Given
        let client = AuthClient(
            signInWithApple: { throw AuthError.cancelled },
            signInWithGoogle: { self.makeSession(provider: .google) }
        )

        // When / Then
        await #expect(throws: AuthError.cancelled) {
            try await client.signInWithApple()
        }
    }
}

// MARK: - Helpers

private extension AuthClientTests {
    func makeSession(provider: AuthProvider) -> AuthSession {
        AuthSession(
            accessToken: "test-access-token",
            tokenType: "bearer",
            user: AuthUser(
                id: "test-user-id",
                email: "test@example.com",
                provider: provider,
                name: "Test User"
            )
        )
    }
}
