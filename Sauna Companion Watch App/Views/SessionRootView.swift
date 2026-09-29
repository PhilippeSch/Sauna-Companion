//
//  SessionRootView.swift
//  Sauna Companion Watch App
//

import SwiftUI

struct SessionRootView: View {
    @Bindable var store: SessionStore
    private var settings = SettingsStore.shared

    /// Apple's heat limits for the watch have to be accepted once, before
    /// anything else — which is why the Action button notice waits for it.
    /// Set only by the button, never by a dismissal.
    @AppStorage("saunaTracker.hasAcceptedHeatSafety") private var hasAcceptedHeatSafety = false
    @State private var showingHeatSafety = false

    /// The Action button has to be pointed at this app in Settings, which is
    /// worth saying once on the models that have one.
    @AppStorage("saunaTracker.hasSeenActionButtonInfo") private var hasSeenActionButtonInfo = false
    @State private var showingActionButtonInfo = false

    init(store: SessionStore) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            switch store.stage {
            case .idle:
                IdlePager(store: store, settings: settings)
            case .active:
                ActiveSessionPager(store: store)
            case .saving:
                SavingSessionView()
            case .summary(let session):
                EndSessionSummaryView(
                    session: session,
                    errorDescription: store.lastErrorDescription,
                    onDone: { store.reset() }
                )
            }
        }
        // Settings can change on either device; keep the running session in
        // step with whatever the store currently holds.
        .onChange(of: settings.settings) { _, newSettings in
            store.applySettings(newSettings)
        }
        .sheet(isPresented: $showingHeatSafety) {
            // watchOS shows one sheet at a time, so the Action button notice
            // follows this one rather than competing with it.
            showActionButtonInfoIfNeeded()
        } content: {
            HeatSafetyView {
                hasAcceptedHeatSafety = true
                showingHeatSafety = false
            }
            // Accepting is the point of this sheet. Disabling interactive
            // dismissal stops the swipe but still leaves watchOS's close
            // button in the corner, so that goes too.
            .interactiveDismissDisabled()
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingActionButtonInfo) {
            // Also covers a swipe-down dismissal, so it never comes back.
            hasSeenActionButtonInfo = true
        } content: {
            ActionButtonInfoView { showingActionButtonInfo = false }
        }
        .task {
            // Re-asserts the registration made at launch, against the instance
            // the UI actually kept.
            store.makeCurrent()
            store.applySettings(settings.settings)

            // The Action button can start a session before there is a store to
            // act on; finish that start now that there is one.
            if PendingSessionStart.isRequested {
                PendingSessionStart.isRequested = false
                if !store.isActive {
                    await store.startSession()
                }
            }

            // Only a watch that can run a session has a limit to accept.
            if hasAcceptedHeatSafety || !store.supportsSessions {
                showActionButtonInfoIfNeeded()
            } else {
                showingHeatSafety = true
            }
        }
    }

    private func showActionButtonInfoIfNeeded() {
        showingActionButtonInfo = !hasSeenActionButtonInfo && WatchHardware.hasActionButton
    }
}

struct SavingSessionView: View {
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Saving…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        // Offered the whole screen, ProgressView takes all of it and draws its
        // spinner in the middle of that box, which pushed the label to the
        // bottom edge — nothing like the 10pt above. Ask for the ideal height
        // instead, then centre the pair as one block.
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
