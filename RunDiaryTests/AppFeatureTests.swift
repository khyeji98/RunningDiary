//
//  AppFeatureTests.swift
//  RunDiaryTests
//
//  Created by 김혜지 on 6/17/26.
//

import ComposableArchitecture
import Testing

@testable import RunDiary

@MainActor
struct AppFeatureTests {
    // MARK: - Test Cases

    @Test("앱 진입 시 키체인에 토큰이 있으면 메인으로 라우팅한다")
    func onAppear_hasToken_routesToMain() async {
        // Given
        let expectedRoute = AppFeature.State.Route.main
        let store = makeTestStore(hasValidSession: true)

        // When
        await store.send(.onAppear) {
            // Then
            $0.route = expectedRoute
        }
    }

    @Test("앱 진입 시 키체인에 토큰이 없으면 로그인으로 라우팅한다")
    func onAppear_noToken_routesToLogin() async {
        // Given
        let expectedRoute = AppFeature.State.Route.login
        let store = makeTestStore(hasValidSession: false)

        // When
        await store.send(.onAppear) {
            // Then
            $0.route = expectedRoute
        }
    }

    @Test("로그인 완료(signedIn) 통지를 받으면 메인으로 라우팅한다")
    func loginSignedIn_routesToMain() async {
        // Given
        let expectedRoute = AppFeature.State.Route.main
        let store = makeTestStore(hasValidSession: false)

        // When
        await store.send(.login(.delegate(.signedIn))) {
            // Then
            $0.route = expectedRoute
        }
    }

    // MARK: - Helper

    private func makeTestStore(
        hasValidSession: Bool
    ) -> TestStore<AppFeature.State, AppFeature.Action> {
        TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.tokenClient.hasValidSession = { hasValidSession }
        }
    }
}
