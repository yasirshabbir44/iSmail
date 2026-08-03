//
//  HintManager.swift
//  iSmail
//
//  Adaptive hinting — after consecutive misses, surface a gentle visual cue.
//

import Foundation
import Observation

/// Tracks consecutive incorrect attempts and unlocks a soft visual hint.
@MainActor
@Observable
final class HintManager {
    /// Consecutive incorrect / missed interactions for the current task.
    private(set) var consecutiveMisses = 0

    /// When `true`, activity views should render adaptive hint chrome.
    private(set) var isHintActive = false

    /// Bumps when a hint first unlocks — bind to `.sensoryFeedback`.
    private(set) var hintUnlockTrigger = 0

    /// Misses required before the hint appears.
    var threshold: Int = 2

    /// Records an incorrect drop, tap, or failed check.
    func recordMiss() {
        consecutiveMisses += 1
        guard consecutiveMisses >= threshold, !isHintActive else { return }
        isHintActive = true
        hintUnlockTrigger += 1
        AudioHapticManager.shared.playHint()
    }

    /// Records a correct micro-step (resets the consecutive miss streak only).
    func recordHit() {
        consecutiveMisses = 0
    }

    /// Clears hint chrome — call on new task load or when the task is solved.
    func reset() {
        consecutiveMisses = 0
        isHintActive = false
    }
}
