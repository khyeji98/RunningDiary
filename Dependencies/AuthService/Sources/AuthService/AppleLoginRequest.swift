//
//  AppleLoginRequest.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

/// 서버 Apple 로그인 API(`POST /api/v1/auth/apple`)의 request body.
///
/// SimpleNetwork 인코더가 `convertToSnakeCase`를 사용하므로
/// `idToken`은 `id_token`으로 자동 변환된다.
/// `name`은 Apple이 최초 로그인 1회에만 제공하므로 값이 있을 때만 전송한다.
struct AppleLoginRequest: Encodable, Sendable {
    let idToken: String
    let name: String?

    enum CodingKeys: String, CodingKey {
        case idToken
        case name
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(idToken, forKey: .idToken)
        try container.encodeIfPresent(name, forKey: .name)
    }
}
