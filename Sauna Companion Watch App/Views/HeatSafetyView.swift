//
//  HeatSafetyView.swift
//  Sauna Companion Watch App
//
//  Shown before anything else on first launch, and again from settings on
//  request. The user has to accept wearing the watch only within Apple's
//  limits before the app can be used; whether they keep to them is theirs to
//  decide, and the app does not check.
//
//  The limits are Apple's own: Ultra in a sauna up to 55 °C, from "About Apple
//  Watch water resistance" (support.apple.com/109522), and 35 °C for every
//  other model, the top of its operating range (support.apple.com/108766).
//  Keep the wording in step with those pages rather than with what feels
//  reasonable in a sauna.
//

import SwiftUI

struct HeatSafetyView: View {
    var onAccept: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "thermometer.sun.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.orange)

                Text("Heat and Your Watch")
                    .font(.headline)

                Text("By tapping Accept, you agree to wear your Apple Watch only within these limits:")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                modelLimit
                    .font(.system(size: 13, weight: .semibold))
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.18), in: .rect(cornerRadius: 8))

                Text("No Apple Watch should be worn in a steam room.")
                    .font(.system(size: 13))

                Text("If your watch gets hot or shows a temperature warning, take it off and let it cool down.")
                    .font(.system(size: 13))

                Text("You use Sauna Companion at your own risk. We accept no liability for damage to your Apple Watch.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Button("Accept", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 4)
        }
    }

    /// Apple's limit for the model this runs on. Two literal `Text`s rather
    /// than one with a computed key, so string extraction sees both.
    @ViewBuilder
    private var modelLimit: some View {
        if WatchHardware.isUltra {
            Text("Apple Watch Ultra: in a sauna up to 55 °C at most.")
        } else {
            Text("This Apple Watch: up to 35 °C at most — Apple does not rate it for a sauna.")
        }
    }
}

#Preview {
    HeatSafetyView(onAccept: {})
}
