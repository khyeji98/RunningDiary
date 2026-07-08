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

    @Test("signInWithApple: 주입된 appleService의 로그인 결과를 그대로 반환한다")
    func signInWithApple_returnsSession() async throws {
        // Given
        let expectedSession = makeSession(provider: .apple)
        let client = makeSUT(appleService: StubAppleLoginService(result: .success(expectedSession)))

        // When
        let result = try await client.signInWithApple()

        // Then
        #expect(result == expectedSession)
    }

    @Test("signInWithGoogle: 주입된 googleService의 로그인 결과를 그대로 반환한다")
    func signInWithGoogle_returnsSession() async throws {
        // Given
        let expectedSession = makeSession(provider: .google)
        let client = makeSUT(googleService: StubGoogleLoginService(result: .success(expectedSession)))

        // When
        let result = try await client.signInWithGoogle()

        // Then
        #expect(result == expectedSession)
    }

    @Test("signInWithApple: appleService가 실패하면 동일한 에러를 던진다")
    func signInWithApple_throwsError() async {
        // Given
        let client = makeSUT(appleService: StubAppleLoginService(result: .failure(AuthError.cancelled)))

        // When / Then
        await #expect(throws: AuthError.cancelled) {
            try await client.signInWithApple()
        }
    }
}

// MARK: - Helpers

private extension AuthClientTests {
    /// `AuthClient.live(appleService:googleService:)`로 SUT를 생성한다.
    /// 실제 `liveValue`와 동일한 배선(delegation) 로직을 태우기 위해
    /// 고정 클로저 대신 `AuthClient.live`를 재사용한다.
    func makeSUT(
        appleService: AppleLoginProviding = StubAppleLoginService(result: .success(Self.fallbackSession)),
        googleService: GoogleLoginProviding = StubGoogleLoginService(result: .success(Self.fallbackSession))
    ) -> AuthClient {
        .live(appleService: appleService, googleService: googleService)
    }

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

    static var fallbackSession: AuthSession {
        AuthSession(
            accessToken: "fallback-access-token",
            tokenType: "bearer",
            user: AuthUser(
                id: "fallback-user-id",
                email: "fallback@example.com",
                provider: .apple,
                name: "Fallback User"
            )
        )
    }
}

// MARK: - Stubs

/// `signInWithApple`이 실제로 주입된 서비스에 위임하는지 검증하기 위한 테스트 전용 fake.
private struct StubAppleLoginService: AppleLoginProviding {
    let result: Result<AuthSession, Error>

    func login() async throws -> AuthSession {
        try result.get()
    }
}

/// `signInWithGoogle`이 실제로 주입된 서비스에 위임하는지 검증하기 위한 테스트 전용 fake.
private struct StubGoogleLoginService: GoogleLoginProviding {
    let result: Result<AuthSession, Error>

    func login() async throws -> AuthSession {
        try result.get()
    }
}
