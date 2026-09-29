//
//  Sauna_Companion_Watch_AppApp.swift
//  Sauna Companion Watch App
//

import SwiftUI

@main
struct Sauna_Companion_Watch_AppApp: App {
    // The session store is owned here rather than inside the root view so it
    // exists, and is registered for App Intents, from the moment the app
    // launches: an Action button press launches the app and can run its
    // intent before any view has been built.
    @State private var store: SessionStore

    init() {
        // Apple rates only Apple Watch Ultra for a sauna, up to 55 °C, so no
        // other model starts a session at all.
        let store = SessionStore(
            recorder: HealthKitSessionRecorder(),
            hapticScheduler: HapticScheduler(),
            supportsSessions: WatchHardware.isUltra
        )
        store.makeCurrent()
        _store = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            SessionRootView(store: store)
                .task {
                    await HealthKitAuthorization.requestAuthorization()
                    WatchConnectivityService.shared.activate()
                }
        }
    }
}
