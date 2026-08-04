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

    /// Cached best available voice (neural / premium when present).
    private let preferredVoice: AVSpeechSynthesisVoice?

    /// Natural conversational pace (default is ~0.5).
    private let preferredRate: Float = 0.50

    /// Soft girl-like warmth without sounding cartoonish.
    private let preferredPitch: Float = 1.08

    private override init() {
        preferredVoice = Self.selectBestVoice()
        super.init()
        synthesizer.delegate = self
        synthesizer.usesApplicationAudioSession = true
    }

    /// Speaks `text` with the most natural available English girl voice.
    /// Stops any in-flight utterance first.
    func speak(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        configureSessionIfNeeded()

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = preferredVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = preferredRate
        utterance.pitchMultiplier = preferredPitch
        utterance.volume = 1.0
        // Small lead-in so the first syllable isn’t clipped after session activation.
        utterance.preUtteranceDelay = 0.08
        utterance.postUtteranceDelay = 0.04
        synthesizer.speak(utterance)
    }

    /// Stops speech immediately (e.g. when leaving an activity).
    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Voice selection

    /// Picks the most natural English *girl* voice available on-device.
    /// Preference: premium/enhanced female → Siri neural female → named warm female → avoid Samantha compact.
    private static func selectBestVoice() -> AVSpeechSynthesisVoice? {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.hasPrefix("en")
        }
        guard !english.isEmpty else {
            return AVSpeechSynthesisVoice(language: "en-US")
        }

        // Try well-known natural female identifiers first (when downloaded / present).
        if let pinned = pinnedNaturalGirlVoice(from: english) {
            return pinned
        }

        let ranked = english.sorted { lhs, rhs in
            let left = score(lhs)
            let right = score(rhs)
            if left != right { return left > right }
            return lhs.name < rhs.name
        }

        return ranked.first
    }

    /// Explicitly prefer modern natural female voices when installed on the device.
    private static func pinnedNaturalGirlVoice(
        from voices: [AVSpeechSynthesisVoice]
    ) -> AVSpeechSynthesisVoice? {
        // Ordered: most human-sounding girl coaches first.
        let preferredIDs = [
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.enhanced.en-US.Zoe",
            "com.apple.voice.compact.en-US.Zoe",
            "com.apple.voice.premium.en-US.Ava",
            "com.apple.voice.enhanced.en-US.Ava",
            "com.apple.voice.compact.en-US.Ava",
            "com.apple.voice.premium.en-US.Nicky",
            "com.apple.voice.enhanced.en-US.Nicky",
            "com.apple.ttsbundle.siri_Nicky_en-US_compact",
            "com.apple.voice.compact.en-US.Nicky",
            "com.apple.ttsbundle.siri_female_en-US_compact",
            "com.apple.voice.premium.en-US.Allison",
            "com.apple.voice.enhanced.en-US.Allison",
            "com.apple.voice.compact.en-US.Allison",
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.premium.en-US.Samantha",
        ]

        let byID = Dictionary(uniqueKeysWithValues: voices.map { ($0.identifier, $0) })
        for id in preferredIDs {
            if let voice = byID[id] { return voice }
        }

        // Fuzzy match: Siri / neural female en-US by name when IDs differ across OS versions.
        let fuzzyNames = ["zoe", "ava", "nicky", "allison", "siri"]
        for name in fuzzyNames {
            if let match = voices.first(where: { voice in
                voice.gender == .female
                    && voice.language.hasPrefix("en-US")
                    && (voice.name.lowercased().contains(name)
                        || voice.identifier.lowercased().contains(name))
                    && !voice.identifier.lowercased().contains("novelty")
            }) {
                return match
            }
        }

        return nil
    }

    private static func score(_ voice: AVSpeechSynthesisVoice) -> Int {
        var score = 0
        let id = voice.identifier.lowercased()
        let name = voice.name.lowercased()

        // Quality tiers (premium/enhanced require user download; use when present).
        switch voice.quality {
        case .premium: score += 400
        case .enhanced: score += 280
        default: break
        }

        // On-device neural voices (Siri-class). Misnamed “super-compact” but highest quality.
        if id.contains("super-compact") || id.contains("siri") {
            score += 220
        } else if id.contains("premium") {
            score += 160
        } else if id.contains("enhanced") {
            score += 100
        } else if id.contains("compact") {
            score -= 20 // default compact voices sound more robotic
        }

        // Locale preference for this app’s English content.
        if voice.language == "en-US" {
            score += 50
        } else if voice.language.hasPrefix("en-") {
            score += 15
        }

        // Strongly prefer a girl / young-woman coach voice.
        switch voice.gender {
        case .female:
            score += 120
        case .male:
            score -= 80
        default:
            break
        }

        // Modern natural-sounding Apple girl voices (boost heavily).
        let naturalGirls = ["zoe", "ava", "nicky", "allison", "susan", "karen", "moira", "tessa", "fiona"]
        if naturalGirls.contains(where: { name.contains($0) || id.contains($0) }) {
            score += 90
        }

        // Samantha compact is the classic robotic default — only OK if enhanced/premium.
        if name.contains("samantha") || id.contains("samantha") {
            if voice.quality == .premium || voice.quality == .enhanced || id.contains("enhanced") || id.contains("premium") {
                score += 40
            } else {
                score -= 60
            }
        }

        // Avoid novelty / personal / low-clarity voices.
        if id.contains("novelty") || name.contains("novelty") {
            score -= 300
        }
        if id.contains("personal") {
            score -= 150
        }

        return score
    }

    // MARK: - Audio session

    private func configureSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Playback + spokenAudio routes voice clearly through the speaker
            // and duck other audio slightly for intelligibility.
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .mixWithOthers]
            )
            try session.setActive(true, options: [])
        } catch {
            // Fallback — speech may still work with the default session.
            try? session.setCategory(.ambient, mode: .spokenAudio, options: [.mixWithOthers])
            try? session.setActive(true, options: [])
        }
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {}
