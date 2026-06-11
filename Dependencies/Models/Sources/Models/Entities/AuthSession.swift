//
//  AuthSession.swift
//  Models
//
//  Created by 김혜지 on 6/11/26.
//

/// 소셜 로그인 후 서버 API 통신으로 전달받는 인증 세션 정보
public struct AuthSession: Equatable, Sendable, Codable {
    public let accessToken: String
    public let tokenType: String
    public let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }

    public init(
        accessToken: String,
        tokenType: String,
        user: AuthUser
    ) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.user = user
    }
}
