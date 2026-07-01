//
//  AuthServiceTests.swift
//  AuthServiceTests
//
//  Created by 김혜지 on 6/11/26.
//

import Foundation
import Models
import Testing

@testable import AuthService

@Suite("AuthService")
struct AuthServiceTests {

    // MARK: - AuthSession Codable

    @Test("서버 응답 JSON을 AuthSession으로 디코딩 시 snake_case 키가 매핑된다")
    func decode_mapsServerSchema() throws {
        // Given
        let expectedAccessToken = "server-access-token"
        let expectedTokenType = "bearer"
        let expectedUser = AuthUser(
            id: "user-1",
            email: "runner@example.com",
            provider: .apple,
            name: "러너"
        )
        let json = """
        {
            "access_token": "server-access-token",
            "token_type": "bearer",
            "user": {
                "id": "user-1",
                "email": "runner@example.com",
                "provider": "apple",
                "name": "러너"
            }
        }
        """

        // When
        let session = try makeDecoder().decode(AuthSession.self, from: Data(json.utf8))

        // Then
        #expect(session.accessToken == expectedAccessToken)
        #expect(session.tokenType == expectedTokenType)
        #expect(session.user == expectedUser)
    }

    // MARK: - MockAppleLoginService

    @Test("MockAppleLoginService 로그인 시 apple provider의 AuthSession을 반환한다")
    func appleLogin_returnsAppleSession() async throws {
        // Given
        let expectedProvider = AuthProvider.apple
        let service = makeAppleService()

        // When
        let session = try await service.login()

        // Then
        #expect(session.user.provider == expectedProvider)
        #expect(!session.accessToken.isEmpty)
    }

    // MARK: - MockGoogleLoginService

    @Test("MockGoogleLoginService 로그인 시 google provider의 AuthSession을 반환한다")
    func googleLogin_returnsGoogleSession() async throws {
        // Given
        let expectedProvider = AuthProvider.google
        let service = makeGoogleService()

        // When
        let session = try await service.login()

        // Then
        #expect(session.user.provider == expectedProvider)
        #expect(!session.accessToken.isEmpty)
    }

    // MARK: - AppleLoginRequest

    @Test("AppleLoginRequest는 convertToSnakeCase로 id_token 키로 인코딩된다")
    func encodeRequest_mapsToSnakeCase() throws {
        // Given
        let expectedIDToken = "apple-jwt"
        let expectedName = "러너"
        let request = AppleLoginRequest(idToken: expectedIDToken, name: expectedName)

        // When
        let json = try encodeToDictionary(request)

        // Then
        #expect(json["id_token"] as? String == expectedIDToken)
        #expect(json["name"] as? String == expectedName)
    }

    @Test("AppleLoginRequest는 name이 nil이면 키 자체를 생략한다")
    func encodeRequest_omitsNilName() throws {
        // Given
        let request = AppleLoginRequest(idToken: "apple-jwt", name: nil)

        // When
        let json = try encodeToDictionary(request)

        // Then
        #expect(json["id_token"] as? String == "apple-jwt")
        #expect(json.keys.contains("name") == false)
    }

    // MARK: - AppleLoginResponse

    @Test("AppleLoginResponse는 snake_case 서버 응답을 디코딩 후 AuthSession으로 매핑한다")
    func decodeResponse_mapsToAuthSession() throws {
        // Given
        let expectedSession = AuthSession(
            accessToken: "server-access-token",
            tokenType: "bearer",
            user: AuthUser(
                id: "user-1",
                email: "runner@example.com",
                provider: .apple,
                name: "러너"
            )
        )
        let json = """
        {
            "access_token": "server-access-token",
            "token_type": "bearer",
            "user": {
                "id": "user-1",
                "email": "runner@example.com",
                "provider": "apple",
                "name": "러너"
            }
        }
        """

        // When
        let response = try makeSnakeCaseDecoder().decode(AppleLoginResponse.self, from: Data(json.utf8))
        let session = response.toDomain()

        // Then
        #expect(session == expectedSession)
    }

    @Test("AppleLoginResponse는 user.name이 null이면 nil로 매핑한다")
    func decodeResponse_nullName_mapsToNilName() throws {
        // Given
        let expectedSession = AuthSession(
            accessToken: "server-access-token",
            tokenType: "bearer",
            user: AuthUser(
                id: "user-1",
                email: "runner@privaterelay.appleid.com",
                provider: .apple,
                name: nil
            )
        )
        let json = """
        {
            "access_token": "server-access-token",
            "token_type": "bearer",
            "user": {
                "id": "user-1",
                "email": "runner@privaterelay.appleid.com",
                "provider": "apple",
                "name": null
            }
        }
        """

        // When
        let response = try makeSnakeCaseDecoder().decode(AppleLoginResponse.self, from: Data(json.utf8))
        let session = response.toDomain()

        // Then
        #expect(session == expectedSession)
    }

    @Test("GoogleLoginService는 미구현 상태로 notImplemented 에러를 던진다")
    func googleLiveLogin_throwsNotImplemented() async {
        // Given
        let service = GoogleLoginService()

        // When / Then
        await #expect(throws: AuthError.notImplemented) {
            try await service.login()
        }
    }
}

// MARK: - Helpers

private extension AuthServiceTests {
    func makeDecoder() -> JSONDecoder {
        JSONDecoder()
    }

    func makeSnakeCaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    func encodeToDictionary(_ value: Encodable) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(value)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    func makeAppleService() -> AppleLoginProviding {
        MockAppleLoginService()
    }

    func makeGoogleService() -> GoogleLoginProviding {
        MockGoogleLoginService()
    }
}
