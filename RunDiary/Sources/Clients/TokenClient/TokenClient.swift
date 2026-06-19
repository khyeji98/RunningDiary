//
//  TokenClient.swift
//  RunDiary
//
//  Created by 김혜지 on 6/17/26.
//

import ComposableArchitecture
import Foundation
import Models
import SecureStorage

/// 인증 토큰을 키체인에 영속 저장/조회하는 클라이언트.
///
/// 소셜 로그인으로 받은 `AuthSession`을 저장하고, 앱 진입 시 세션 존재 여부를
/// 판단하는 데 사용한다.
@DependencyClient
struct TokenClient {
    /// accessToken(과 존재할 경우 refreshToken)을 키체인에 저장한다.
    var saveSession: @Sendable (AuthSession) throws -> Void
    /// 저장된 accessToken을 반환한다. 없으면 `nil`.
    var accessToken: @Sendable () -> String? = { nil }
    /// 저장된 refreshToken을 반환한다. 없으면 `nil`.
    var refreshToken: @Sendable () -> String? = { nil }
    /// accessToken이 존재하는지 여부. 앱 진입 라우팅 판단에 사용한다.
    var hasValidSession: @Sendable () -> Bool = { false }
    /// 저장된 모든 토큰을 삭제한다. (로그아웃 등)
    var clear: @Sendable () throws -> Void
}

extension TokenClient: DependencyKey {
    static let liveValue: TokenClient = .live()

    static func live(storage: SecureStoring = KeychainStorage()) -> TokenClient {
        TokenClient(
            saveSession: { session in
                try storage.save(session.accessToken, for: .accessToken)

                if let refreshToken = session.refreshToken {
                    try storage.save(refreshToken, for: .refreshToken)
                }
            },
            accessToken: { storage.read(.accessToken) },
            refreshToken: { storage.read(.refreshToken) },
            hasValidSession: { storage.read(.accessToken) != nil },
            clear: {
                try storage.delete(.accessToken)
                try storage.delete(.refreshToken)
            }
        )
    }

    static let testValue = TokenClient(
        saveSession: unimplemented("\(Self.self).saveSession"),
        accessToken: unimplemented("\(Self.self).accessToken", placeholder: nil),
        refreshToken: unimplemented("\(Self.self).refreshToken", placeholder: nil),
        hasValidSession: unimplemented("\(Self.self).hasValidSession", placeholder: false),
        clear: unimplemented("\(Self.self).clear")
    )

    static let previewValue: TokenClient = .live(storage: InMemorySecureStorage())
}

extension DependencyValues {
    var tokenClient: TokenClient {
        get { self[TokenClient.self] }
        set { self[TokenClient.self] = newValue }
    }
}

/// 프리뷰/테스트에서 키체인 대신 사용할 인메모리 저장소.
final class InMemorySecureStorage: SecureStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var store: [KeychainKey: String] = [:]

    init() {}

    func save(_ value: String, for key: KeychainKey) throws {
        lock.withLock { store[key] = value }
    }

    func read(_ key: KeychainKey) -> String? {
        lock.withLock { store[key] }
    }

    func delete(_ key: KeychainKey) throws {
        lock.withLock { _ = store.removeValue(forKey: key) }
    }
}
