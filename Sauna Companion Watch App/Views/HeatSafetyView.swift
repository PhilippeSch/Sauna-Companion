//
//  HeatSafetyView.swift
//  Sauna Companion Watch App
//
//  Shown before anything else on first launch, and again from settings on
//  request. Sessions only run on Apple Watch Ultra, so this is the Ultra's
//  limit: the user has to accept wearing it only up to 55 °C before the app
//  can be used. Whether they keep to it is theirs to decide; the app does not
//  check.
//
//  The limit is Apple's own, from "About Apple Watch water resistance"
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

                Text("By tapping Accept, you agree to wear your Apple Watch only within these limits:")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("Apple Watch Ultra: in a sauna up to 55 °C at most.")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.18), in: .rect(cornerRadius: 8))

                Text("Infrared cabins can be run within this limit; a Finnish sauna at 80–100 °C is far above it.")
                    .font(.system(size: 13))

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
}

#Preview {
    HeatSafetyView(onAccept: {})
}
