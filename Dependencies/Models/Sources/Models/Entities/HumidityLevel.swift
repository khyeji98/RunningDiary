//
//  HumidityLevel.swift
//  Models
//
//  Created by 김혜지 on 6/9/26.
//

/// 유저가 일기 작성 시 선택하는 습도 체감
public enum HumidityLevel: String, CaseIterable, Sendable, Equatable, Codable {
    case dry
    case humid
}
