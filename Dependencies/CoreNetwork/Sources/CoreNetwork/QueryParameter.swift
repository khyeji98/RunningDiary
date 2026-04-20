//
//  QueryParameter.swift
//  CoreNetwork
//
//  Created by 김혜지 on 3/31/26.
//

import Foundation

/// 쿼리 파라미터를 정의하는 프로토콜입니다.
/// 구조체의 프로퍼티만 정의하면 자동으로 URLQueryItem으로 변환합니다.
public protocol QueryParameter: Encodable {}

public extension QueryParameter {
    /// 프로퍼티를 URLQueryItem 배열로 변환합니다.
    /// 플랫한 key-value 구조만 지원합니다. 중첩 객체나 배열은 무시됩니다.
    var queryItems: [URLQueryItem] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        guard
            let data = try? encoder.encode(self),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [] }

        return dict.compactMap { key, value in
            if value is NSNull { return nil }
            if value is [Any] || value is [String: Any] { return nil }

            let nsValue = value as AnyObject
            if nsValue === kCFBooleanTrue {
                return URLQueryItem(name: key, value: "true")
            } else if nsValue === kCFBooleanFalse {
                return URLQueryItem(name: key, value: "false")
            }

            return URLQueryItem(name: key, value: String(describing: value))
        }
        .sorted { $0.name < $1.name }
    }
}

/// 쿼리 파라미터가 없는 요청에 사용합니다.
public struct EmptyQuery: QueryParameter {
    public init() {}
}
