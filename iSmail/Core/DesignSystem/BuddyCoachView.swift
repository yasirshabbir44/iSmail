//
//  BuddyCoachView.swift
//  iSmail
//
//  Friendly coach mascot + speech bubble — LingoKids-style guidance for kids.
//

import SwiftUI

enum BuddyMood: Equatable {
    case idle
    case cheering
    case thinking
    case celebrating
}

struct BuddyCoachView: View {
    var mood: BuddyMood = .idle
    var size: CGFloat = 88

    @State private var bounce = false
    @State private var blink = false

    var body: some View {
        ZStack {
            // Soft ground shadow
            Ellipse()
                .fill(Color.black.opacity(0.10))
                .frame(width: size * 0.72, height: size * 0.16)
                .offset(y: size * 0.42)

            // Body
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.25, green: 0.78, blue: 0.82),
                            Color(red: 0.08, green: 0.62, blue: 0.68)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 3)
                }
                .shadow(color: LearningTheme.accent.opacity(0.35), radius: 10, y: 6)

            // Cheeks
            HStack(spacing: size * 0.38) {
                Circle().fill(LearningTheme.coral.opacity(0.45)).frame(width: size * 0.14, height: size * 0.10)
                Circle().fill(LearningTheme.coral.opacity(0.45)).frame(width: size * 0.14, height: size * 0.10)
            }
            .offset(y: size * 0.08)

            // Eyes
            HStack(spacing: size * 0.18) {
                eye
                eye
            }
            .offset(y: -size * 0.08)

            // Mouth
            mouth
                .offset(y: size * 0.18)

            // Antenna sparkle when celebrating / thinking
            if mood == .celebrating || mood == .thinking {
                Image(systemName: mood == .celebrating ? "star.fill" : "lightbulb.fill")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(mood == .celebrating ? LearningTheme.sunshine : LearningTheme.focus)
                    .offset(y: -size * 0.58)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size * 1.2, height: size * 1.35)
        .scaleEffect(bounce ? 1.06 : 1.0)
        .offset(y: bounce ? -4 : 0)
        .onChange(of: mood) { _, newMood in
            react(to: newMood)
        }
        .onAppear {
            react(to: mood)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_200_000_000)
                blink = true
                try? await Task.sleep(nanoseconds: 120_000_000)
                blink = false
            }
        }
        .accessibilityHidden(true)
    }

    private var eye: some View {
        Capsule(style: .continuous)
            .fill(LearningTheme.ink)
            .frame(
                width: size * 0.11,
                height: blink ? size * 0.03 : size * (mood == .thinking ? 0.10 : 0.16)
            )
            .animation(.easeInOut(duration: 0.08), value: blink)
    }

    @ViewBuilder
    private var mouth: some View {
        switch mood {
        case .idle, .thinking:
            Capsule(style: .continuous)
                .fill(LearningTheme.ink.opacity(0.75))
                .frame(width: size * 0.22, height: size * 0.06)
        case .cheering, .celebrating:
            // Open happy smile (bottom arc; do not rotate — that flips it into a frown)
            Circle()
                .trim(from: 0.10, to: 0.40)
                .stroke(LearningTheme.ink.opacity(0.8), style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round))
                .frame(width: size * 0.28, height: size * 0.28)
                .offset(y: -size * 0.06)
        }
    }

    private func react(to mood: BuddyMood) {
        switch mood {
        case .idle:
            withAnimation(LearningTheme.floaty.repeatForever(autoreverses: true)) {
                bounce = true
            }
        case .cheering, .celebrating:
            bounce = false
            withAnimation(LearningTheme.buddyBounce.repeatCount(3, autoreverses: true)) {
                bounce = true
            }
        case .thinking:
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }
}

// MARK: - Speech bubble

struct CoachBubble: View {
    let message: String
    var tint: Color = LearningTheme.accent

    var body: some View {
        Text(message)
            .font(.system(.body, design: .rounded).weight(.bold))
            .foregroundStyle(LearningTheme.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LearningTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(tint.opacity(0.3), lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
            }
            .accessibilityLabel(message)
    }
}

struct BuddyCoachBanner: View {
    let message: String
    var mood: BuddyMood = .idle
    var tint: Color = LearningTheme.accent
    var buddySize: CGFloat = 64

    var body: some View {
        HStack(alignment: .center, spacing: buddySize < 56 ? 8 : 12) {
            BuddyCoachView(mood: mood, size: buddySize)
                .fixedSize()

            CoachBubble(message: message, tint: tint)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(LearningTheme.forgivingSpring, value: message)
        .animation(LearningTheme.forgivingSpring, value: mood)
    }
}

// MARK: - Bounce press

struct KidBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(LearningTheme.focusFlash, value: configuration.isPressed)
    }
}

// MARK: - Progress pips

struct LessonProgressPips: View {
    let total: Int
    let completed: Int
    var tint: Color = LearningTheme.accent

    var body: some View {
        let count = max(total, 1)
        // Dense campaigns (21 chapters) must flex — fixed pip widths blew past SE/iPhone width
        // and expanded the entire home ScrollView past the trailing edge.
        let spacing: CGFloat = count > 12 ? 3 : (count > 8 ? 5 : 8)

        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index < completed ? tint : LearningTheme.slot)
                    .frame(maxWidth: .infinity)
                    .frame(height: 10)
                    .animation(LearningTheme.forgivingSpring, value: completed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress \(completed) of \(total)")
    }
}

#Preview {
    VStack(spacing: 24) {
        BuddyCoachBanner(message: "Drag the animals to the sounds!", mood: .idle)
        BuddyCoachBanner(message: "Almost — try again!", mood: .thinking, tint: LearningTheme.softMiss)
        BuddyCoachBanner(message: "Yay! You did it!", mood: .celebrating, tint: LearningTheme.success)
    }
    .padding()
    .background(PlayWorldBackground())
}
