//
//  GoogleLoginService.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

import Models

/// Google 로그인 구현체.
/// 실제 Google Sign In 및 서버 API 통신 로직은 추후 구현 예정.
public final class GoogleLoginService: GoogleLoginProviding {
    public init() {}

    public func login() async throws -> AuthSession {
        // TODO: Google Sign In SDK로 로그인 수행 후
        // idToken을 서버로 전달하여 AuthSession 수신
        throw AuthError.notImplemented
    }
}
