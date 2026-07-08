//
//  LoginView.swift
//  RunDiary
//
//  Created by 김혜지 on 6/11/26.
//

import ComposableArchitecture
import Models
import SwiftUI

struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>

    var body: some View {
        VStack(spacing: 24) {
            Text("달림일기")
                .font(.largeTitle.bold())
                .frame(maxHeight: .infinity, alignment: .center)

            if let session = store.session {
                successInfo(session: session)
            }

            if store.isLoading {
                ProgressView()
            }

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            AppleSignInButton {
                store.send(.appleSignInTapped)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .disabled(store.isLoading)
        }
        .padding(24)
    }

    private func successInfo(session: AuthSession) -> some View {
        VStack(spacing: 8) {
            Text("로그인 성공")
                .font(.headline)
            if let name = session.user.name, !name.isEmpty {
                Text(name)
            }
            Text(session.user.email)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    LoginView(
        store: Store(initialState: LoginFeature.State()) {
            LoginFeature()
        }
    )
}
