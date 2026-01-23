//
//  MemoSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import SwiftUI

struct MemoSectionView: View {
    @Binding var memo: String

    init(memo: Binding<String>) {
        self._memo = memo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("record.section.memo")
                .font(.headline)
                .padding(.bottom, 4)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $memo)
                    .frame(minHeight: 150)
                    .padding(4)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)

                if memo.isEmpty {
                    Text("record.placeholder.memo_new")
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                        .padding(.leading, 9)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
