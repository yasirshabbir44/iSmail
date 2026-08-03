//
//  iSmailApp.swift
//  iSmail
//
//  Created by Yasir Shabbir on 04/08/2026.
//

import SwiftData
import SwiftUI

@main
struct iSmailApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .modelContainer(for: ChildProfile.self)
    }
}

/// Routes between the profile switcher and the main activity dashboard.
private struct RootView: View {
    @Environment(AppSession.self) private var session
    @Query private var profiles: [ChildProfile]

    private var activeProfile: ChildProfile? {
        guard let id = session.activeProfileID else { return nil }
        return profiles.first { $0.id == id }
    }

    var body: some View {
        Group {
            if let profile = activeProfile {
                ContentView(profile: profile)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(profile.id)
            } else {
                ProfileSelectionView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(LearningTheme.forgivingSpring, value: session.activeProfileID)
        .onAppear {
            // Drop a stale ID if the profile was deleted.
            if let id = session.activeProfileID,
               !profiles.contains(where: { $0.id == id }) {
                session.clearActiveProfile()
            }
        }
    }
}
