//
//  CalmCornerView.swift
//  iSmail
//
//  Breathing / reset space — ADHD cool-down without leaving the play world.
//

import SwiftUI

struct CalmCornerView: View {
    var onReturnToMap: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var breathScale: CGFloat = 0.72
    @State private var isInhaling = true
    @State private var cycleCount = 0
    @State private var isRunning = false
    @State private var glow = false
    @State private var generation = 0

    private let inhaleSeconds: Double = 4
    private let exhaleSeconds: Double = 4
    private let targetCycles = 3

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 700

            ZStack {
                PlayWorldBackground()

                VStack(spacing: compact ? 16 : 22) {
                    topChrome

                    Spacer(minLength: 8)

                    Text(isRunning ? (isInhaling ? "Breathe in…" : "Breathe out…") : "Ready when you are")
                        .font(.system(.title, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                        .animation(LearningTheme.forgivingSpring, value: isInhaling)
                        .animation(LearningTheme.forgivingSpring, value: isRunning)

                    Text(isRunning ? "Cycle \(min(cycleCount + 1, targetCycles)) of \(targetCycles)" : "Three gentle breaths together")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(LearningTheme.mutedInk)

                    ZStack {
                        Circle()
                            .fill(LearningTheme.accent.opacity(glow ? 0.22 : 0.10))
                            .frame(width: 260, height: 260)
                            .scaleEffect(breathScale * 1.15)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        LearningTheme.skyTop,
                                        LearningTheme.accent.opacity(0.75)
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 180, height: 180)
                            .scaleEffect(breathScale)
                            .overlay {
                                BuddyCoachView(mood: isRunning ? .idle : .cheering, size: 72)
                                    .scaleEffect(0.9)
                            }
                            .shadow(color: LearningTheme.accent.opacity(0.28), radius: 18, y: 8)
                    }
                    .frame(height: compact ? 240 : 280)

                    Spacer(minLength: 8)

                    if cycleCount >= targetCycles {
                        doneCard
                    } else {
                        startButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .frame(maxWidth: LearningTheme.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            generation += 1
            isRunning = false
            SpeechManager.shared.stop()
        }
    }

    // MARK: - Chrome

    private var topChrome: some View {
        HStack {
            ScreenBackButton(accessibilityLabel: "Back to map") {
                returnHome()
            }

            Text("Calm Corner")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)

            Spacer()

            Image(systemName: "wind")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(LearningTheme.accent)
                .frame(width: 44, height: 44)
                .background {
                    Circle().fill(LearningTheme.accentSoft)
                }
        }
    }

    private var startButton: some View {
        Button {
            startBreathing()
        } label: {
            Text(isRunning ? "Breathing…" : "Start breathing")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: LearningTheme.minTouchTarget)
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(isRunning ? LearningTheme.mutedInk.opacity(0.45) : LearningTheme.accent)
                }
        }
        .buttonStyle(KidBounceButtonStyle())
        .disabled(isRunning)
        .accessibilityLabel(isRunning ? "Breathing in progress" : "Start breathing")
    }

    private var doneCard: some View {
        VStack(spacing: 14) {
            Text("You did it — so calm!")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)

            Text("Ready to play again whenever you like.")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .multilineTextAlignment(.center)

            Button {
                returnHome()
            } label: {
                Text("Back to map")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: LearningTheme.minTouchTarget)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LearningTheme.success)
                    }
            }
            .buttonStyle(KidBounceButtonStyle())

            Button {
                cycleCount = 0
                startBreathing()
            } label: {
                Text("One more round")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(KidBounceButtonStyle())
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.95))
                .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
        }
    }

    // MARK: - Breathing loop

    private func startBreathing() {
        guard !isRunning else { return }
        generation += 1
        let token = generation
        isRunning = true
        cycleCount = 0
        SpeechManager.shared.speak(text: "Breathe in slowly.")
        runCycle(token: token)
    }

    private func runCycle(token: Int) {
        guard token == generation, isRunning else { return }
        guard cycleCount < targetCycles else {
            isRunning = false
            AudioHapticManager.shared.playSuccess()
            SpeechManager.shared.speak(text: "Beautiful breathing. You did it!")
            return
        }

        // Inhale
        isInhaling = true
        glow = true
        AudioHapticManager.shared.playBreathingChime()
        withAnimation(.easeInOut(duration: inhaleSeconds)) {
            breathScale = 1.08
        }

        SafeAsync.after(inhaleSeconds) {
            guard token == generation, isRunning else { return }
            isInhaling = false
            glow = false
            if cycleCount == 0 {
                SpeechManager.shared.speak(text: "Now breathe out.")
            }
            withAnimation(.easeInOut(duration: exhaleSeconds)) {
                breathScale = 0.72
            }

            SafeAsync.after(exhaleSeconds) {
                guard token == generation, isRunning else { return }
                cycleCount += 1
                runCycle(token: token)
            }
        }
    }

    private func returnHome() {
        generation += 1
        isRunning = false
        SpeechManager.shared.stop()
        if let onReturnToMap {
            onReturnToMap()
        } else {
            dismiss()
        }
    }
}

#Preview {
    CalmCornerView()
}
