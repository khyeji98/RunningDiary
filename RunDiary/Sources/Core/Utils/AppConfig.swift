//
//  AppConfig.swift
//  RunDiary
//
//  Created by 김혜지 on 6/11/26.
//

import Foundation

/// 빌드 구성(xcconfig → Info.plist)에서 주입된 앱 설정 값을 읽는다.
enum AppConfig {
    /// 서버 기본 URL(scheme + host).
    ///
    /// `Config/Secrets.xcconfig`의 `API_BASE_URL_DEBUG`/`API_BASE_URL_RELEASE`가
    /// 빌드 설정 `API_BASE_URL` → Info.plist를 거쳐 주입된다.
    static var baseURL: String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
            !value.isEmpty
        else {
            assertionFailure("API_BASE_URL이 Info.plist에 주입되지 않았습니다.")
            return ""
        }

        return value
    }
}
