//
//  HTTPMethod.swift
//  CoreNetwork
//
//  Created by 김혜지 on 3/31/26.
//

import Foundation

/// HTTP 요청 메서드를 정의합니다.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
