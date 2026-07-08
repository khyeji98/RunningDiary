//
//  KeychainStorage.swift
//  SecureStorage
//
//  Created by 김혜지 on 6/17/26.
//

import Foundation
import Security

/// `Security` 프레임워크의 키체인(`kSecClassGenericPassword`)을 사용하는 `SecureStoring` 구현체.
///
/// 상태 없는 value type. 내부에 캐시 등 mutable state를 추가하려면 참조 타입으로 되돌리는 것을 검토할 것.
public struct KeychainStorage: SecureStoring {
    private let service: String

    /// - Parameter service: 키체인 항목의 service 식별자. 기본값은 앱 번들 식별자.
    public init(service: String = Bundle.main.bundleIdentifier ?? "RunDiary") {
        self.service = service
    }

    public func save(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.invalidData }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]

        // upsert: 먼저 추가를 시도하고, 이미 존재하면(errSecDuplicateItem) 갱신한다.
        // delete 후 add 방식과 달리 단일 Security 프레임워크 호출로 귀결되므로 원자적이다.
        let addQuery = query.merging([
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]) { _, new in new }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

        if addStatus == errSecDuplicateItem {
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else { throw KeychainError.unhandled(status: updateStatus) }
        } else {
            guard addStatus == errSecSuccess else { throw KeychainError.unhandled(status: addStatus) }
        }
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
