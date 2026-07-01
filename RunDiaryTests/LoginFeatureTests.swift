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
@Suite("LoginFeature")
struct LoginFeatureTests {
    // MARK: - Test Cases

    // TC: login-appleSignIn-success
    @Test("Apple 로그인 성공 시 세션을 저장하고 signedIn을 통지한다")
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
            // Then
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.signInResponse.success) {
            $0.isLoading = false
            $0.session = expectedSession
        }
        await store.receive(\.delegate.signedIn)
        #expect(savedSessions.value == [expectedSession])
    }

    // TC: login-appleSignIn-serverError
    @Test("Apple 로그인이 서버 에러로 실패하면 에러 메시지를 노출한다")
    func appleSignInTapped_serverError() async {
        // Given
        let expectedMessage = AuthError.serverError.localizedDescription
        let store = makeTestStore(result: .failure(AuthError.serverError))

        // When
        await store.send(.appleSignInTapped) {
            // Then
            $0.isLoading = true
        }

        await store.receive(\.signInResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = expectedMessage
        }
    }

    // TC: login-appleSignIn-cancelled
    @Test("사용자가 로그인을 취소하면 에러 메시지를 노출하지 않는다")
    func appleSignInTapped_cancelled() async {
        // Given
        let store = makeTestStore(result: .failure(AuthError.cancelled))

        // When
        await store.send(.appleSignInTapped) {
            // Then
            $0.isLoading = true
        }

        await store.receive(\.signInResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = nil
        }
    }

    // TC: login-signInResponse-tokenSaveFailure (기존 테스트 공백 → 신규 추가)
    @Test("토큰 저장에 실패하면 세션을 롤백하고 에러 메시지를 노출하며 통지하지 않는다")
    func appleSignInTapped_tokenSaveFailure() async {
        // Given
        struct TokenSaveError: Error, LocalizedError {
            var errorDescription: String? { "토큰 저장 실패" }
        }

        let expectedMessage = TokenSaveError().localizedDescription
        let store = makeTestStore(result: .success(makeSession())) {
            $0.tokenClient.saveSession = { _ in throw TokenSaveError() }
        }

        // When
        await store.send(.appleSignInTapped) {
            // Then
            $0.isLoading = true
            $0.errorMessage = nil
        }

        // 성공 응답을 받지만 토큰 저장 실패로 session은 nil로 롤백되고
        // delegate(.signedIn)은 전송되지 않는다.
        await store.receive(\.signInResponse.success) {
            $0.isLoading = false
            $0.errorMessage = expectedMessage
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
