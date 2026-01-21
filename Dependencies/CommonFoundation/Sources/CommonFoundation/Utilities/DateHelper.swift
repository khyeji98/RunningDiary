//
//  DateHelper.swift
//  CommonFoundation
//
//  Created by 김혜지 on 1/21/26.
//

import Foundation

/// 날짜 관련 유틸리티 함수 모음
public enum DateHelper {
    
    // MARK: - Day Operations
    
    /// 특정 날짜의 시작 (00:00:00)
    public static func startOfDay(
        for date: Date,
        calendar: Calendar = .current
    ) -> Date {
        calendar.startOfDay(for: date)
    }
    
    /// 특정 날짜의 끝 (다음날 00:00:00)
    public static func endOfDay(
        for date: Date,
        calendar: Calendar = .current
    ) -> Date? {
        calendar.endOfDay(for: date)
    }
    
    /// 두 날짜가 같은 날인지 확인
    public static func isSameDay(
        _ date1: Date,
        _ date2: Date,
        calendar: Calendar = .current
    ) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    // MARK: - Week Operations
    
    /// 특정 날짜가 속한 주의 월요일 반환
    public static func startOfWeek(
        for date: Date,
        calendar: Calendar = .current
    ) -> Date {
        var modifiedCalendar = calendar
        modifiedCalendar.firstWeekday = 2  // 월요일 시작

        let components = modifiedCalendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear],
            from: date
        )
        return modifiedCalendar.date(from: components) ?? date
    }
    
    /// 특정 날짜가 속한 주의 월~일 7일 반환
    public static func getWeekDates(
        for date: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        let startOfWeek = startOfWeek(for: date, calendar: calendar)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    /// 특정 날짜에서 N주 이동
    public static func addWeeks(
        _ weeks: Int,
        to date: Date,
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(byAdding: .weekOfYear, value: weeks, to: date) ?? date
    }
    
    // MARK: - Date Arithmetic
    
    /// 날짜에 일 단위 추가
    public static func addDays(
        _ days: Int,
        to date: Date,
        calendar: Calendar = .current
    ) -> Date? {
        calendar.date(byAdding: .day, value: days, to: date)
    }
    
    /// 날짜에 초 단위 추가
    public static func addSeconds(
        _ seconds: Int,
        to date: Date,
        calendar: Calendar = .current
    ) -> Date? {
        calendar.date(byAdding: .second, value: seconds, to: date)
    }
    
    // MARK: - Formatting
    
    /// 연도와 월을 포맷팅된 문자열로 반환
    @MainActor
    public static func formattedYearMonth(
        year: Int,
        month: Int,
        calendar: Calendar = .current
    ) -> String {
        guard let date = calendar.date(from: DateComponents(year: year, month: month)) else {
            return "\(year)-\(month)"
        }
        return date.formattedString(formatter: .yearMonth)
    }
}
