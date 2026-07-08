//
//  KeychainKey.swift
//  SecureStorage
//
//  Created by 김혜지 on 6/17/26.
//

/// 키체인에 저장되는 항목의 키.
///
/// 앱(`TokenClient`)과 `AuthService`(토큰 갱신)가 동일한 키를 공유하도록
/// 단일 지점에서 정의한다. (모듈 간 키 불일치/순환 의존 방지)
public enum KeychainKey: String, Sendable, CaseIterable {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
}
