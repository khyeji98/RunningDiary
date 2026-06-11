//
//  BaseURL.swift
//  RunDiary
//
//  Created by 김혜지 on 4/22/26.
//

import Foundation

struct BaseURL: Sendable {
    let value: String

    static let rundiary = BaseURL(value: Bundle.main.apiBaseURL)
}

private extension Bundle {
    var apiBaseURL: String {
        guard
            let value = object(forInfoDictionaryKey: "APIBaseURL") as? String,
            !value.isEmpty
        else {
            assertionFailure("APIBaseURL missing in Info.plist")
            return ""
        }
        return value
    }
}
