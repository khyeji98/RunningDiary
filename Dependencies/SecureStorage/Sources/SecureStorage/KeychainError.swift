//
//  KeychainError.swift
//  SecureStorage
//
//  Created by 김혜지 on 6/17/26.
//

import Foundation

/// 키체인 접근 중 발생할 수 있는 에러.
public enum KeychainError: Error, Equatable {
    /// 저장할 문자열을 Data로 변환하지 못함.
    case invalidData
    /// SecItem API가 실패한 경우의 OSStatus.
    case unhandled(status: OSStatus)
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidData: return "키체인에 저장할 데이터 변환에 실패했습니다."
        case let .unhandled(status): return "키체인 작업이 실패했습니다. 상태 코드: \(status)"
        }
    }
}
