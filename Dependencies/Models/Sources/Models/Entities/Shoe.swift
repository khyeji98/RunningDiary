//
//  Shoe.swift
//  Models
//
//  Created by 김혜지 on 4/22/26.
//

public struct Shoe: Identifiable, Equatable, Hashable, Sendable, Decodable {
    public let id: String
    public let brandName: String
    public let name: String
    public let nameKo: String
    public let category: [String: String]
    public let subcategory: [String: String]
    public let tags: [String]
    public let imageUrl: String?
    public let reviewSummary: String?
    public let pros: [String]
    public let cons: [String]
    public let description: String?

    public init(
        id: String,
        brandName: String,
        name: String,
        nameKo: String,
        category: [String: String],
        subcategory: [String: String],
        tags: [String],
        imageUrl: String?,
        reviewSummary: String?,
        pros: [String],
        cons: [String],
        description: String?
    ) {
        self.id = id
        self.brandName = brandName
        self.name = name
        self.nameKo = nameKo
        self.category = category
        self.subcategory = subcategory
        self.tags = tags
        self.imageUrl = imageUrl
        self.reviewSummary = reviewSummary
        self.pros = pros
        self.cons = cons
        self.description = description
    }
}
