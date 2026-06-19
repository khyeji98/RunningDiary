//
//  RootView.swift
//  RunDiary
//
//  Created by 김혜지 on 6/17/26.
//

import ComposableArchitecture
import SwiftUI

/// 앱의 최상위 뷰. `AppFeature.State.Route`에 따라 화면을 분기한다.
struct RootView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            switch store.route {
            case .loading:
                ProgressView()

            case .login:
                LoginView(store: store.scope(state: \.login, action: \.login))

            case .main:
                DailyDetailView(store: store.scope(state: \.daily, action: \.daily))
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
