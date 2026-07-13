//
//  SeriesPoint.swift
//  Models
//
//  Created by 김혜지 on 7/12/26.
//

// 필드명 `t`/`v`는 series 목표 JSON 스키마({t, v})에 맞춘 의도적 축약이다.
// swiftlint:disable identifier_name
public struct SeriesPoint: Equatable, Sendable, Codable {
    public let t: Int    // 시작 후 경과 초
    public let v: Int

    public init(t: Int, v: Int) {
        self.t = t
        self.v = v
    }
}
// swiftlint:enable identifier_name
