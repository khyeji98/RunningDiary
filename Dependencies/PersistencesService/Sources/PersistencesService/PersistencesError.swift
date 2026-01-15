//
//  PersistencesError.swift
//  RunDiary
//
//  Created by 김혜지 on 11/5/25.
//

import Foundation

public enum PersistencesError: Error {
    case notFound
    case saveFailed
    case updateFailed
    case deleteFailed
}
