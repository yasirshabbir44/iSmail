//
//  BubblePopView.swift
//  iSmail
//
//  30-second sensory bonus mini-game — pop floating bubbles for coins.
//

import SwiftUI
internal import Combine

struct BubblePopView: View {
    /// Called once when the round ends with total coins earned this session.
    var onRoundFinished: ((Int) -> Void)?
    var onReturnToMap: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var bubbles: [BubbleModel] = []
    @State private var particles: [PopParticle] = []
    @State private var score = 0
    @State private var secondsRemaining: Double = 30
    @State private var isRunning = false
    @State private var isFinished = false
    @State private var impactTrigger = 0
    @State private var spawnAccumulator: Double = 0
    @State private var lastTick: Date?
    @State private var canvasSize: CGSize = .zero
    @State private var nextSpawnID = 0

    private let roundDuration: Double = 30
    private let maxBubbles = 10
    private let spawnInterval: Double = 0.55
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private var progress: Double {
        max(0, min(1, secondsRemaining / roundDuration))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PlayWorldBackground()

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
        .sensoryFeedback(.impact(weight: .light), trigger: impactTrigger)
        .statusBarHidden(isRunning && !isFinished)
    }

    // MARK: - Chrome

    private var topChrome: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Bubble Pop!")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)

                Spacer()

                HStack(spacing: 6) {
                    Text("🪙")
                    Text("+\(score)")
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
                .accessibilityLabel("Coins earned \(score)")
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

            Text(isFinished ? "Time's up!" : "\(Int(ceil(secondsRemaining)))s")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.mutedInk)
                .frame(maxWidth: .infinity, alignment: .trailing)
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
            ZStack {
                ForEach(bubbles) { bubble in
                    BubbleView(bubble: bubble) {
                        pop(bubble)
                    }
                    .position(bubble.position)
                }

                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                canvasSize = field.size
            }
            .onChange(of: field.size) { _, size in
                canvasSize = size
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 2)
                }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bubble playfield")
    }

    // MARK: - Completion

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Great Job!")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .accessibilityAddTraits(.isHeader)

                Text("You popped \(score) bubbles")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)

                HStack(spacing: 8) {
                    Text("🪙")
                        .font(.system(size: 36))
                    Text("+\(score)")
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
        secondsRemaining = roundDuration
        bubbles = []
        particles = []
        spawnAccumulator = 0
        lastTick = nil
        isFinished = false
        isRunning = true
        // Seed a few bubbles so the field isn't empty.
        for _ in 0..<3 {
            spawnBubble()
        }
    }

    private func tick(at date: Date) {
        guard isRunning, !isFinished else { return }

        let previous = lastTick ?? date
        let delta = min(0.05, date.timeIntervalSince(previous))
        lastTick = date
        guard delta > 0 else { return }

        secondsRemaining = max(0, secondsRemaining - delta)
        if secondsRemaining <= 0 {
            finishRound()
            return
        }

        spawnAccumulator += delta
        while spawnAccumulator >= spawnInterval, bubbles.count < maxBubbles {
            spawnAccumulator -= spawnInterval
            spawnBubble()
        }

        bubbles = bubbles.compactMap { bubble in
            var next = bubble
            next.position.y -= next.speed * delta
            next.position.x += sin(next.wobblePhase + date.timeIntervalSinceReferenceDate * next.wobbleSpeed)
                * next.wobbleAmplitude * delta
            next.wobblePhase += delta * 2.2
            // Recycle off the top.
            if next.position.y < -next.radius {
                return nil
            }
            // Soft clamp so bubbles don't drift off-screen sideways.
            next.position.x = min(max(next.position.x, next.radius), max(canvasSize.width - next.radius, next.radius))
            return next
        }

        particles = particles.compactMap { particle in
            var next = particle
            next.position.x += next.velocity.dx * delta
            next.position.y += next.velocity.dy * delta
            next.velocity.dy += 220 * delta
            next.opacity -= delta * 2.4
            next.size = max(2, next.size - delta * 10)
            return next.opacity > 0.05 ? next : nil
        }
    }

    private func spawnBubble() {
        let width = max(canvasSize.width, 200)
        let height = max(canvasSize.height, 300)
        let radius = CGFloat.random(in: 28...48)
        let x = CGFloat.random(in: radius...(width - radius))
        let model = BubbleModel(
            id: nextSpawnID,
            position: CGPoint(x: x, y: height + radius + CGFloat.random(in: 0...40)),
            radius: radius,
            color: BubblePalette.random(),
            speed: CGFloat.random(in: 55...110),
            wobbleAmplitude: CGFloat.random(in: 18...42),
            wobbleSpeed: Double.random(in: 1.2...2.4),
            wobblePhase: Double.random(in: 0...(Double.pi * 2))
        )
        nextSpawnID += 1
        bubbles.append(model)
    }

    private func pop(_ bubble: BubbleModel) {
        guard !isFinished else { return }
        bubbles.removeAll { $0.id == bubble.id }
        score += 1
        impactTrigger += 1
        AudioHapticManager.shared.playPop()
        emitParticles(from: bubble)
    }

    private func emitParticles(from bubble: BubbleModel) {
        let count = Int.random(in: 8...12)
        let burst: [PopParticle] = (0..<count).map { index in
            let angle = (Double(index) / Double(count)) * Double.pi * 2
                + Double.random(in: -0.2...0.2)
            let speed = CGFloat.random(in: 90...180)
            return PopParticle(
                id: UUID(),
                position: bubble.position,
                velocity: CGVector(
                    dx: CGFloat(cos(angle)) * speed,
                    dy: CGFloat(sin(angle)) * speed
                ),
                size: CGFloat.random(in: 5...10),
                color: bubble.color,
                opacity: 1
            )
        }
        particles.append(contentsOf: burst)
    }

    private func finishRound() {
        guard !isFinished else { return }
        isRunning = false
        isFinished = true
        bubbles = []
        withAnimation(LearningTheme.forgivingSpring) {
            // overlay appears via isFinished
        }
        AudioHapticManager.shared.playSuccess()
        onRoundFinished?(score)
    }

    private func returnToMap() {
        if let onReturnToMap {
            onReturnToMap()
        } else {
            dismiss()
        }
    }
}

// MARK: - Bubble view

struct BubbleView: View {
    let bubble: BubbleModel
    var onPop: () -> Void

    var body: some View {
        Button(action: onPop) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                bubble.color.opacity(0.85),
                                bubble.color
                            ],
                            center: UnitPoint(x: 0.32, y: 0.28),
                            startRadius: 2,
                            endRadius: bubble.radius
                        )
                    )
                    .frame(width: bubble.radius * 2, height: bubble.radius * 2)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.55), lineWidth: 2)
                    }
                    .shadow(color: bubble.color.opacity(0.35), radius: 8, y: 4)

                // Shine
                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: bubble.radius * 0.35, height: bubble.radius * 0.22)
                    .offset(x: -bubble.radius * 0.28, y: -bubble.radius * 0.32)
            }
            .frame(width: max(LearningTheme.minTouchTarget, bubble.radius * 2),
                   height: max(LearningTheme.minTouchTarget, bubble.radius * 2))
            .contentShape(Circle())
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel("Bubble")
        .accessibilityHint("Double tap to pop")
    }
}

// MARK: - Models

struct BubbleModel: Identifiable {
    let id: Int
    var position: CGPoint
    var radius: CGFloat
    var color: Color
    var speed: CGFloat
    var wobbleAmplitude: CGFloat
    var wobbleSpeed: Double
    var wobblePhase: Double
}

private struct PopParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var color: Color
    var opacity: Double
}

private enum BubblePalette {
    static let colors: [Color] = [
        LearningTheme.accent,
        LearningTheme.coral,
        LearningTheme.sunshine,
        LearningTheme.success,
        Color(red: 0.42, green: 0.58, blue: 0.95),
        Color(red: 0.90, green: 0.45, blue: 0.72)
    ]

    static func random() -> Color {
        colors.randomElement() ?? LearningTheme.accent
    }
}

#Preview {
    BubblePopView()
}
