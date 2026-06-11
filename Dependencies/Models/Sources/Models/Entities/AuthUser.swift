//
//  AuthUser.swift
//  Models
//
//  Created by 김혜지 on 6/11/26.
//

public struct AuthUser: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let email: String
    public let provider: AuthProvider
    public let name: String

    public init(
        id: String,
        email: String,
        provider: AuthProvider,
        name: String
    ) {
        self.id = id
        self.email = email
        self.provider = provider
        self.name = name
    }
}
