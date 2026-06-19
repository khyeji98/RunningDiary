//
//  KeychainStorage.swift
//  SecureStorage
//
//  Created by 김혜지 on 6/17/26.
//

import Foundation
import Security

/// `Security` 프레임워크의 키체인(`kSecClassGenericPassword`)을 사용하는 `SecureStoring` 구현체.
public final class KeychainStorage: SecureStoring {
    private let service: String

    /// - Parameter service: 키체인 항목의 service 식별자. 기본값은 앱 번들 식별자.
    public init(service: String = Bundle.main.bundleIdentifier ?? "RunDiary") {
        self.service = service
    }

    public func save(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.invalidData }

        // upsert: 기존 항목을 지우고 새로 추가한다.
        try delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else { throw KeychainError.unhandled(status: status) }
    }

    public func read(_ key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard
            status == errSecSuccess,
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        else { return nil }

        return value
    }

    public func delete(_ key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status: status)
        }
    }
}
