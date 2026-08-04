//
//  PatternConstructorView.swift
//  iSmail
//
//  Working-memory mini-game — Simon-says tile sequences with ADHD-friendly recovery.
//

import SwiftUI

struct PatternConstructorView: View {
    /// Called once when the session ends with coins earned.
    var onRoundFinished: ((Int) -> Void)?
    var onReturnToMap: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var sequence: [Int] = []
    @State private var playerStep = 0
    @State private var phase: Phase = .ready
    @State private var litTile: Int?
    @State private var hintTile: Int?
    @State private var shakeOffset: CGFloat = 0
    @State private var successTrigger = 0
    @State private var warningTrigger = 0
    @State private var roundsCleared = 0
    @State private var isFinished = false
    @State private var generation = 0
    @State private var showBurst = false

    private let targetRounds = 5
    private let startingLength = 2
    private let gridSpacing: CGFloat = 14
    private let tileColors: [Color] = [
        Color(red: 0.98, green: 0.45, blue: 0.38),
        Color(red: 1.0, green: 0.78, blue: 0.22),
        Color(red: 0.22, green: 0.70, blue: 0.48),
        Color(red: 0.08, green: 0.62, blue: 0.68),
        Color(red: 0.42, green: 0.58, blue: 0.95),
        Color(red: 0.90, green: 0.45, blue: 0.72),
        Color(red: 0.95, green: 0.55, blue: 0.25),
        Color(red: 0.55, green: 0.40, blue: 0.90),
        Color(red: 0.35, green: 0.78, blue: 0.85)
    ]

    private enum Phase {
        case ready
        case watching
        case repeating
        case celebrating
    }

    private var coinsEarned: Int {
        roundsCleared * 2
    }

    private var canAcceptInput: Bool {
        phase == .repeating && !isFinished
    }

    var body: some View {
        ZStack {
            PlayWorldBackground()

            VStack(spacing: 16) {
                topChrome
                promptBanner
                patternGrid
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                progressPips
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .frame(maxWidth: LearningTheme.contentMaxWidth)
            .frame(maxWidth: .infinity)

            RewardBurstView(coinCount: 6, symbolName: "star.fill", isActive: $showBurst)

            if isFinished {
                completionOverlay
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.warning, trigger: warningTrigger)
        .onAppear { beginSession() }
        .onDisappear { generation += 1 }
    }

    // MARK: - Chrome

    private var topChrome: some View {
        HStack(spacing: 12) {
                ScreenBackButton(accessibilityLabel: "Back to map") {
                    returnToMap()
                }

                Text("Pattern Builder")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                Text("🪙")
                Text("+\(coinsEarned)")
                    .contentTransition(.numericText())
                    .monospacedDigit()
            }
            .font(.system(.title3, design: .rounded).weight(.heavy))
            .foregroundStyle(LearningTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous)
                    .fill(LearningTheme.sunshineSoft)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(LearningTheme.sunshine.opacity(0.5), lineWidth: 2)
                    }
            }
            .accessibilityLabel("Coins earned \(coinsEarned)")
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.75), lineWidth: 2)
                }
                .shadow(color: LearningTheme.accent.opacity(0.10), radius: 10, y: 4)
        }
    }

    private var promptBanner: some View {
        Text(promptText)
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundStyle(LearningTheme.mutedInk)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LearningTheme.surface.opacity(0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(LearningTheme.accent.opacity(0.35), lineWidth: 2)
                    }
            }
            .animation(LearningTheme.forgivingSpring, value: phase)
            .accessibilityAddTraits(.isHeader)
    }

    private var promptText: String {
        switch phase {
        case .ready:
            return "Watch the pattern…"
        case .watching:
            return "Watch carefully!"
        case .repeating:
            return hintTile == nil
                ? "Your turn — tap the pattern!"
                : "Almost! Try the glowing tile."
        case .celebrating:
            return "Nice memory!"
        }
    }

    private var progressPips: some View {
        VStack(spacing: 6) {
            LessonProgressPips(
                total: targetRounds,
                completed: roundsCleared,
                tint: LearningTheme.accent
            )
            Text("Round \(min(roundsCleared + 1, targetRounds)) of \(targetRounds)")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.mutedInk)
        }
    }

    // MARK: - Grid

    private var patternGrid: some View {
        GeometryReader { geo in
            let side = tileSide(for: geo.size)
            let totalWidth = side * 3 + gridSpacing * 2
            let totalHeight = side * 3 + gridSpacing * 2

            VStack(spacing: gridSpacing) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: gridSpacing) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col
                            PatternTileView(
                                color: tileColors[index],
                                side: side,
                                isLit: litTile == index,
                                showHint: hintTile == index,
                                isEnabled: canAcceptInput
                            ) {
                                handleTap(index)
                            }
                        }
                    }
                }
            }
            .frame(width: totalWidth, height: totalHeight)
            .offset(x: shakeOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(canAcceptInput)
    }

    private func tileSide(for size: CGSize) -> CGFloat {
        let available = min(size.width, size.height) - gridSpacing * 2
        let fitted = available / 3
        return max(80, min(110, fitted))
    }

    // MARK: - Completion

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Spacer(minLength: 0)
                    ScreenCloseButton(accessibilityLabel: "Close and return to map") {
                        returnToMap()
                    }
                }

                Text("Great Memory!")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .accessibilityAddTraits(.isHeader)

                Text("You cleared \(roundsCleared) patterns")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)

                HStack(spacing: 8) {
                    Text("🪙")
                        .font(.system(size: 36))
                    Text("+\(coinsEarned)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(LearningTheme.ink)
                        .contentTransition(.numericText())
                }
                .padding(.vertical, 8)

                Button {
                    returnToMap()
                } label: {
                    Text("Return to Map")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            LearningTheme.accent,
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                        )
                        .shadow(color: LearningTheme.accent.opacity(0.35), radius: 12, y: 6)
                }
                .buttonStyle(KidBounceButtonStyle())
                .accessibilityLabel("Return to map")
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(LearningTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(LearningTheme.sunshine.opacity(0.55), lineWidth: 3)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
            }
        }
        .animation(LearningTheme.forgivingSpring, value: isFinished)
    }

    // MARK: - Game flow

    private func beginSession() {
        roundsCleared = 0
        isFinished = false
        sequence = []
        growSequence(to: startingLength)
        playDemo()
    }

    private func growSequence(to length: Int) {
        while sequence.count < length {
            sequence.append(Int.random(in: 0..<9))
        }
    }

    private func playDemo() {
        let token = generation
        phase = .watching
        playerStep = 0
        hintTile = nil
        litTile = nil

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard token == generation, !isFinished else { return }

            for tile in sequence {
                guard token == generation, !isFinished else { return }
                litTile = tile
                AudioHapticManager.shared.playTone(forTile: tile)
                try? await Task.sleep(nanoseconds: 420_000_000)
                litTile = nil
                try? await Task.sleep(nanoseconds: 180_000_000)
            }

            guard token == generation, !isFinished else { return }
            phase = .repeating
        }
    }

    private func handleTap(_ index: Int) {
        guard canAcceptInput, playerStep < sequence.count else { return }

        litTile = index
        AudioHapticManager.shared.playTone(forTile: index)

        let expected = sequence[playerStep]
        if index == expected {
            hintTile = nil
            playerStep += 1
            SafeAsync.after(0.18) {
                if litTile == index { litTile = nil }
            }

            if playerStep >= sequence.count {
                clearRound()
            }
        } else {
            handleMiss(expected: expected)
        }
    }

    private func handleMiss(expected: Int) {
        warningTrigger += 1
        AudioHapticManager.shared.playIncorrect()
        playerStep = 0
        hintTile = expected

        withAnimation(.default) {
            shakeOffset = 12
        }
        SafeAsync.after(0.08) {
            withAnimation(.default) { shakeOffset = -10 }
        }
        SafeAsync.after(0.16) {
            withAnimation(.default) { shakeOffset = 7 }
        }
        SafeAsync.after(0.24) {
            withAnimation(LearningTheme.forgivingSpring) { shakeOffset = 0 }
        }
        SafeAsync.after(0.22) {
            litTile = nil
        }
    }

    private func clearRound() {
        let token = generation
        phase = .celebrating
        hintTile = nil
        litTile = nil
        successTrigger += 1
        showBurst = true
        AudioHapticManager.shared.playSuccess()

        withAnimation(LearningTheme.forgivingSpring) {
            roundsCleared += 1
        }

        if roundsCleared >= targetRounds {
            SafeAsync.after(0.7) {
                guard token == generation else { return }
                finishSession()
            }
            return
        }

        SafeAsync.after(0.85) {
            guard token == generation, !isFinished else { return }
            growSequence(to: sequence.count + 1)
            playDemo()
        }
    }

    private func finishSession() {
        guard !isFinished else { return }
        isFinished = true
        phase = .ready
        onRoundFinished?(coinsEarned)
    }

    private func returnToMap() {
        if let onReturnToMap {
            onReturnToMap()
        } else {
            dismiss()
        }
    }
}

// MARK: - Tile

struct PatternTileView: View {
    let color: Color
    let side: CGFloat
    let isLit: Bool
    let showHint: Bool
    let isEnabled: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(isLit ? 1.0 : 0.88),
                            color.opacity(isLit ? 0.85 : 0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(isLit ? 0.95 : 0.55), lineWidth: isLit ? 4 : 2)
                }
                .overlay(alignment: .topLeading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.45))
                        .frame(width: side * 0.28, height: side * 0.12)
                        .offset(x: side * 0.14, y: side * 0.14)
                }
                .shadow(color: color.opacity(isLit ? 0.55 : 0.28), radius: isLit ? 16 : 8, y: isLit ? 4 : 6)
                .scaleEffect(isLit ? 1.06 : 1.0)
                .frame(width: side, height: side)
                .frame(minWidth: 80, minHeight: 80)
                .hintAura(isActive: showHint)
                .hintScalePulse(isActive: showHint)
        }
        .buttonStyle(KidBounceButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel("Pattern tile")
        .accessibilityHint(isEnabled ? "Double tap to play this tile" : "Watch the pattern")
        .animation(LearningTheme.focusFlash, value: isLit)
    }
}

#Preview {
    PatternConstructorView()
}
