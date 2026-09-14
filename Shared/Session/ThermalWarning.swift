//
//  ThermalWarning.swift
//  Sauna Companion
//
//  Watches the device's own thermal state and says when it runs hot. On the
//  watch, in a sauna, that is the device reporting it is past what it is
//  rated for, so the user is told — on screen, and with a tap for every step
//  it heats up by, felt even with the screen off.
//
//  Warn only, by decision: ending the session on the user's behalf was
//  considered and turned down. The session keeps running.
//
//  The state source and the escalation hook are injected so the logic can be
//  tested without a hot watch; the watch supplies ProcessInfo and a haptic.
//

import Foundation
import Observation

@MainActor
@Observable
final class ThermalWarning {
    /// True while the device reports itself `serious` or `critical`.
    private(set) var isOverheating = false

    private let readState: () -> ProcessInfo.ThermalState
    private let onEscalation: (ProcessInfo.ThermalState) -> Void
    private var lastState: ProcessInfo.ThermalState = .nominal
    @ObservationIgnored private var monitoring: Task<Void, Never>?

    init(
        readState: @escaping () -> ProcessInfo.ThermalState,
        onEscalation: @escaping (ProcessInfo.ThermalState) -> Void
    ) {
        self.readState = readState
        self.onEscalation = onEscalation
        // A watch that is already hot when this is created counts as a step
        // up from nominal.
        refresh()
    }

    /// Follows the system's thermal notifications from here on.
    func startMonitoring() {
        guard monitoring == nil else { return }
        monitoring = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: ProcessInfo.thermalStateDidChangeNotification) {
                guard let self else { return }
                self.refresh()
            }
        }
    }

    /// Reads the current state. Escalates only on a step up into the hot
    /// range — the same heat again, or cooling from critical to serious, stays
    /// quiet, while heating up again after cooling down taps again.
    func refresh() {
        let state = readState()
        let isHot = Self.isHot(state)
        if isHot, state.rawValue > lastState.rawValue {
            onEscalation(state)
        }
        isOverheating = isHot
        lastState = state
    }

    private static func isHot(_ state: ProcessInfo.ThermalState) -> Bool {
        state.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    }
}
