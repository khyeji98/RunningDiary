//
//  CoreNetwork.swift
//  CoreNetwork
//
//  Created by 김혜지 on 3/31/26.
//

import Foundation

public final class CoreNetwork: Sendable {

    public static let shared = CoreNetwork()

    private let session: NetworkService = URLSessionService()

    private init() {}

    public func request<API: RequestAPI>(_ api: API) async throws -> API.Response {
        try await session.request(api)
    }
}
