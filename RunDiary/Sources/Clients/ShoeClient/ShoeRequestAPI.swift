//
//  ShoeRequestAPI.swift
//  RunDiary
//
//  Created by 김혜지 on 4/22/26.
//

import CoreNetwork
import Models

struct ShoeListRequestAPI: RequestAPI, Sendable {
    typealias Query = EmptyQuery
    typealias Response = [Shoe]

    var httpMethod: HTTPMethod { .get }
    var path: String { Endpoint.shoes.rawValue }
    var baseURL: String { BaseURL.rundiary.value }
}
