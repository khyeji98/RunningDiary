//
//  ShoeClient.swift
//  RunDiary
//
//  Created by 김혜지 on 4/22/26.
//

import CoreNetwork
import Dependencies
import DependenciesMacros
import Models

@DependencyClient
struct ShoeClient {
    var fetchAllShoes: @Sendable () async throws -> [Shoe]
}

extension ShoeClient: DependencyKey {
    static let liveValue = ShoeClient {
        try await CoreNetwork.shared.request(ShoeListRequestAPI())
    }

    static let testValue = ShoeClient(
        fetchAllShoes: unimplemented("\(Self.self).fetchAllShoes", placeholder: [])
    )

    static let previewValue = ShoeClient {
        []
    }
}

extension DependencyValues {
    var shoeClient: ShoeClient {
        get { self[ShoeClient.self] }
        set { self[ShoeClient.self] = newValue }
    }
}
