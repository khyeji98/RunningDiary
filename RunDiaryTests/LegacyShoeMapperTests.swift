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

// ShoeCache.displayName 테스트는 ShoeCache 싱글턴 직렬화를 위해 ShoeCacheTests.swift로 이동
