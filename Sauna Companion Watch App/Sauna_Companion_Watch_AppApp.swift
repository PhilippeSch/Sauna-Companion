//
//  Sauna_Companion_Watch_AppApp.swift
//  Sauna Companion Watch App
//

import SwiftUI
import WatchKit

@main
struct Sauna_Companion_Watch_AppApp: App {
    // The session store is owned here rather than inside the root view so it
    // exists, and is registered for App Intents, from the moment the app
    // launches: an Action button press launches the app and can run its
    // intent before any view has been built.
    @State private var store: SessionStore
    @State private var thermalWarning: ThermalWarning

    init() {
        let store = SessionStore(
            recorder: HealthKitSessionRecorder(),
            hapticScheduler: HapticScheduler()
        )
        store.makeCurrent()
        _store = State(initialValue: store)

        // A tap for every step the watch heats up by, but only during a
        // session: with none running, there is no sauna to leave.
        let thermalWarning = ThermalWarning(readState: Self.thermalState) { [weak store] _ in
            guard store?.isActive == true else { return }
            WKInterfaceDevice.current().play(.failure)
        }
        thermalWarning.startMonitoring()
        _thermalWarning = State(initialValue: thermalWarning)
    }

    private static func thermalState() -> ProcessInfo.ThermalState {
        #if DEBUG
        // A simulator cannot heat up, so Debug builds take a stand-in from the
        // user default SAUNA_DEBUG_THERMAL_STATE: 2 for serious, 3 for
        // critical. `simctl launch` passes neither environment variables nor
        // launch arguments to a watch app, so it is set from lldb inside the
        // running app — the README has the commands. Read as a string, which
        // also covers a value stored as a number.
        if let raw = UserDefaults.standard.string(forKey: "SAUNA_DEBUG_THERMAL_STATE").flatMap(Int.init),
           let state = ProcessInfo.ThermalState(rawValue: raw) {
            return state
        }
        #endif
        return ProcessInfo.processInfo.thermalState
    }

    var body: some Scene {
        WindowGroup {
            SessionRootView(store: store)
                .environment(thermalWarning)
                .task {
                    await HealthKitAuthorization.requestAuthorization()
                    WatchConnectivityService.shared.activate()
                }
        }
    }
}
