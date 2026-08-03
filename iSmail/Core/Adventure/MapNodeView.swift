//
//  MapNodeView.swift
//  iSmail
//
//  Circular adventure-path lesson node — completed, active, locked, or mystery chest.
//

import SwiftUI

enum MapNodeState: Equatable {
    case completed
    case active
    case locked
}

struct MapNodeView: View {
    let step: Int
    let symbolName: String
    let tint: Color
    let state: MapNodeState
    var size: CGFloat = 80
    /// When true, renders a treasure-chest milestone instead of a standard disk.
    var isChestReward: Bool = false
    /// Child avatar shown floating above today's active node.
    var avatarId: String? = nil
    /// Locked-future countdown, e.g. "Tomorrow" or "3 days".
    var countdownLabel: String? = nil
    /// Emphasize pulse/avatar only for the calendar-today node.
    var isTodaysNode: Bool = false

    @State private var pulse = false
    @State private var avatarBob = false

    private let mapSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    private var showsActiveChrome: Bool { state == .active && isTodaysNode }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if showsActiveChrome {
                    Circle()
                        .stroke(tint.opacity(0.55), lineWidth: 4)
                        .frame(width: size + 18, height: size + 18)
                        .scaleEffect(pulse ? 1.18 : 1.0)
                        .opacity(pulse ? 0.15 : 0.85)

                    Circle()
                        .stroke(tint.opacity(0.35), lineWidth: 3)
                        .frame(width: size + 10, height: size + 10)
                        .scaleEffect(pulse ? 1.08 : 1.0)
                        .opacity(pulse ? 0.25 : 0.7)
                }

                nodeBody
                    .frame(width: size, height: size)
                    .overlay {
                        if !isChestReward {
                            Circle()
                                .strokeBorder(borderColor, lineWidth: state == .completed ? 4 : 3)
                        }
                    }
                    .shadow(
                        color: shadowColor,
                        radius: state == .locked ? 4 : 10,
                        y: 5
                    )

                if !isChestReward {
                    nodeGlyph
                        .opacity(state == .locked ? 0.55 : 1)
                }

                if state == .locked {
                    fogOverlay
                }

                if state == .completed {
                    Image(systemName: "crown.fill")
                        .font(.system(size: size * 0.28, weight: .bold))
                        .foregroundStyle(LearningTheme.sunshine)
                        .offset(y: -size * 0.48)
                        .shadow(color: LearningTheme.sunshine.opacity(0.45), radius: 4, y: 2)

                    starBadge
                        .offset(x: size * 0.34, y: size * 0.34)
                }
            }
            .frame(width: max(size + 24, 80), height: max(size + 24, 80))
            .overlay(alignment: .top) {
                if showsActiveChrome, let avatarId {
                    AvatarBadgeView(avatarId: avatarId, size: size * 0.42)
                        .overlay {
                            RoundedRectangle(cornerRadius: size * 0.42 * 0.28, style: .continuous)
                                .strokeBorder(.white, lineWidth: 2)
                        }
                        .shadow(color: tint.opacity(0.35), radius: 6, y: 3)
                        .offset(y: avatarBob ? -size * 0.78 : -size * 0.72)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }

            if state == .locked, let countdownLabel, !countdownLabel.isEmpty {
                Text(countdownLabel)
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.mutedInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule(style: .continuous)
                            .fill(LearningTheme.surface.opacity(0.92))
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(LearningTheme.slot, lineWidth: 1.5)
                            }
                    }
                    .accessibilityLabel("Unlocks \(countdownLabel)")
            }
        }
        .animation(mapSpring, value: state)
        .onAppear { startActiveMotionIfNeeded() }
        .onChange(of: state) { _, _ in restartMotion() }
        .onChange(of: isTodaysNode) { _, _ in restartMotion() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Pieces

    @ViewBuilder
    private var nodeBody: some View {
        if isChestReward {
            chestNode
        } else {
            nodeDisk
        }
    }

    private var chestNode: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: chestFillColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .strokeBorder(Color.white.opacity(state == .locked ? 0.4 : 0.85), lineWidth: 3)
                }

            Image(systemName: state == .completed ? "checkmark.seal.fill" : "treasurechest.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(state == .locked ? LearningTheme.mutedInk.opacity(0.7) : .white)
                .symbolRenderingMode(.hierarchical)
                .opacity(state == .locked ? 0.75 : 1)

            if state == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundStyle(LearningTheme.ink.opacity(0.55))
                    .offset(x: size * 0.28, y: size * 0.28)
            }
        }
    }

    private var chestFillColors: [Color] {
        switch state {
        case .completed:
            return [LearningTheme.sunshine, LearningTheme.coral]
        case .active:
            return [Color(red: 0.95, green: 0.62, blue: 0.18), LearningTheme.sunshine]
        case .locked:
            return [
                Color(red: 0.78, green: 0.82, blue: 0.86),
                Color(red: 0.68, green: 0.72, blue: 0.78)
            ]
        }
    }

    private var nodeGlyph: some View {
        Group {
            switch state {
            case .completed:
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.36, weight: .heavy))
                    .foregroundStyle(.white)
            case .active:
                Image(systemName: symbolName)
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating.speed(0.45), isActive: isTodaysNode)
            case .locked:
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundStyle(LearningTheme.mutedInk.opacity(0.75))
            }
        }
    }

    private var starBadge: some View {
        ZStack {
            Circle()
                .fill(LearningTheme.sunshine)
                .frame(width: size * 0.34, height: size * 0.34)
                .overlay {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                }
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.16, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var fogOverlay: some View {
        Group {
            if isChestReward {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(cloudFill)
            } else {
                Circle()
                    .fill(cloudFill)
            }
        }
        .frame(width: size, height: size)
        .blur(radius: 1.5)
        .allowsHitTesting(false)
    }

    private var cloudFill: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.55),
                Color(red: 0.86, green: 0.90, blue: 0.94).opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var nodeDisk: some View {
        switch state {
        case .completed:
            Circle().fill(
                LinearGradient(
                    colors: [tint, tint.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .active:
            Circle().fill(
                LinearGradient(
                    colors: [tint.opacity(0.95), tint],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .locked:
            Circle().fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.78, green: 0.82, blue: 0.86),
                        Color(red: 0.68, green: 0.72, blue: 0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var borderColor: Color {
        switch state {
        case .completed: return Color.white.opacity(0.85)
        case .active: return Color.white.opacity(0.9)
        case .locked: return Color.white.opacity(0.45)
        }
    }

    private var shadowColor: Color {
        switch state {
        case .completed, .active: return tint.opacity(0.35)
        case .locked: return Color.black.opacity(0.08)
        }
    }

    private var accessibilityLabel: String {
        let chest = isChestReward ? ", mystery chest" : ""
        switch state {
        case .completed: return "Lesson \(step)\(chest), completed"
        case .active:
            return isTodaysNode
                ? "Lesson \(step)\(chest), today's adventure"
                : "Lesson \(step)\(chest), ready to play"
        case .locked:
            if let countdownLabel {
                return "Lesson \(step)\(chest), locked, unlocks \(countdownLabel)"
            }
            return "Lesson \(step)\(chest), locked"
        }
    }

    private func restartMotion() {
        pulse = false
        avatarBob = false
        startActiveMotionIfNeeded()
    }

    private func startActiveMotionIfNeeded() {
        guard showsActiveChrome else { return }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            pulse = true
        }
        withAnimation(LearningTheme.floaty.repeatForever(autoreverses: true)) {
            avatarBob = true
        }
    }
}

#Preview {
    HStack(alignment: .top, spacing: 28) {
        MapNodeView(
            step: 1,
            symbolName: "dog.fill",
            tint: LearningTheme.accent,
            state: .completed,
            isChestReward: false
        )
        MapNodeView(
            step: 2,
            symbolName: "apple.logo",
            tint: LearningTheme.coral,
            state: .active,
            avatarId: "avatar_lion",
            isTodaysNode: true
        )
        MapNodeView(
            step: 5,
            symbolName: "star.fill",
            tint: LearningTheme.sunshine,
            state: .locked,
            isChestReward: true,
            countdownLabel: "Tomorrow"
        )
    }
    .padding(40)
    .background(PlayWorldBackground())
}
