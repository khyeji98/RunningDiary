//
//  WindLevel.swift
//  Models
//
//  Created by 김혜지 on 6/9/26.
//

/// 유저가 일기 작성 시 선택하는 바람 세기
public enum WindLevel: String, CaseIterable, Sendable, Equatable, Codable {
    case weak
    case moderate
    case strong
}
