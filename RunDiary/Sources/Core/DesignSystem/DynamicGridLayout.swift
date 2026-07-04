//
//  DynamicGridLayout.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

/// 항목들이 가로로 배치되다가 공간이 부족하면 자동으로 다음 줄로 넘어가는 동적 그리드 레이아웃
struct DynamicGridLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(items: Data, spacing: CGFloat = 8, content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)

        let width = proposal.width ?? rows.map { $0.width }.max() ?? 0
        var height: CGFloat = 0

        for row in rows {
            height += row.height
            if row != rows.last {
                height += spacing
            }
        }

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)

        var yOffset = bounds.minY

        for row in rows {
            var xOffset = bounds.minX

            for item in row.items {
                let itemSize = item.sizeThatFits(.unspecified)
                item.place(at: CGPoint(x: xOffset, y: yOffset), proposal: .unspecified)
                xOffset += itemSize.width + spacing
            }

            yOffset += row.height + spacing
        }
    }

    struct Row: Equatable {
        var items: [LayoutSubview]
        var width: CGFloat
        var height: CGFloat

        static func == (lhs: Row, rhs: Row) -> Bool {
            lhs.width == rhs.width && lhs.height == rhs.height && lhs.items.count == rhs.items.count
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        let maxWidth = proposal.width ?? .infinity

        var currentRowItems: [LayoutSubview] = []
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)

            if currentRowWidth + subviewSize.width > maxWidth && !currentRowItems.isEmpty {
                // Move to new row
                rows.append(Row(items: currentRowItems, width: currentRowWidth, height: currentRowHeight))
                currentRowItems = []
                currentRowWidth = 0
                currentRowHeight = 0
            }

            if !currentRowItems.isEmpty {
                currentRowWidth += spacing
            }

            currentRowItems.append(subview)
            currentRowWidth += subviewSize.width
            currentRowHeight = max(currentRowHeight, subviewSize.height)
        }

        if !currentRowItems.isEmpty {
            rows.append(Row(items: currentRowItems, width: currentRowWidth, height: currentRowHeight))
        }

        return rows
    }
}
