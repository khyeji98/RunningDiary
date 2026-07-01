//
//  AppleLoginResponse.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

import Models

/// 서버 응답 DTO.
///
/// `AuthSession`은 명시적 snake_case `CodingKeys`를 가지고 있어 SimpleNetwork의
/// `convertFromSnakeCase` 디코더와 충돌하므로, 디코딩 전용 camelCase DTO를 별도로 둔다.
struct AppleLoginResponse: Decodable, Sendable {
    let accessToken: String
    let tokenType: String
    // TODO: 서버가 refresh_token을 반환하면 옵셔널 해제 검토.
    let refreshToken: String?
    let user: User

    struct User: Decodable, Sendable {
        let id: String
        let email: String
        let provider: AuthProvider
        // 서버는 Apple private relay 사용자 등에 대해 name을 null로 반환할 수 있다.
        let name: String?
    }

    func toDomain() -> AuthSession {
        AuthSession(
            accessToken: accessToken,
            tokenType: tokenType,
            user: AuthUser(
                id: user.id,
                email: user.email,
                provider: user.provider,
                name: user.name
            ),
            refreshToken: refreshToken
        )
    }
}
