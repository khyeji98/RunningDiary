//
//  ShoeCacheTests.swift
//  RunDiaryTests
//

import Models
import Testing

@testable import RunDiary

// ShoeCache.shared는 싱글턴 Actor이므로 모든 하위 Suite를 직렬 실행
@Suite("ShoeCache", .serialized)
struct ShoeCacheAllTests {

    @Suite("store / retrieve")
    struct ShoeCacheTests {

        // MARK: - store / allShoes

        @Test("store 후 allShoes는 nameKo 오름차순 정렬")
        func store_sortsAllShoesByNameKo() async {
            let cache = ShoeCache.shared
            await cache.reset()

            let shoes = [
                makeShoe(id: "c", brand: "Asics",  nameKo: "파워런"),
                makeShoe(id: "a", brand: "Adidas", nameKo: "가제트"),
                makeShoe(id: "b", brand: "Nike",   nameKo: "나이트런"),
            ]
            await cache.store(shoes)

            let result = await cache.allShoes()
            #expect(result.map(\.nameKo) == ["가제트", "나이트런", "파워런"])
            await cache.reset()
        }

        // MARK: - groupedShoes

        @Test("store 후 groupedShoes는 브랜드별 그룹핑")
        func store_groupsShoesByBrand() async {
            let cache = ShoeCache.shared
            await cache.reset()

            let shoes = [
                makeShoe(id: "n1", brand: "Nike",   nameKo: "나이트런"),
                makeShoe(id: "n2", brand: "Nike",   nameKo: "페가수스"),
                makeShoe(id: "a1", brand: "Adidas", nameKo: "아디제로"),
            ]
            await cache.store(shoes)

            let grouped = await cache.groupedShoes()
            #expect(grouped["Nike"]?.count == 2)
            #expect(grouped["Adidas"]?.count == 1)
            #expect(grouped["Asics"] == nil)
            await cache.reset()
        }

        // MARK: - shoes(for:)

        @Test("shoes(for:)는 해당 브랜드 신발만 반환")
        func shoesForBrand_returnsOnlyMatchingBrand() async {
            let cache = ShoeCache.shared
            await cache.reset()

            let shoes = [
                makeShoe(id: "n1", brand: "Nike",   nameKo: "나이트런"),
                makeShoe(id: "a1", brand: "Adidas", nameKo: "아디제로"),
            ]
            await cache.store(shoes)

            let nikeShoes = await cache.shoes(for: "Nike")
            #expect(nikeShoes.count == 1)
            #expect(nikeShoes.first?.id == "n1")

            let unknownBrand = await cache.shoes(for: "Unknown")
            #expect(unknownBrand.isEmpty)
            await cache.reset()
        }

        // MARK: - shoe(id:)

        @Test("shoe(id:)는 ID로 단건 조회")
        func shoeById_returnsMatchingShoe() async {
            let cache = ShoeCache.shared
            await cache.reset()

            let target = makeShoe(id: "target-id", brand: "Nike", nameKo: "나이트런")
            await cache.store([target, makeShoe(id: "other-id", brand: "Adidas", nameKo: "아디제로")])

            let found = await cache.shoe(id: "target-id")
            #expect(found?.id == "target-id")

            let notFound = await cache.shoe(id: "non-existent")
            #expect(notFound == nil)
            await cache.reset()
        }

        // MARK: - isLoaded

        @Test("reset 후 isLoaded == false, store 후 true")
        func isLoaded_stateTransitions() async {
            let cache = ShoeCache.shared
            await cache.reset()

            #expect(await cache.isLoaded == false)
            await cache.store([makeShoe(id: "x", brand: "Nike", nameKo: "테스트슈")])
            #expect(await cache.isLoaded == true)

            await cache.reset()
            #expect(await cache.isLoaded == false)
        }

        // MARK: - reset

        @Test("reset 후 allShoes 비어있음")
        func reset_clearsAllShoes() async {
            let cache = ShoeCache.shared
            await cache.store([makeShoe(id: "s1", brand: "Nike", nameKo: "테스트슈")])
            await cache.reset()

            let result = await cache.allShoes()
            #expect(result.isEmpty)
        }
    }

    // MARK: - displayName Tests
    // (ShoeCache 싱글턴 공유로 인해 LegacyShoeMapperTests에서 이동)

    @Suite("displayName")
    struct ShoeCacheDisplayNameTests {

        @Test
        func test_displayName_legacySlug_returnsDecodedName() async {
            let cache = ShoeCache.shared
            await cache.reset()

            let result = await cache.displayName(for: "nike-alphafly-3")

            #expect(result == "Nike Alphafly 3")
            await cache.reset()
        }

        @Test
        func test_displayName_emptyId_returnsNil() async {
            let cache = ShoeCache.shared
            await cache.reset()

            let result = await cache.displayName(for: "")

            #expect(result == nil)
            await cache.reset()
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
}

// MARK: - Helper

private func makeShoe(id: String, brand: String, nameKo: String) -> Shoe {
    Shoe(
        id: id,
        brandName: brand,
        name: nameKo,
        nameKo: nameKo,
        category: [:],
        subcategory: [:],
        tags: [],
        imageUrl: nil,
        reviewSummary: nil,
        pros: [],
        cons: [],
        description: nil
    )
}
