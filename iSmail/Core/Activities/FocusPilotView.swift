//
//  FocusPilotView.swift
//  iSmail
//
//  Impulse-control mini-game — hold to climb, release to glide, collect stars, dodge soft clouds.
//

import SwiftUI
internal import Combine

struct FocusPilotView: View {
    /// Called once when the round ends with coins earned.
    var onRoundFinished: ((Int) -> Void)?
    var onReturnToMap: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var avatarY: CGFloat = 0
    @State private var isHolding = false
    @State private var stars: [PilotEntity] = []
    @State private var clouds: [PilotEntity] = []
    @State private var score = 0
    @State private var avoidedCount = 0
    @State private var secondsRemaining: Double = 45
    @State private var isRunning = false
    @State private var isFinished = false
    @State private var lastTick: Date?
    @State private var canvasSize: CGSize = .zero
    @State private var nextEntityID = 0
    @State private var spawnAccumulator: Double = 0
    @State private var successTrigger = 0
    @State private var warningTrigger = 0
    @State private var showBurst = false
    @State private var burstOrigin: CGPoint = .zero
    @State private var avatarNudge: CGFloat = 0
    @State private var bobPhase: Double = 0

    private let roundDuration: Double = 45
    private let scrollSpeed: CGFloat = 145
    private let climbSpeed: CGFloat = 220
    private let fallSpeed: CGFloat = 190
    private let avatarRadius: CGFloat = 22
    private let spawnInterval: Double = 0.95
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private var progress: Double {
        max(0, min(1, secondsRemaining / roundDuration))
    }

    private var coinsEarned: Int {
        score + avoidedCount / 2
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                skyBackdrop

                VStack(spacing: 12) {
                    topChrome
                    playfield
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .frame(maxWidth: LearningTheme.contentMaxWidth)
                .frame(maxWidth: .infinity)

                if isFinished {
                    completionOverlay
                        .transition(.scale(scale: 0.88).combined(with: .opacity))
                }
            }
            .onAppear {
                canvasSize = geo.size
                startRound()
            }
            .onChange(of: geo.size) { _, newSize in
                canvasSize = newSize
            }
            .onReceive(timer) { date in
                tick(at: date)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.warning, trigger: warningTrigger)
        .statusBarHidden(isRunning && !isFinished)
    }

    // MARK: - Backdrop

    private var skyBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.78, blue: 0.95),
                    Color(red: 0.72, green: 0.90, blue: 0.98),
                    Color(red: 0.96, green: 0.93, blue: 0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Soft distant hills
            Ellipse()
                .fill(LearningTheme.success.opacity(0.22))
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .offset(y: 280)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Chrome

    private var topChrome: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ScreenBackButton(accessibilityLabel: "Back to map") {
                    returnToMap()
                }

                Text("Focus Pilot")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(LearningTheme.sunshine)
                    Text("\(score)")
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
                .accessibilityLabel("Stars collected \(score)")
            }

            GeometryReader { barGeo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(LearningTheme.slot)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [LearningTheme.accent, LearningTheme.coral],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, barGeo.size.width * progress))
                        .animation(.linear(duration: 0.1), value: progress)
                }
            }
            .frame(height: 14)
            .accessibilityLabel("Time remaining \(Int(secondsRemaining.rounded())) seconds")

            Text(isFinished ? "Time's up!" : "Hold to fly up · Release to glide down · \(Int(ceil(secondsRemaining)))s")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.mutedInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
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

    // MARK: - Playfield

    private var playfield: some View {
        GeometryReader { field in
            let midY = field.size.height * 0.5
            let avatarX = field.size.width * 0.22

            ZStack {
                // Soft lane markers
                ForEach(0..<3, id: \.self) { lane in
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: field.size.width * 0.9, height: 3)
                        .position(
                            x: field.size.width * 0.5,
                            y: field.size.height * (0.28 + CGFloat(lane) * 0.22)
                        )
                }

                ForEach(clouds) { cloud in
                    SoftCloudView(size: cloud.size)
                        .position(cloud.position)
                        .allowsHitTesting(false)
                }

                ForEach(stars) { star in
                    Image(systemName: "star.fill")
                        .font(.system(size: star.size * 0.72, weight: .bold))
                        .foregroundStyle(LearningTheme.sunshine)
                        .shadow(color: LearningTheme.sunshine.opacity(0.45), radius: 6, y: 2)
                        .position(star.position)
                        .allowsHitTesting(false)
                }

                PilotAvatarView(isClimbing: isHolding)
                    .offset(x: avatarNudge)
                    .position(x: avatarX, y: avatarY == 0 ? midY : avatarY)
                    .allowsHitTesting(false)

                RewardBurstView(coinCount: 5, symbolName: "star.fill", isActive: $showBurst)
                    .position(burstOrigin == .zero
                              ? CGPoint(x: avatarX, y: avatarY == 0 ? midY : avatarY)
                              : burstOrigin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard isRunning, !isFinished else { return }
                        isHolding = true
                    }
                    .onEnded { _ in
                        isHolding = false
                    }
            )
            .onAppear {
                canvasSize = field.size
                if avatarY == 0 {
                    avatarY = field.size.height * 0.5
                }
            }
            .onChange(of: field.size) { _, size in
                canvasSize = size
                avatarY = min(max(avatarY, avatarRadius + 8), size.height - avatarRadius - 8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 2)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus pilot playfield")
        .accessibilityHint("Touch and hold to fly up, release to glide down")
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

                Text("Smooth Flying!")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .accessibilityAddTraits(.isHeader)

                Text("\(score) stars · \(avoidedCount) clouds cleared")
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

    // MARK: - Game loop

    private func startRound() {
        score = 0
        avoidedCount = 0
        secondsRemaining = roundDuration
        stars = []
        clouds = []
        spawnAccumulator = 0
        lastTick = nil
        isFinished = false
        isRunning = true
        isHolding = false
        avatarY = max(canvasSize.height, 300) * 0.5
        // Seed a gentle first wave.
        spawnEntity(kind: .star)
        spawnEntity(kind: .cloud)
    }

    private func tick(at date: Date) {
        guard isRunning, !isFinished else { return }
        let height = max(canvasSize.height, 200)
        let width = max(canvasSize.width, 200)
        let previous = lastTick ?? date
        let delta = min(0.05, date.timeIntervalSince(previous))
        lastTick = date
        guard delta > 0 else { return }

        secondsRemaining = max(0, secondsRemaining - delta)
        if secondsRemaining <= 0 {
            finishRound()
            return
        }

        bobPhase += delta * 3.2
        let verticalDelta = (isHolding ? -climbSpeed : fallSpeed) * delta
        avatarY = min(max(avatarY + verticalDelta, avatarRadius + 8), height - avatarRadius - 8)

        spawnAccumulator += delta
        while spawnAccumulator >= spawnInterval {
            spawnAccumulator -= spawnInterval
            spawnEntity(kind: Bool.random() ? .star : .cloud)
        }

        let avatarX = width * 0.22
        let avatarPoint = CGPoint(x: avatarX, y: avatarY)

        stars = stars.compactMap { entity in
            var next = entity
            next.position.x -= scrollSpeed * delta
            next.position.y += sin(bobPhase + next.wobble) * 12 * delta

            if distance(avatarPoint, next.position) < avatarRadius + next.size * 0.35 {
                collectStar(at: next.position)
                return nil
            }
            return next.position.x < -40 ? nil : next
        }

        clouds = clouds.compactMap { entity in
            var next = entity
            next.position.x -= scrollSpeed * delta * next.speedScale

            if distance(avatarPoint, next.position) < avatarRadius + next.size * 0.38 {
                bumpCloud(at: next.position)
                return nil
            }

            if next.position.x + next.size * 0.5 < avatarX - avatarRadius {
                // Successful avoidance once the cloud clears the avatar.
                if !next.wasCleared {
                    next.wasCleared = true
                    registerAvoidance(at: CGPoint(x: avatarX + 24, y: next.position.y))
                }
            }
            return next.position.x < -60 ? nil : next
        }
    }

    private func spawnEntity(kind: PilotEntity.Kind) {
        let width = max(canvasSize.width, 200)
        let height = max(canvasSize.height, 300)
        let size: CGFloat = kind == .star
            ? CGFloat.random(in: 28...38)
            : CGFloat.random(in: 48...72)
        let y = CGFloat.random(in: (size + 16)...(height - size - 16))
        let entity = PilotEntity(
            id: nextEntityID,
            kind: kind,
            position: CGPoint(x: width + size + CGFloat.random(in: 0...80), y: y),
            size: size,
            speedScale: CGFloat.random(in: 0.85...1.15),
            wobble: Double.random(in: 0...(Double.pi * 2)),
            wasCleared: false
        )
        nextEntityID += 1
        if kind == .star {
            stars.append(entity)
        } else {
            clouds.append(entity)
        }
    }

    private func collectStar(at point: CGPoint) {
        score += 1
        successTrigger += 1
        AudioHapticManager.shared.playPop()
        fireBurst(at: point)
    }

    private func registerAvoidance(at point: CGPoint) {
        avoidedCount += 1
        successTrigger += 1
        AudioHapticManager.shared.playHint()
        fireBurst(at: point)
    }

    private func bumpCloud(at point: CGPoint) {
        warningTrigger += 1
        AudioHapticManager.shared.playIncorrect()
        withAnimation(.default) { avatarNudge = 10 }
        SafeAsync.after(0.08) {
            withAnimation(.default) { avatarNudge = -8 }
        }
        SafeAsync.after(0.16) {
            withAnimation(LearningTheme.forgivingSpring) { avatarNudge = 0 }
        }
        // Soft miss — no score loss; cloud dissolves.
        _ = point
    }

    private func fireBurst(at point: CGPoint) {
        burstOrigin = point
        showBurst = false
        SafeAsync.after(0.02) {
            showBurst = true
        }
    }

    private func finishRound() {
        guard !isFinished else { return }
        isRunning = false
        isFinished = true
        isHolding = false
        stars = []
        clouds = []
        AudioHapticManager.shared.playSuccess()
        onRoundFinished?(coinsEarned)
    }

    private func returnToMap() {
        if let onReturnToMap {
            onReturnToMap()
        } else {
            dismiss()
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}

// MARK: - Avatar

private struct PilotAvatarView: View {
    let isClimbing: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            LearningTheme.coral,
                            LearningTheme.coral.opacity(0.85)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 2,
                        endRadius: 26
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.7), lineWidth: 2)
                }
                .shadow(color: LearningTheme.coral.opacity(0.4), radius: 10, y: 4)

            Image(systemName: isClimbing ? "paperplane.fill" : "paperplane")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(isClimbing ? -28 : 18))
                .offset(x: 1, y: isClimbing ? -1 : 2)
        }
        .scaleEffect(isClimbing ? 1.06 : 1.0)
        .animation(LearningTheme.focusFlash, value: isClimbing)
        .accessibilityHidden(true)
    }
}

// MARK: - Soft cloud

private struct SoftCloudView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.92))
                .frame(width: size * 1.15, height: size * 0.55)
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(x: -size * 0.22, y: -size * 0.12)
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: size * 0.48, height: size * 0.48)
                .offset(x: size * 0.2, y: -size * 0.08)
        }
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        .accessibilityHidden(true)
    }
}

// MARK: - Models

private struct PilotEntity: Identifiable {
    enum Kind {
        case star
        case cloud
    }

    let id: Int
    let kind: Kind
    var position: CGPoint
    var size: CGFloat
    var speedScale: CGFloat
    var wobble: Double
    var wasCleared: Bool
}

#Preview {
    FocusPilotView()
}
