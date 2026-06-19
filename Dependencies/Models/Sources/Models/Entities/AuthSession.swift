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
    /// accessToken 만료 시 갱신에 사용하는 refresh token.
    ///
    /// 현재 서버가 반환하지 않을 수 있어 옵셔널로 둔다.
    /// TODO: 서버가 refresh_token을 반환하기 시작하면 옵셔널 해제를 검토한다.
    public let refreshToken: String?
    public let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case user
    }

    public init(
        accessToken: String,
        tokenType: String,
        user: AuthUser,
        refreshToken: String? = nil
    ) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.user = user
        self.refreshToken = refreshToken
    }
}
