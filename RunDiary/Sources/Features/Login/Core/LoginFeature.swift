//
//  LoginFeature.swift
//  RunDiary
//
//  Created by 김혜지 on 6/11/26.
//

import AuthService
import ComposableArchitecture
import Foundation
import Models

@Reducer
struct LoginFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var isLoading: Bool = false
        var session: AuthSession?
        var errorMessage: String?
    }

    // MARK: - Action

    enum Action {
        case appleSignInTapped
        case signInResponse(Result<AuthSession, Error>)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            /// 로그인에 성공하고 토큰을 저장한 뒤 상위(AppFeature)에 통지한다.
            case signedIn
        }
    }

    // MARK: - Dependency

    @Dependency(\.authClient) var authClient
    @Dependency(\.tokenClient) var tokenClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .appleSignInTapped:
                state.isLoading = true
                state.errorMessage = nil

                return .run { send in
                    do {
                        let session = try await authClient.signInWithApple()
                        await send(.signInResponse(.success(session)))
                    } catch {
                        await send(.signInResponse(.failure(error)))
                    }
                }

            case let .signInResponse(.success(session)):
                state.isLoading = false
                state.session = session
                state.errorMessage = nil

                // 토큰을 키체인에 저장한 뒤 상위에 로그인 완료를 통지한다.
                do {
                    try tokenClient.saveSession(session)
                    return .send(.delegate(.signedIn))
                } catch {
                    state.session = nil
                    state.errorMessage = error.localizedDescription
                    return .none
                }

            case let .signInResponse(.failure(error)):
                state.isLoading = false

                // 사용자가 직접 취소한 경우 에러 메시지를 노출하지 않는다.
                if let authError = error as? AuthError, authError == .cancelled {
                    state.errorMessage = nil
                } else {
                    state.errorMessage = error.localizedDescription
                }

                return .none

            case .delegate:
                return .none
            }
        }
    }
}
