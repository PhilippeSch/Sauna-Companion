//
//  ThermalWarningTests.swift
//  Sauna CompanionTests
//
//  When the overheating warning shows and when its tap fires: once for every
//  step the device heats up by, never twice for the same heat, never on the
//  way down.
//

import Testing
import Foundation
@testable import Sauna_Companion

@MainActor
struct ThermalWarningTests {

    /// Stands in for the device: a thermal state set by hand, and a log of
    /// every escalation the warning reported.
    final class FakeDevice {
        var state: ProcessInfo.ThermalState = .nominal
        var escalations: [ProcessInfo.ThermalState] = []
    }

    private func make(startingAt state: ProcessInfo.ThermalState = .nominal) -> (ThermalWarning, FakeDevice) {
        let device = FakeDevice()
        device.state = state
        let warning = ThermalWarning(
            readState: { device.state },
            onEscalation: { device.escalations.append($0) }
        )
        return (warning, device)
    }

    @Test func staysQuietWhileTheDeviceIsCool() {
        let (warning, device) = make()

        device.state = .fair
        warning.refresh()

        #expect(warning.isOverheating == false)
        #expect(device.escalations.isEmpty)
    }

    @Test func warnsOnceWhenTheDeviceTurnsSerious() {
        let (warning, device) = make()

        device.state = .serious
        warning.refresh()
        warning.refresh()

        #expect(warning.isOverheating)
        #expect(device.escalations == [.serious], "the same heat must not tap twice")
    }

    @Test func tapsAgainWhenItGetsWorse() {
        let (warning, device) = make()

        device.state = .serious
        warning.refresh()
        device.state = .critical
        warning.refresh()

        #expect(warning.isOverheating)
        #expect(device.escalations == [.serious, .critical])
    }

    @Test func coolingFromCriticalToSeriousStaysQuiet() {
        let (warning, device) = make(startingAt: .critical)

        device.state = .serious
        warning.refresh()

        #expect(warning.isOverheating, "serious is still too hot")
        #expect(device.escalations == [.critical])
    }

    @Test func coolingDownClearsTheWarning() {
        let (warning, device) = make(startingAt: .serious)

        device.state = .fair
        warning.refresh()

        #expect(warning.isOverheating == false)
        #expect(device.escalations == [.serious])
    }

    @Test func heatingUpAgainAfterCoolingDownTapsAgain() {
        let (warning, device) = make()

        device.state = .serious
        warning.refresh()
        device.state = .fair
        warning.refresh()
        device.state = .serious
        warning.refresh()

        #expect(warning.isOverheating)
        #expect(device.escalations == [.serious, .serious])
    }

    @Test func aDeviceThatIsAlreadyHotIsFlaggedStraightAway() {
        let (warning, device) = make(startingAt: .critical)

        #expect(warning.isOverheating)
        #expect(device.escalations == [.critical])
    }
}
