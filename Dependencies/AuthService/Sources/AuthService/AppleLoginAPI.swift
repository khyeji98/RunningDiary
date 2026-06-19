//
//  AppleLoginAPI.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

import Models
import SimpleNetwork

/// 서버 Apple 로그인 엔드포인트 정의.
struct AppleLoginAPI: RequestAPI {
    typealias Query = EmptyQuery
    typealias Response = AppleLoginResponse

    let baseURL: String
    let request: AppleLoginRequest

    var httpMethod: HTTPMethod { .post }
    var path: String { "/api/v1/auth/apple" }
    var headers: HTTPHeaders? { [.contentType(.json)] }
    var body: (any Encodable & Sendable)? { request }
}

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
        let name: String
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
