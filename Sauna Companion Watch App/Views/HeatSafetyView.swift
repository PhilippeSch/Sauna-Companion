//
//  HeatSafetyView.swift
//  Sauna Companion Watch App
//
//  Shown before anything else on first launch, and again from settings on
//  request. Apple rates most Apple Watch models not to be worn in a sauna at
//  all and Ultra only up to 55 °C, and App Review rejected the app under
//  guideline 2.4.2 for encouraging use that could damage the watch.
//
//  The limits are Apple's own, from "About Apple Watch water resistance"
//  (support.apple.com/109522). Keep the wording in step with that page rather
//  than with what feels reasonable in a sauna.
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

                Button("I Understand", action: onAccept)
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
            Text("Apple says Apple Watch Ultra can be worn in a sauna up to 55 °C.")
        } else {
            Text("Apple says this Apple Watch should not be worn in a sauna. Only Apple Watch Ultra is made for it, up to 55 °C.")
        }
    }
}

#Preview {
    HeatSafetyView(onAccept: {})
}
