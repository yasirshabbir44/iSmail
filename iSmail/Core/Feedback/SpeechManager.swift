//
//  SpeechManager.swift
//  iSmail
//
//  Friendly read-aloud for ADHD-friendly prompts (reading fatigue / missed text).
//

import AVFoundation
import Foundation

/// Singleton voice guidance using `AVSpeechSynthesizer`.
@MainActor
final class SpeechManager: NSObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()

    /// Clear, kid-friendly speaking rate (slightly slower than default ~0.5).
    private let preferredRate: Float = 0.48

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks `text` with a natural en-US voice. Stops any in-flight utterance first.
    func speak(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        configureSessionIfNeeded()

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = preferredRate
        utterance.pitchMultiplier = 1.05
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.05
        synthesizer.speak(utterance)
    }

    /// Stops speech immediately (e.g. when leaving an activity).
    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func configureSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .spokenAudio, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            // Ambient fallback — speech may still work with the default session.
        }
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {}
