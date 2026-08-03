//
//  RewardBurstView.swift
//  iSmail
//
//  Floating coin/star particle burst celebrating task completion.
//

import SwiftUI

struct RewardBurstView: View {
    let coinCount: Int
    let symbolName: String
    @Binding var isActive: Bool

    @State private var particles: [BurstParticle] = []
    @State private var hasFired = false
    @State private var generation = 0

    private var clampedCount: Int {
        min(max(coinCount, 5), 8)
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: symbolName)
                    .font(.system(size: particle.size, weight: .bold))
                    .foregroundStyle(particle.tint)
                    .shadow(color: LearningTheme.sunshine.opacity(0.45), radius: 4, y: 1)
                    .offset(x: particle.offset.width, y: particle.offset.height)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            if isActive, !hasFired {
                fire()
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                fire()
            } else {
                particles = []
                hasFired = false
            }
        }
        .onDisappear {
            generation += 1
        }
    }

    private func fire() {
        guard !hasFired else { return }
        hasFired = true

        let count = clampedCount
        let token = generation

        particles = (0..<count).map { index in
            let angle = (-70.0 + (140.0 / Double(max(count - 1, 1))) * Double(index)) * .pi / 180
            let distance = CGFloat.random(in: 72...128)
            return BurstParticle(
                id: UUID(),
                offset: .zero,
                target: CGSize(
                    width: CGFloat(cos(angle)) * distance,
                    height: CGFloat(sin(angle)) * distance - CGFloat.random(in: 20...48)
                ),
                opacity: 1,
                scale: 0.35,
                rotation: Double.random(in: -20...20),
                size: CGFloat.random(in: 22...30),
                tint: index.isMultiple(of: 2)
                    ? Color(red: 0.95, green: 0.75, blue: 0.15)
                    : Color(red: 1.0, green: 0.84, blue: 0.28)
            )
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            particles = particles.map { particle in
                var next = particle
                next.offset = particle.target
                next.scale = 1.0
                next.rotation += Double.random(in: -35...35)
                return next
            }
        }

        withAnimation(.easeOut(duration: 0.55).delay(0.45)) {
            particles = particles.map { particle in
                var next = particle
                next.opacity = 0
                next.offset = CGSize(
                    width: particle.target.width * 1.08,
                    height: particle.target.height - 28
                )
                next.scale = 0.7
                return next
            }
        }

        SafeAsync.after(1.1) {
            guard token == generation else { return }
            isActive = false
            particles = []
            hasFired = false
        }
    }
}

private struct BurstParticle: Identifiable {
    let id: UUID
    var offset: CGSize
    var target: CGSize
    var opacity: Double
    var scale: CGFloat
    var rotation: Double
    var size: CGFloat
    var tint: Color
}

#Preview {
    struct PreviewHost: View {
        @State private var active = true
        var body: some View {
            ZStack {
                LearningTheme.canvas.ignoresSafeArea()
                RewardBurstView(coinCount: 6, symbolName: "star.fill", isActive: $active)
                Button("Burst") { active = true }
                    .offset(y: 120)
            }
        }
    }
    return PreviewHost()
}
