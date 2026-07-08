//
//  AppFeature.swift
//  RunDiary
//
//  Created by 김혜지 on 6/17/26.
//

import ComposableArchitecture

/// 앱 진입점 라우팅을 담당하는 루트 리듀서.
///
/// 앱 시작 시 키체인에 저장된 토큰 존재 여부로 로그인/메인 화면을 결정하고,
/// 로그인 완료 통지를 받아 메인으로 전환한다.
@Reducer
struct AppFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        enum Route: Equatable {
            case loading
            case login
            case main
        }

        var route: Route = .loading
        var login = LoginFeature.State()
        var daily = DailyDetailFeature.State()
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case login(LoginFeature.Action)
        case daily(DailyDetailFeature.Action)
    }

    // MARK: - Dependency

    @Dependency(\.tokenClient) var tokenClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }

        Scope(state: \.daily, action: \.daily) {
            DailyDetailFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                state.route = tokenClient.hasValidSession() ? .main : .login
                return .none

            case .login(.delegate(.signedIn)):
                state.route = .main
                return .none

            // TODO: 로그아웃/refresh 최종 실패 시 .signedOut delegate 수신
            //       → tokenClient.clear() 후 state.route = .login 으로 전환한다.
            case .login, .daily:
                return .none
            }
        }
    }
}
