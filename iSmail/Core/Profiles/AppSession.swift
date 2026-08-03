//
//  AppSession.swift
//  iSmail
//
//  Global play-session state — which child profile is currently active.
//

import Foundation
import Observation

@Observable
@MainActor
final class AppSession {
    private static let activeProfileKey = "iSmail.activeProfileID"

    /// `nil` means the profile switcher should be shown.
    var activeProfileID: UUID? {
        didSet {
            if let activeProfileID {
                UserDefaults.standard.set(activeProfileID.uuidString, forKey: Self.activeProfileKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.activeProfileKey)
            }
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.activeProfileKey),
           let uuid = UUID(uuidString: raw) {
            activeProfileID = uuid
        }
    }

    func selectProfile(_ profile: ChildProfile) {
        activeProfileID = profile.id
    }

    func clearActiveProfile() {
        activeProfileID = nil
    }
}
