//
//  RhythmTapView.swift
//  iSmail
//
//  Music / rhythm mini-game — tap glowing pads in time for focus + auditory fun.
//

import SwiftUI
internal import Combine

struct RhythmTapView: View {
    var onRoundFinished: ((Int) -> Void)?
    var onReturnToMap: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var activePad: Int?
    @State private var score = 0
    @State private var combo = 0
    @State private var secondsRemaining: Double = 35
    @State private var isRunning = false
    @State private var isFinished = false
    @State private var beatAccumulator: Double = 0
    @State private var lastTick: Date?
    @State private var padFlash: Int?
    @State private var missFlash = false
    @State private var successTrigger = 0
    @State private var didAward = false
    @State private var expectedPad = 0

    private let roundDuration: Double = 35
    private let beatInterval: Double = 0.85
    private let padCount = 4
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private let padColors: [Color] = [
        LearningTheme.coral,
        LearningTheme.sunshine,
        LearningTheme.accent,
        Color(red: 0.42, green: 0.58, blue: 0.95)
    ]

    private var progress: Double {
        max(0, min(1, secondsRemaining / roundDuration))
    }

    private var coinsEarned: Int {
        max(1, score / 2 + combo / 4)
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 700

            ZStack {
                PlayWorldBackground()

                VStack(spacing: 14) {
                    topChrome
                    timerBar
                    scoreRow

                    Spacer(minLength: 8)

                    padGrid(compact: compact)

                    Spacer(minLength: 8)

                    Text(isRunning ? "Tap the glowing pad!" : "Get ready…")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.mutedInk)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .frame(maxWidth: LearningTheme.contentMaxWidth)
                .frame(maxWidth: .infinity)

                if isFinished {
                    completionOverlay
                        .transition(.scale(scale: 0.88).combined(with: .opacity))
                }
            }
            .onAppear { startRound() }
            .onReceive(timer) { date in
                tick(at: date)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: successTrigger)
        .statusBarHidden(isRunning && !isFinished)
    }

    // MARK: - Chrome

    private var topChrome: some View {
        HStack(spacing: 12) {
            ScreenBackButton(accessibilityLabel: "Back to map") {
                returnToMap()
            }

            Text("Rhythm Tap")
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
        }
    }

    private var timerBar: some View {
        GeometryReader { barGeo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(LearningTheme.slot)
                Capsule(style: .continuous)
                    .fill(LearningTheme.coral.gradient)
                    .frame(width: max(8, barGeo.size.width * progress))
            }
        }
        .frame(height: 12)
        .accessibilityLabel("Time remaining \(Int(secondsRemaining)) seconds")
    }

    private var scoreRow: some View {
        HStack {
            Label("\(score) hits", systemImage: "hand.tap.fill")
            Spacer()
            Label("Combo \(combo)", systemImage: "flame.fill")
                .foregroundStyle(combo > 2 ? LearningTheme.coral : LearningTheme.mutedInk)
        }
        .font(.system(.subheadline, design: .rounded).weight(.heavy))
        .foregroundStyle(LearningTheme.ink)
    }

    // MARK: - Pads

    private func padGrid(compact: Bool) -> some View {
        let side = compact ? 120.0 : 140.0
        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 16
        ) {
            ForEach(0..<padCount, id: \.self) { index in
                padButton(index: index, side: side)
            }
        }
        .padding(.horizontal, 8)
    }

    private func padButton(index: Int, side: CGFloat) -> some View {
        let isActive = activePad == index
        let tint = padColors[index % padColors.count]

        return Button {
            tapPad(index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(isActive ? tint : tint.opacity(0.22))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(tint.opacity(isActive ? 1 : 0.45), lineWidth: isActive ? 4 : 2)
                    }
                    .shadow(color: isActive ? tint.opacity(0.45) : .clear, radius: 14, y: 6)

                Image(systemName: ["music.note", "star.fill", "heart.fill", "sparkles"][index % 4])
                    .font(.system(size: side * 0.28, weight: .bold))
                    .foregroundStyle(isActive ? .white : tint)
                    .scaleEffect(padFlash == index ? 1.18 : 1.0)
            }
            .frame(height: side)
            .scaleEffect(isActive ? 1.04 : 1.0)
            .animation(LearningTheme.forgivingSpring, value: activePad)
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel("Pad \(index + 1)")
    }

    // MARK: - Game loop

    private func startRound() {
        score = 0
        combo = 0
        secondsRemaining = roundDuration
        isRunning = true
        isFinished = false
        didAward = false
        beatAccumulator = 0
        lastTick = nil
        cueNextBeat()
    }

    private func tick(at date: Date) {
        guard isRunning, !isFinished else { return }
        let previous = lastTick ?? date
        let dt = date.timeIntervalSince(previous)
        lastTick = date
        guard dt > 0, dt < 0.25 else { return }

        secondsRemaining = max(0, secondsRemaining - dt)
        if secondsRemaining <= 0 {
            finishRound()
            return
        }

        beatAccumulator += dt
        if beatAccumulator >= beatInterval {
            beatAccumulator = 0
            cueNextBeat()
        }
    }

    private func cueNextBeat() {
        var next = Int.random(in: 0..<padCount)
        if next == expectedPad { next = (next + 1) % padCount }
        expectedPad = next
        activePad = next
        AudioHapticManager.shared.playTone(forTile: next)
    }

    private func tapPad(_ index: Int) {
        guard isRunning, !isFinished else { return }

        if index == activePad {
            score += 1
            combo += 1
            successTrigger += 1
            padFlash = index
            AudioHapticManager.shared.playSuccess()
            withAnimation(LearningTheme.successBump) {
                activePad = nil
            }
            SafeAsync.after(0.18) {
                if padFlash == index { padFlash = nil }
            }
        } else {
            combo = 0
            missFlash = true
            AudioHapticManager.shared.playIncorrect()
            SafeAsync.after(0.25) { missFlash = false }
        }
    }

    private func finishRound() {
        guard !isFinished else { return }
        isFinished = true
        isRunning = false
        activePad = nil
        if !didAward {
            didAward = true
            onRoundFinished?(coinsEarned)
        }
        AudioHapticManager.shared.playSuccess()
    }

    private func returnToMap() {
        isRunning = false
        if let onReturnToMap {
            onReturnToMap()
        } else {
            dismiss()
        }
    }

    // MARK: - Completion

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()

            VStack(spacing: 14) {
                BuddyCoachView(mood: .celebrating, size: 88)

                Text("Beat master!")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)

                Text("+\(coinsEarned) coins · \(score) taps")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(LearningTheme.mutedInk)

                Button {
                    returnToMap()
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
                    startRound()
                } label: {
                    Text("Play again")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.accent)
                }
                .buttonStyle(KidBounceButtonStyle())
            }
            .padding(22)
            .frame(maxWidth: 360)
            .background {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(LearningTheme.surface)
                    .shadow(color: .black.opacity(0.14), radius: 22, y: 10)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    RhythmTapView()
}
