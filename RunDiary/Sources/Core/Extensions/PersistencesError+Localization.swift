//
//  PersistencesError+Localization.swift
//  RunDiary
//
//  Created by 김혜지 on 1/15/26.
//

import Foundation
import PersistencesService

extension PersistencesError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return L10n.repositoryErrorNotFound.value
        case .saveFailed:
            return L10n.repositoryErrorSaveFailed.value
        case .updateFailed:
            return L10n.repositoryErrorUpdateFailed.value
        case .deleteFailed:
            return L10n.repositoryErrorDeleteFailed.value
        }
    }
}
