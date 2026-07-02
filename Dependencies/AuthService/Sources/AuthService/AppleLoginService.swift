//
//  AppleLoginService.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

import Models
@preconcurrency import SimpleNetwork

/// Apple 로그인 구현체.
///
/// `ASAuthorizationController`로 Apple 자체 로그인을 수행한 뒤,
/// identity token을 서버 Apple 로그인 API로 전달하여 `AuthSession`을 수신한다.
/// 상태 없는 value type. 내부에 캐시 등 mutable state를 추가하려면 참조 타입으로 되돌리는 것을 검토할 것.
public struct AppleLoginService: AppleLoginProviding {
    private let baseURL: String
    private let service: NetworkService

    public init(
        baseURL: String,
        service: NetworkService = URLSessionService()
    ) {
        self.baseURL = baseURL
        self.service = service
    }

    public func login() async throws -> AuthSession {
        let credential = try await requestAppleCredential()
        let request = AppleLoginRequest(idToken: credential.idToken, name: credential.name)
        let api = AppleLoginAPI(baseURL: baseURL, request: request)

        do {
            let response = try await service.request(api)
            return response.toDomain()
        } catch let error as AuthError {
            AuthLogger.error("Apple 로그인 서버 통신 실패(AuthError)", error: error)
            throw error
        } catch {
            // 원본 네트워크 에러는 여기서 serverError로 단순화되므로, 던지기 직전에 원인을 남긴다.
            AuthLogger.error("Apple 로그인 서버 통신 실패", error: error)
            throw AuthError.serverError
        }
    }

    @MainActor
    private func requestAppleCredential() async throws -> AppleCredential {
        try await AppleAuthorizationController().authorize()
    }
}
