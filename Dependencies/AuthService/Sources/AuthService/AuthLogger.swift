//
//  AuthLogger.swift
//  AuthService
//
//  Created by 김혜지 on 6/17/26.
//

import Foundation
import OSLog

/// 인증(소셜 로그인 / 토큰 갱신) API 에러 디버깅용 로거.
///
/// auth API 에러는 외부로 던지기 전에 `AuthError`로 단순화되어 원인이 소실되기 쉽다.
/// 이 로거로 던지기 직전의 **원본 에러와 컨텍스트**를 OSLog에 남겨 Console.app /
/// `log stream`에서 추적할 수 있게 한다.
///
/// 앱 타겟 `AppLogger`와 동일한 subsystem을 사용해 한 곳에서 필터링된다.
/// (필터 예: `subsystem == "com.kimhyeji.RunDiary" && category == "Auth"`)
enum AuthLogger {
    private static let logger = Logger(
        subsystem: "com.kimhyeji.RunDiary",
        category: "Auth"
    )

    static func debug(
        _ message: String,
        file: String = #fileID,
        line: Int = #line
    ) {
        logger.debug("[\(shortFile(file), privacy: .public):\(line, privacy: .public)] \(message, privacy: .public)")
    }

    static func info(
        _ message: String,
        file: String = #fileID,
        line: Int = #line
    ) {
        logger.info("[\(shortFile(file), privacy: .public):\(line, privacy: .public)] \(message, privacy: .public)")
    }

    /// 에러와 함께 컨텍스트 메시지를 남긴다. 디버깅을 위해 타입/도메인/코드까지 기록한다.
    static func error(
        _ message: String,
        error: Error? = nil,
        file: String = #fileID,
        line: Int = #line
    ) {
        var detail = message

        if let error {
            let nsError = error as NSError
            detail += " | error=\(type(of: error)) domain=\(nsError.domain) code=\(nsError.code) description=\(error.localizedDescription)"
        }

        logger.error("[\(shortFile(file), privacy: .public):\(line, privacy: .public)] \(detail, privacy: .public)")
    }

    private static func shortFile(_ file: String) -> String {
        (file as NSString).lastPathComponent
    }
}
