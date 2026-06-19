//
//  AuthError.swift
//  AuthService
//
//  Created by 김혜지 on 6/11/26.
//

import Foundation

public enum AuthError: Error, Equatable {
    /// 사용자가 로그인을 취소함
    case cancelled
    /// 소셜 provider로부터 받은 자격 증명이 유효하지 않음
    case invalidCredential
    /// 서버 API 통신 실패
    case serverError
    /// accessToken이 만료되었고 refresh로도 갱신하지 못함(재로그인 필요)
    case tokenExpired
    /// 아직 구현되지 않음
    case notImplemented
}
