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
