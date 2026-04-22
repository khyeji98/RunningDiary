//
//  ShoeCache.swift
//  RunDiary
//
//  Created by 김혜지 on 4/22/26.
//

import Models

public actor ShoeCache {
    public static let shared = ShoeCache()

    private var flat: [Shoe] = []
    private var grouped: [String: [Shoe]] = [:]
    private var byID: [String: Shoe] = [:]
    private var loaded = false

    private init() {}

    public func store(_ shoes: [Shoe]) {
        flat = shoes
        grouped = Dictionary(grouping: shoes) { $0.brandName }
        byID = Dictionary(uniqueKeysWithValues: shoes.map { ($0.id, $0) })
        loaded = true
    }

    public func allShoes() -> [Shoe] { flat }
    public func groupedShoes() -> [String: [Shoe]] { grouped }
    public func shoes(for brand: String) -> [Shoe] { grouped[brand] ?? [] }
    public func shoe(id: String) -> Shoe? { byID[id] }
    public var isLoaded: Bool { loaded }

    public func reset() {
        flat = []
        grouped = [:]
        byID = [:]
        loaded = false
    }
}
