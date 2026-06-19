//
//  LoginFeatureTests.swift
//  RunDiaryTests
//
//  Created by 김혜지 on 6/11/26.
//

import AuthService
import ComposableArchitecture
import Foundation
import Models
import Testing

@testable import RunDiary

@MainActor
struct LoginFeatureTests {
    // MARK: - Test Cases

    @Test("Apple 로그인 버튼 탭 후 성공 시 세션을 저장하고 signedIn을 통지한다")
    func appleSignInTapped_success() async {
        // Given
        let expectedSession = makeSession()
        let savedSessions = LockIsolated<[AuthSession]>([])
        let store = makeTestStore(result: .success(expectedSession)) {
            $0.tokenClient.saveSession = { session in
                savedSessions.withValue { $0.append(session) }
            }
        }

        // When
        await store.send(.appleSignInTapped) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        // Then
        await store.receive(\.signInResponse.success) {
            $0.isLoading = false
            $0.session = expectedSession
        }
        await store.receive(\.delegate.signedIn)
        #expect(savedSessions.value == [expectedSession])
    }

    @Test("Apple 로그인 실패 시 에러 메시지를 노출한다")
    func appleSignInTapped_serverError() async {
        // Given
        let store = makeTestStore(result: .failure(AuthError.serverError))

        // When
        await store.send(.appleSignInTapped) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.signInResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = AuthError.serverError.localizedDescription
        }
    }

    @Test("사용자가 로그인을 취소하면 에러 메시지를 노출하지 않는다")
    func appleSignInTapped_cancelled() async {
        // Given
        let store = makeTestStore(result: .failure(AuthError.cancelled))

        // When
        await store.send(.appleSignInTapped) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.signInResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = nil
        }
    }

    // MARK: - Helper

    private func makeTestStore(
        result: Result<AuthSession, Error>,
        configure: (inout DependencyValues) -> Void = { _ in }
    ) -> TestStore<LoginFeature.State, LoginFeature.Action> {
        TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        } withDependencies: {
            $0.authClient.signInWithApple = {
                try result.get()
            }
            $0.tokenClient.saveSession = { _ in }
            configure(&$0)
        }
    }

    private func makeSession() -> AuthSession {
        AuthSession(
            accessToken: "test-access-token",
            tokenType: "bearer",
            user: AuthUser(
                id: "test-user-id",
                email: "apple@example.com",
                provider: .apple,
                name: "Apple User"
            )
        )
    }
}
