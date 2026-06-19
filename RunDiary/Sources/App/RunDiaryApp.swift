//
//  RunDiaryApp.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import ComposableArchitecture
import PersistencesService
import SwiftData
import SwiftUI

@main
struct RunDiaryApp: App {
    let modelContainer = DataModel.shared.container
    let store: StoreOf<AppFeature>

    init() {
        self.store = Store(initialState: AppFeature.State()) {
            AppFeature()
                ._printChanges()
        } withDependencies: {
            $0.persistencesClient = .live(modelContext: DataModel.shared.container.mainContext)
            $0.healthKitClient = .liveValue
            $0.authClient = .liveValue
            $0.tokenClient = .liveValue
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .modelContainer(modelContainer)
        }
    }
}
