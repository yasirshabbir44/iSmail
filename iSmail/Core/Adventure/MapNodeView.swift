//
//  MapNodeView.swift
//  iSmail
//
//  Circular adventure-path lesson node — completed, active, or locked.
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

    @State private var pulse = false
    @State private var mascotBob = false

    private let mapSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)

    var body: some View {
        ZStack {
            if state == .active {
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

            nodeDisk
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .strokeBorder(borderColor, lineWidth: state == .completed ? 4 : 3)
                }
                .shadow(
                    color: shadowColor,
                    radius: state == .locked ? 4 : 10,
                    y: 5
                )

            nodeGlyph
                .opacity(state == .locked ? 0.55 : 1)

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
            if state == .active {
                BuddyCoachView(mood: .cheering, size: size * 0.42)
                    .offset(y: mascotBob ? -size * 0.78 : -size * 0.72)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .animation(mapSpring, value: state)
        .onAppear { startActiveMotionIfNeeded() }
        .onChange(of: state) { _, newState in
            if newState == .active {
                startActiveMotionIfNeeded()
            } else {
                pulse = false
                mascotBob = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Pieces

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
                    .symbolEffect(.pulse, options: .repeating.speed(0.45), isActive: true)
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
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color(red: 0.86, green: 0.90, blue: 0.94).opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 1.5)
            .allowsHitTesting(false)
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
        switch state {
        case .completed: return "Lesson \(step), completed"
        case .active: return "Lesson \(step), current"
        case .locked: return "Lesson \(step), locked"
        }
    }

    private func startActiveMotionIfNeeded() {
        guard state == .active else { return }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            pulse = true
        }
        withAnimation(LearningTheme.floaty.repeatForever(autoreverses: true)) {
            mascotBob = true
        }
    }
}

#Preview {
    HStack(spacing: 28) {
        MapNodeView(step: 1, symbolName: "dog.fill", tint: LearningTheme.accent, state: .completed)
        MapNodeView(step: 2, symbolName: "apple.logo", tint: LearningTheme.coral, state: .active)
        MapNodeView(step: 3, symbolName: "list.number", tint: LearningTheme.accent, state: .locked)
    }
    .padding(40)
    .background(PlayWorldBackground())
}
