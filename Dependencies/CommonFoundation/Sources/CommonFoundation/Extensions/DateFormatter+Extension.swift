//
//  DateFormatter+Extension.swift
//  CommonFoundation
//
//  Created by 김혜지 on 12/9/25.
//

import Foundation

extension DateFormatter {
    /// "yyyyMMMM" 형식의 DateFormatter
    @MainActor
    public static let yearMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        return formatter
    }()

    /// "a h:mm" 형식의 DateFormatter (사용자 로케일)
    @MainActor
    public static let hourMinutes: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("a h:mm")
        return formatter
    }()

    /// "E" 형식의 DateFormatter
    @MainActor
    public static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("E")
        return formatter
    }()
}
