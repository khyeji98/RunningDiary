//
//  AppleLoginProviding.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

import Models

/// Apple 소셜 로그인 인터페이스
public protocol AppleLoginProviding: Sendable {
    /// Apple 로그인을 수행하고 서버 API 통신으로 인증 세션을 받아온다.
    func login() async throws -> AuthSession
}
