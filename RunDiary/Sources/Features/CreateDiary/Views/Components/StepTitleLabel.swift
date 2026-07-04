//
//  StepTitleLabel.swift
//  RunDiary
//

import SwiftUI

struct StepTitleLabel: View {
    private let key: LocalizableKey<LocalizableParameterCount0>

    init(_ key: LocalizableKey<LocalizableParameterCount0>) {
        self.key = key
    }

    var body: some View {
        key.text
            .font(.title3.weight(.semibold))
            .foregroundStyle(.blue700)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
    }
}
