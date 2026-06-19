//
//  AppleAuthorizationController.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

import AuthenticationServices
import UIKit

/// Apple 로그인에서 추출한, 서버 전달에 필요한 자격 증명.
struct AppleCredential: Sendable {
    /// Apple identity token(JWT) 문자열.
    let idToken: String
    /// 사용자 이름. Apple이 최초 로그인 1회에만 제공하므로 그 외에는 nil.
    let name: String?
}

/// `ASAuthorizationController`의 delegate 기반 플로우를 async/await로 브리지하는 래퍼.
@MainActor
final class AppleAuthorizationController: NSObject {
    private var continuation: CheckedContinuation<AppleCredential, Error>?
    /// 인증이 끝날 때까지 self를 살려두기 위한 강한 참조.
    private var retainedSelf: AppleAuthorizationController?

    /// Apple 로그인을 수행하고 자격 증명을 비동기로 반환한다.
    func authorize() async throws -> AppleCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.retainedSelf = self

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    private func finish(with result: Result<AppleCredential, Error>) {
        continuation?.resume(with: result)
        continuation = nil
        retainedSelf = nil
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleAuthorizationController: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(AuthError.invalidCredential))
            return
        }

        guard
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            finish(with: .failure(AuthError.invalidCredential))
            return
        }

        let name = credential.fullName.flatMap { components -> String? in
            let formatter = PersonNameComponentsFormatter()
            let formatted = formatter.string(from: components)
            return formatted.isEmpty ? nil : formatted
        }

        finish(with: .success(AppleCredential(idToken: idToken, name: name)))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            finish(with: .failure(AuthError.cancelled))
        } else {
            finish(with: .failure(AuthError.invalidCredential))
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleAuthorizationController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let activeWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow

        return activeWindow ?? ASPresentationAnchor()
    }
}
