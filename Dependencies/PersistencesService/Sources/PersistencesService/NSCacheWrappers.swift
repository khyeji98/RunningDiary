//
//  NSCacheWrappers.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models

/// NSCache의 키로 사용하기 위한 YearMonthDay 래퍼. NSObject 기반의 hash/isEqual 구현을 제공한다.
final class YearMonthDayCacheKey: NSObject {
    let value: YearMonthDay

    init(_ value: YearMonthDay) {
        self.value = value
        super.init()
    }

    override var hash: Int { value.hashValue }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? YearMonthDayCacheKey else { return false }
        return value == other.value
    }
}

/// NSCache의 값으로 사용하기 위한 [Diary] 래퍼.
final class DiaryArrayCacheValue: NSObject {
    let diaries: [Diary]

    init(_ diaries: [Diary]) {
        self.diaries = diaries
        super.init()
    }
}
