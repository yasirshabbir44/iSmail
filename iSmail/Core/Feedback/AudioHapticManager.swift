//
//  AudioHapticManager.swift
//  iSmail
//
//  Lightweight multi-sensory feedback — synthesized tones + notification haptics.
//  Soft, ADHD-friendly; never harsh error blasts.
//

import AVFoundation

/// Singleton synthesizer for success / soft-incorrect / hint cues.
/// Pair with SwiftUI `.sensoryFeedback` on the calling view for haptics.
@MainActor
final class AudioHapticManager {
    static let shared = AudioHapticManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private let format: AVAudioFormat
    private var isArmed = false

    private init() {
        // These formats are always available on Apple platforms.
        format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44_100,
            channels: 1,
            interleaved: false
        ) ?? AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.9
    }

    // MARK: - Public cues

    /// Cheerful high-pitch chime. Pair with `.sensoryFeedback(.success)`.
    func playSuccess() {
        playChime(
            notes: [
                (frequency: 880, duration: 0.07, volume: 0.28),
                (frequency: 1174.7, duration: 0.10, volume: 0.32),
                (frequency: 1396.9, duration: 0.14, volume: 0.26)
            ]
        )
    }

    /// Soft low woodblock/thud. Pair with `.sensoryFeedback(.warning)`.
    func playIncorrect() {
        playChime(
            notes: [
                (frequency: 180, duration: 0.06, volume: 0.16),
                (frequency: 140, duration: 0.09, volume: 0.12)
            ],
            wave: .softThud
        )
    }

    /// Subtle sparkle when an adaptive hint unlocks.
    func playHint() {
        playChime(
            notes: [
                (frequency: 1568, duration: 0.05, volume: 0.14),
                (frequency: 2093, duration: 0.07, volume: 0.12),
                (frequency: 2637, duration: 0.09, volume: 0.10)
            ],
            wave: .sparkle
        )
    }

    /// Soft inhale/exhale tones for the frustration calm-down pause.
    func playBreathingChime() {
        playChime(
            notes: [
                (frequency: 261.6, duration: 0.28, volume: 0.12),
                (frequency: 329.6, duration: 0.36, volume: 0.14),
                (frequency: 392.0, duration: 0.42, volume: 0.11),
                (frequency: 329.6, duration: 0.32, volume: 0.10)
            ],
            wave: .breath
        )
    }

    /// Quick bubble-pop blip for the Bubble Pop mini-game.
    func playPop() {
        playChime(
            notes: [
                (frequency: 1320, duration: 0.035, volume: 0.22),
                (frequency: 1760, duration: 0.045, volume: 0.14)
            ],
            wave: .sparkle
        )
    }

    /// Distinct pad tone for Pattern Constructor tiles (0…8).
    func playTone(forTile index: Int) {
        let tones: [Double] = [
            261.63, 293.66, 329.63,
            349.23, 392.00, 440.00,
            493.88, 523.25, 587.33
        ]
        let clamped = max(0, min(index, tones.count - 1))
        let freq = tones[clamped]
        playChime(
            notes: [
                (frequency: freq, duration: 0.16, volume: 0.26),
                (frequency: freq * 2, duration: 0.08, volume: 0.10)
            ],
            wave: .sparkle
        )
    }

    // MARK: - Engine

    private func armEngineIfNeeded() -> Bool {
        if isArmed, engine.isRunning {
            return true
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            if !engine.isRunning {
                try engine.start()
            }
            isArmed = true
            return true
        } catch {
            isArmed = false
            return false
        }
    }

    private enum WaveShape {
        case sine
        case softThud
        case sparkle
        case breath
    }

    private func playChime(
        notes: [(frequency: Double, duration: Double, volume: Float)],
        wave: WaveShape = .sine
    ) {
        guard armEngineIfNeeded() else { return }

        var samples: [Float] = []
        samples.reserveCapacity(notes.reduce(0) { $0 + Int($1.duration * sampleRate) })

        for note in notes {
            let count = max(1, Int(note.duration * sampleRate))
            for i in 0..<count {
                let t = Double(i) / sampleRate
                let envelope = attackReleaseEnvelope(
                    index: i,
                    total: count,
                    attack: 0.008,
                    release: 0.04
                )
                let raw: Float
                switch wave {
                case .sine:
                    raw = Float(sin(2 * Double.pi * note.frequency * t))
                case .softThud:
                    let tone = sin(2 * Double.pi * note.frequency * t)
                    let noise = Double.random(in: -0.15...0.15)
                    raw = Float(tone * 0.85 + noise * 0.15)
                case .sparkle:
                    let fund = sin(2 * Double.pi * note.frequency * t)
                    let harm = 0.35 * sin(2 * Double.pi * note.frequency * 2 * t)
                    raw = Float(fund + harm)
                case .breath:
                    // Soft triangle-ish tone — rounded, never sharp.
                    let phase = 2 * Double.pi * note.frequency * t
                    let fund = sin(phase)
                    let soft = 0.18 * sin(2 * phase)
                    raw = Float(fund * 0.88 + soft)
                }
                samples.append(raw * note.volume * envelope)
            }
        }

        guard !samples.isEmpty,
              let buffer = makeBuffer(samples: samples)
        else { return }

        // Avoid stacking a huge queue if the child taps rapidly.
        if player.isPlaying {
            player.stop()
        }

        do {
            // Re-arm if the engine was interrupted (phone call, route change).
            if !engine.isRunning {
                try engine.start()
            }
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()
        } catch {
            isArmed = false
        }
    }

    private func attackReleaseEnvelope(
        index: Int,
        total: Int,
        attack: Double,
        release: Double
    ) -> Float {
        let attackSamples = max(1, Int(attack * sampleRate))
        let releaseSamples = max(1, Int(release * sampleRate))
        if index < attackSamples {
            return Float(index) / Float(attackSamples)
        }
        let releaseStart = max(0, total - releaseSamples)
        if index >= releaseStart {
            let remaining = max(0, total - index)
            return Float(remaining) / Float(releaseSamples)
        }
        return 1
    }

    private func makeBuffer(samples: [Float]) -> AVAudioPCMBuffer? {
        guard samples.count > 0,
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: format,
                  frameCapacity: AVAudioFrameCount(samples.count)
              )
        else { return nil }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        samples.withUnsafeBufferPointer { src in
            if let base = src.baseAddress {
                channel.update(from: base, count: samples.count)
            }
        }
        return buffer
    }
}
