//
//  SkyCondition.swift
//  Models
//
//  Created by 김혜지 on 6/9/26.
//

/// 유저가 일기 작성 시 선택하는 하늘 상태
public enum SkyCondition: String, CaseIterable, Sendable, Equatable, Codable {
    case sunny
    case cloudy
}
