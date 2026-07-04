//
//  FeelsLikeLevel.swift
//  Models
//
//  Created by 김혜지 on 6/9/26.
//

/// 유저가 일기 작성 시 선택하는 체감 온도
public enum FeelsLikeLevel: String, CaseIterable, Sendable, Equatable, Codable {
    case cold
    case neutral
    case hot
}
