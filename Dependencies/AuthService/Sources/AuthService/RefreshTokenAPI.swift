//
//  RefreshTokenAPI.swift
//  AuthService
//
//  Created by 김혜지 on 6/17/26.
//

import SimpleNetwork

/// 서버 토큰 갱신 엔드포인트 정의.
///
/// TODO: refresh API 스펙(경로/요청/응답 스키마)이 확정되면 실제 값으로 연동한다.
struct RefreshTokenAPI: RequestAPI {
    typealias Query = EmptyQuery
    typealias Response = RefreshTokenResponse

    let baseURL: String
    let refreshToken: String

    var httpMethod: HTTPMethod { .post }
    var path: String { "/api/v1/auth/refresh" }
    var headers: HTTPHeaders? { [.contentType(.json)] }
    var body: (any Encodable & Sendable)? { RefreshTokenRequest(refreshToken: refreshToken) }
}

/// 토큰 갱신 request body.
///
/// `convertToSnakeCase`로 `refreshToken` → `refresh_token` 변환된다.
struct RefreshTokenRequest: Encodable, Sendable {
    let refreshToken: String
}

/// 토큰 갱신 응답 DTO.
///
/// accessToken 갱신 시 refreshToken도 함께 회전(rotation)되어 매번 응답에 포함되므로 옵셔널이 아니다.
struct RefreshTokenResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
}
