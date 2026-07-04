//
//  PainAreaAnchorTests.swift
//  RunDiaryTests
//

import Models
import SwiftUI
import Testing

@testable import RunDiary

@Suite("PainArea+Anchor")
struct PainAreaAnchorTests {

    // MARK: - 단일 포인트 부위 (xOffset == 0)

    @Test("xOffset=0 부위는 anchor 1개, x=0.5")
    func singleAnchorAreas_haveOnlyCenter() {
        let singleAreas: [PainArea] = [.neck, .chest, .waist]
        for area in singleAreas {
            let anchors = area.anchors
            #expect(anchors.count == 1, "\(area) anchors.count should be 1")
            #expect(anchors[0].x == 0.5, "\(area) anchor.x should be 0.5")
        }
    }

    // MARK: - 좌우 대칭 부위 (xOffset > 0)

    @Test("xOffset>0 부위는 anchor 2개, 좌우 대칭")
    func bilateralAreas_haveTwoSymmetricAnchors() {
        let bilateralAreas: [PainArea] = [.shoulder, .hip, .knee, .shin, .calf, .achilles, .ankle, .sole, .side]
        for area in bilateralAreas {
            let anchors = area.anchors
            #expect(anchors.count == 2, "\(area) anchors.count should be 2")
            let left = anchors[0]
            let right = anchors[1]
            #expect(abs((left.x + right.x) - 1.0) < 0.001, "\(area) anchors should be symmetric around 0.5")
            #expect(left.y == right.y, "\(area) both anchors should share same y")
        }
    }

    // MARK: - 모든 부위 유효 범위

    @Test("모든 PainArea anchor의 x, y 값이 0~1 범위")
    func allAnchors_areInUnitRange() {
        for area in PainArea.allCases {
            for anchor in area.anchors {
                #expect(anchor.x >= 0 && anchor.x <= 1, "\(area).anchor.x=\(anchor.x) out of range")
                #expect(anchor.y >= 0 && anchor.y <= 1, "\(area).anchor.y=\(anchor.y) out of range")
            }
        }
    }
}
