//
//  TokenRefreshing.swift
//  AuthService
//
//  Created by 김혜지 on 6/17/26.
//

import SecureStorage
@preconcurrency import SimpleNetwork

/// accessToken 갱신을 담당하는 추상화.
public protocol TokenRefreshing: Sendable {
    /// refreshToken으로 accessToken을 갱신하고, 새 accessToken을 반환한다.
    /// 갱신된 토큰은 구현체가 저장소에 반영한다.
    func refresh() async throws -> String
}

/// refreshToken 기반 accessToken 갱신 구현체.
///
/// `actor`로 구현해 동시에 여러 401이 발생해도 갱신은 **한 번만** 수행하고
/// 진행 중인 갱신 결과를 공유한다(single-flight).
public actor TokenRefresher: TokenRefreshing {
    private let baseURL: String
    private let service: NetworkService
    private let storage: SecureStoring

    /// 진행 중인 갱신 Task. 동시 호출은 이 Task의 결과를 공유한다.
    private var inFlight: Task<String, Error>?

    public init(
        baseURL: String,
        service: NetworkService = URLSessionService(),
        storage: SecureStoring = KeychainStorage()
    ) {
        self.baseURL = baseURL
        self.service = service
        self.storage = storage
    }

    public func refresh() async throws -> String {
        // 이미 갱신이 진행 중이면 그 결과를 기다린다.
        if let inFlight {
            return try await inFlight.value
        }

        let task = Task<String, Error> { [baseURL, service, storage] in
            guard let refreshToken = storage.read(.refreshToken) else {
                throw AuthError.tokenExpired
            }

            // TODO: refresh API 연동.
            //   let api = RefreshTokenAPI(baseURL: baseURL, refreshToken: refreshToken)
            //   let response = try await service.request(api)
            //   try storage.save(response.accessToken, for: .accessToken)
            //   // refreshToken은 갱신마다 회전(rotation)되어 응답에 항상 포함되므로 무조건 저장한다.
            //   // 조건부로 저장하면 회전 전 refreshToken이 키체인에 남아 다음 갱신에 잘못 사용될 수 있다.
            //   try storage.save(response.refreshToken, for: .refreshToken)
            //   return response.accessToken
            _ = (baseURL, service, refreshToken)
            throw AuthError.notImplemented
        }

        inFlight = task

        defer { inFlight = nil }

        return try await task.value
    }
}
