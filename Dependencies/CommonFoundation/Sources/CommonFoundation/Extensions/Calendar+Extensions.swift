//
//  Calendar+Extensions.swift
//  CommonFoundation
//
//  Created by 김혜지 on 1/21/26.
//

import Foundation

extension Calendar {
    /// 특정 날짜의 끝 (다음날 00:00:00)
    public func endOfDay(for date: Date) -> Date? {
        let startOfDay = startOfDay(for: date)
        return self.date(byAdding: .day, value: 1, to: startOfDay)
    }
}
