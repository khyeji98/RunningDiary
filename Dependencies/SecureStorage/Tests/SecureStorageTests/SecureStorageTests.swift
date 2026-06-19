//
//  SecureStorageTests.swift
//  SecureStorageTests
//
//  Created by 김혜지 on 6/17/26.
//

import Testing

@testable import SecureStorage

@Suite("SecureStorage")
struct SecureStorageTests {

    @Test("저장한 값을 동일 키로 다시 읽으면 같은 값이 반환된다")
    func saveRead_returnsSameValue() throws {
        // Given
        let expectedValue = "access-token-123"
        let storage = makeStorage()

        // When
        try storage.save(expectedValue, for: .accessToken)

        // Then
        #expect(storage.read(.accessToken) == expectedValue)
    }

    @Test("같은 키에 다시 저장하면 값이 덮어써진다")
    func saveTwice_overwritesValue() throws {
        // Given
        let expectedValue = "new-token"
        let storage = makeStorage()

        // When
        try storage.save("old-token", for: .accessToken)
        try storage.save(expectedValue, for: .accessToken)

        // Then
        #expect(storage.read(.accessToken) == expectedValue)
    }

    @Test("삭제 후 읽으면 nil이 반환된다")
    func delete_returnsNil() throws {
        // Given
        let storage = makeStorage()
        try storage.save("token", for: .accessToken)

        // When
        try storage.delete(.accessToken)

        // Then
        #expect(storage.read(.accessToken) == nil)
    }

    @Test("저장한 적 없는 키를 읽으면 nil이 반환된다")
    func readMissingKey_returnsNil() {
        // Given
        let storage = makeStorage()

        // When / Then
        #expect(storage.read(.refreshToken) == nil)
    }

    @Test("존재하지 않는 키를 삭제해도 에러를 던지지 않는다")
    func deleteMissingKey_doesNotThrow() throws {
        // Given
        let storage = makeStorage()

        // When / Then
        try storage.delete(.refreshToken)
    }
}

// MARK: - Helpers

private extension SecureStorageTests {
    /// 키체인 환경에 의존하지 않도록 인메모리 구현으로 라운드트립을 검증한다.
    func makeStorage() -> SecureStoring {
        InMemorySecureStorage()
    }
}

/// 테스트 전용 인메모리 `SecureStoring` 구현.
private final class InMemorySecureStorage: SecureStoring, @unchecked Sendable {
    private var store: [KeychainKey: String] = [:]

    func save(_ value: String, for key: KeychainKey) throws {
        store[key] = value
    }

    func read(_ key: KeychainKey) -> String? {
        store[key]
    }

    func delete(_ key: KeychainKey) throws {
        store[key] = nil
    }
}
