//
//  SecureStoring.swift
//  SecureStorage
//
//  Created by 김혜지 on 6/17/26.
//

/// 키체인 같은 보안 저장소에 문자열 값을 저장/조회/삭제하는 추상화.
///
/// 테스트에서 인메모리 구현으로 대체할 수 있도록 프로토콜로 분리한다.
public protocol SecureStoring: Sendable {
    /// 값을 저장한다. 동일 키가 존재하면 덮어쓴다(upsert).
    func save(_ value: String, for key: KeychainKey) throws

    /// 값을 조회한다. 없으면 `nil`.
    func read(_ key: KeychainKey) -> String?

    /// 값을 삭제한다. 존재하지 않아도 에러를 던지지 않는다.
    func delete(_ key: KeychainKey) throws
}
