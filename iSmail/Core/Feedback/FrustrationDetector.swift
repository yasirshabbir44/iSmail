//
//  FrustrationDetector.swift
//  iSmail
//
//  Detects frantic multi-tapping (executive overload / guessing) and offers a calm pause.
//

import Foundation
import Observation

/// Tracks rapid taps and temporarily cools down interaction when spam is detected.
@MainActor
@Observable
final class FrustrationDetector {
    /// When `true`, card / stage inputs should ignore touches.
    private(set) var isCoolingDown = false

    /// Drives the soft calming overlay banner.
    private(set) var showCalmBanner = false

    /// Bumps when a calm pause begins — bind to sensory feedback if desired.
    private(set) var calmTrigger = 0

    private var tapTimestamps: [Date] = []
    private var cooldownGeneration = 0
    private var lastRecordedAt: Date?

    /// Window used to judge “rapid” tapping.
    var tapWindow: TimeInterval = 2.0

    /// Trigger when the count of taps inside `tapWindow` exceeds this value.
    var tapThreshold: Int = 5

    /// How long inputs stay disabled after a trigger.
    var cooldownDuration: TimeInterval = 3.0

    /// Call on each discrete tap / press end inside the activity stage.
    func recordTap() {
        guard !isCoolingDown else { return }

        let now = Date()
        // Collapse duplicate signals from gesture + attempt callbacks for one press.
        if let lastRecordedAt, now.timeIntervalSince(lastRecordedAt) < 0.05 {
            return
        }
        lastRecordedAt = now

        tapTimestamps.append(now)
        tapTimestamps.removeAll { now.timeIntervalSince($0) > tapWindow }

        // Spec: more than 5 rapid taps in under 2 seconds.
        if tapTimestamps.count > tapThreshold {
            beginCooldown()
        }
    }

    /// Clears state for a new activity / session.
    func reset() {
        cooldownGeneration += 1
        tapTimestamps.removeAll()
        lastRecordedAt = nil
        isCoolingDown = false
        showCalmBanner = false
    }

    private func beginCooldown() {
        isCoolingDown = true
        showCalmBanner = true
        calmTrigger += 1
        tapTimestamps.removeAll()
        AudioHapticManager.shared.playBreathingChime()

        cooldownGeneration += 1
        let token = cooldownGeneration
        SafeAsync.after(cooldownDuration) {
            guard token == self.cooldownGeneration else { return }
            self.isCoolingDown = false
            self.showCalmBanner = false
        }
    }
}
