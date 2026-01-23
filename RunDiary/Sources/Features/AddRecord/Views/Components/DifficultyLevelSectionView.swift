//
//  DifficultyLevelSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import Models
import SwiftUI

struct DifficultyLevelSectionView: View {
    @Binding var selectedLevel: DifficultyLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 2) {
                Text("record.section.difficulty")
                Text("*")
                    .foregroundColor(.red)
            }
            .font(.headline)
            .padding(.bottom, 4)

            DifficultySlider(selectedLevel: $selectedLevel)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - DifficultySlider

private struct DifficultySlider: View {
    @Binding var selectedLevel: DifficultyLevel?
    @State private var isDragging: Bool = false
    @State private var thumbOffset: CGFloat = 0
    @State private var hasInitialized: Bool = false

    private let levels = DifficultyLevel.allCases
    private let thumbSize: CGFloat = 24
    private let dotSize: CGFloat = 12
    private let trackHeight: CGFloat = 4

    var body: some View {
        VStack(spacing: 12) {
            // 슬라이더 트랙 영역
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let stepWidth = (totalWidth - thumbSize) / CGFloat(levels.count - 1)
                let currentIndex = selectedLevel.map { CGFloat($0.rawValue - 1) } ?? 2

                ZStack(alignment: .leading) {
                    // Track (배경 라인)
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: trackHeight)
                        .padding(.horizontal, thumbSize / 2)

                    // Dots (5개의 점)
                    HStack(spacing: 0) {
                        ForEach(Array(levels.enumerated()), id: \.element) { index, level in
                            Circle()
                                .fill(Color.gray300)
                                .frame(width: dotSize, height: dotSize)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedLevel = level
                                    }
                                }

                            if index < levels.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, thumbSize / 2 - dotSize / 2)

                    // Thumb (드래그 가능한 손잡이)
                    Circle()
                        .fill(Color.blue300)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .offset(x: thumbOffset)
                        .onAppear {
                            if !hasInitialized {
                                thumbOffset = currentIndex * stepWidth
                                hasInitialized = true
                            }
                        }
                        .onChange(of: selectedLevel) { _, _ in
                            if !isDragging {
                                let newIndex = selectedLevel.map { CGFloat($0.rawValue - 1) } ?? 2
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    thumbOffset = newIndex * stepWidth
                                }
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                    }
                                    let newOffset = currentIndex * stepWidth + value.translation.width
                                    thumbOffset = min(max(0, newOffset), totalWidth - thumbSize)
                                }
                                .onEnded { _ in
                                    let snappedIndex = round(thumbOffset / stepWidth)
                                    let clampedIndex = Int(min(max(0, snappedIndex), CGFloat(levels.count - 1)))

                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        thumbOffset = CGFloat(clampedIndex) * stepWidth
                                    }

                                    selectedLevel = levels[clampedIndex]
                                    isDragging = false
                                }
                        )
                }
                .frame(height: thumbSize)
            }
            .frame(height: thumbSize)

            // Labels (양 끝만 표기)
            HStack {
                Text("difficulty_level.short.very_easy")
                    .font(.caption2)
                    .foregroundColor(.gray500)
                Spacer()
                Text("difficulty_level.short.very_hard")
                    .font(.caption2)
                    .foregroundColor(.gray500)
            }
        }
    }
}
