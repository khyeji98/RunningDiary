//
//  LegacyShoeMapperTests.swift
//  RunDiaryTests
//
//  Created by 김혜지 on 5/6/26.
//

import Models
import Testing

@testable import RunDiary

@Suite("LegacyShoeMapper")
struct LegacyShoeMapperTests {

    @Test
    func test_decodeName_knownLegacySlug_returnsExactName() {
        #expect(LegacyShoeMapper.decodeName(from: "nike-alphafly-3") == "Nike Alphafly 3")
        #expect(LegacyShoeMapper.decodeName(from: "adidas-adizero-evo-sl") == "Adidas Adizero Evo SL")
        #expect(LegacyShoeMapper.decodeName(from: "puma-fast-r-nitro-elite-3") == "Puma Fast-R Nitro Elite 3")
        #expect(
            LegacyShoeMapper.decodeName(from: "new-balance-fuelcell-supercomp-trainer-v2")
                == "New Balance FuelCell SuperComp Trainer v2"
        )
    }

    @Test
    func test_decodeName_unknownSlug_returnsTitleCased() {
        #expect(LegacyShoeMapper.decodeName(from: "some-new-shoe") == "Some New Shoe")
    }

    @Test
    func test_decodeName_emptyString_returnsNil() {
        #expect(LegacyShoeMapper.decodeName(from: "") == nil)
    }
}

@Suite("ShoeCache.displayName")
struct ShoeCacheDisplayNameTests {

    @Test
    func test_displayName_legacySlug_returnsDecodedName() async {
        let cache = ShoeCache.shared
        await cache.reset()

        let result = await cache.displayName(for: "nike-alphafly-3")

        #expect(result == "Nike Alphafly 3")
    }

    @Test
    func test_displayName_emptyId_returnsNil() async {
        let cache = ShoeCache.shared
        await cache.reset()

        let result = await cache.displayName(for: "")

        #expect(result == nil)
    }

    @Test
    func test_displayName_cachedNewID_returnsCachedName() async {
        let cache = ShoeCache.shared
        await cache.reset()
        let shoe = Shoe(
            id: "srv-001",
            brandName: "Nike",
            name: "Pegasus 41",
            nameKo: "페가수스 41",
            category: [:],
            subcategory: [:],
            tags: [],
            imageUrl: nil,
            reviewSummary: nil,
            pros: [],
            cons: [],
            description: nil
        )
        await cache.store([shoe])

        let result = await cache.displayName(for: "srv-001")

        #expect(result == "페가수스 41")
        await cache.reset()
    }
}
