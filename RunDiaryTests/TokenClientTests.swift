//
//  TokenClientTests.swift
//  RunDiaryTests
//
//  Created by 김혜지 on 6/17/26.
//

import Models
import SecureStorage
import Testing

@testable import RunDiary

struct TokenClientTests {
    // MARK: - Test Cases

    @Test("세션 저장 후 accessToken을 조회하면 저장한 값이 반환된다")
    func saveSession_storesAccessToken() throws {
        // Given
        let expectedAccessToken = "access-123"
        let storage = InMemorySecureStorage()
        let client = TokenClient.live(storage: storage)

        // When
        try client.saveSession(makeSession(accessToken: expectedAccessToken))

        // Then
        #expect(client.accessToken() == expectedAccessToken)
    }

    @Test("refreshToken이 있으면 함께 저장된다")
    func saveSession_storesRefreshToken() throws {
        // Given
        let expectedRefreshToken = "refresh-456"
        let storage = InMemorySecureStorage()
        let client = TokenClient.live(storage: storage)

        // When
        try client.saveSession(makeSession(refreshToken: expectedRefreshToken))

        // Then
        #expect(client.refreshToken() == expectedRefreshToken)
    }

    @Test("accessToken이 저장되어 있으면 hasValidSession은 true다")
    func hasValidSession_withToken_returnsTrue() throws {
        // Given
        let storage = InMemorySecureStorage()
        let client = TokenClient.live(storage: storage)

        // When
        try client.saveSession(makeSession())

        // Then
        #expect(client.hasValidSession() == true)
    }

    @Test("저장된 토큰이 없으면 hasValidSession은 false다")
    func hasValidSession_withoutToken_returnsFalse() {
        // Given
        let client = TokenClient.live(storage: InMemorySecureStorage())

        // When / Then
        #expect(client.hasValidSession() == false)
    }

    @Test("clear 호출 시 저장된 토큰이 모두 삭제된다")
    func clear_removesAllTokens() throws {
        // Given
        let storage = InMemorySecureStorage()
        let client = TokenClient.live(storage: storage)
        try client.saveSession(makeSession(refreshToken: "refresh-456"))

        // When
        try client.clear()

        // Then
        #expect(client.accessToken() == nil)
        #expect(client.refreshToken() == nil)
        #expect(client.hasValidSession() == false)
    }

    // MARK: - Helper

    private func makeSession(
        accessToken: String = "access-123",
        refreshToken: String? = nil
    ) -> AuthSession {
        AuthSession(
            accessToken: accessToken,
            tokenType: "bearer",
            user: AuthUser(
                id: "user-1",
                email: "runner@example.com",
                provider: .apple,
                name: "러너"
            ),
            refreshToken: refreshToken
        )
    }
}
