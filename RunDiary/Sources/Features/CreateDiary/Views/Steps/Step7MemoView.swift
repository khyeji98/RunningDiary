//
//  Step7MemoView.swift
//  RunDiary
//

import ComposableArchitecture
import SwiftUI

struct Step7MemoView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>

    var body: some View {
        VStack(spacing: 0) {
            StepTitleLabel(L10n.recordStepTitleMemo)

            ZStack(alignment: .topLeading) {
                TextEditor(
                    text: Binding(
                        get: { store.memo },
                        set: { store.send(.updateMemo($0)) }
                    )
                )
                .frame(minHeight: 240)
                .padding(10)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray100, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if store.memo.isEmpty {
                    Text("record.placeholder.memo_new")
                        .foregroundStyle(.gray500)
                        .padding(.top, 18)
                        .padding(.leading, 14)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            Spacer(minLength: 0)
        }
    }
}
