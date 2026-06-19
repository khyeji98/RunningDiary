//
//  AuthenticatedNetworkService.swift
//  AuthService
//
//  Created by 김혜지 on 6/17/26.
//

@preconcurrency import SimpleNetwork

/// 인증이 필요한 요청을 감싸는 `NetworkService` 데코레이터.
///
/// 응답이 401(accessToken 만료)이면 `TokenRefreshing`으로 accessToken을 갱신한 뒤
/// 원래 요청을 **1회 재시도**한다.
///
/// ## Authorization 헤더 주입에 대하여
/// SimpleNetwork는 각 `RequestAPI`의 `headers`로 URLRequest를 구성하므로,
/// 이 데코레이터가 헤더를 직접 끼워넣지 않는다. 인증이 필요한 API는 자신의 `headers`에서
/// 키체인 accessToken을 읽어 `.authorization(bearer:)`를 구성해야 한다.
/// 재시도 시점에는 갱신된 accessToken을 다시 읽어 자동 반영된다.
///
/// TODO: 인증 필요한 비즈니스 API가 추가되면 키체인 토큰을 읽어
///       `Authorization: Bearer`를 구성하는 공통 헤더 빌더를 도입한다.
public final class AuthenticatedNetworkService: NetworkService {
    private let inner: NetworkService
    private let refresher: TokenRefreshing

    public init(
        inner: NetworkService = URLSessionService(),
        refresher: TokenRefreshing
    ) {
        self.inner = inner
        self.refresher = refresher
    }

    public func request<API: RequestAPI>(_ api: API) async throws -> API.Response {
        do {
            return try await inner.request(api)
        } catch let error as NetworkError {
            guard case .httpError(let statusCode) = error, statusCode == 401 else {
                AuthLogger.error("인증 요청 실패 \(API.self)", error: error)
                throw error
            }

            AuthLogger.info("401 수신 → accessToken 갱신 시도 \(API.self)")

            do {
                // accessToken 갱신 후 1회 재시도. 재시도 요청은 갱신된 토큰을 다시 읽는다.
                _ = try await refresher.refresh()
            } catch {
                AuthLogger.error("토큰 갱신 실패 \(API.self)", error: error)
                throw error
            }

            return try await inner.request(api)
        }
    }
}
