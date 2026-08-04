//
//  LearningTheme.swift
//  iSmail
//
//  ADHD-friendly visual tokens with a warm, LingoKids-inspired play world.
//

import SwiftUI

enum LearningTheme {
    // MARK: Touch

    static let minTouchTarget: CGFloat = 64
    static let cardMinHeight: CGFloat = 80
    static let dropZoneSize: CGFloat = 114
    static let dragChipSize: CGFloat = 92
    /// Soft floor so SE can still fit 3–4 tiles without overflowing.
    static let compactTileFloor: CGFloat = 56
    /// Readable content width on iPad / landscape.
    static let contentMaxWidth: CGFloat = 720
    /// Shared horizontal inset for scroll screens.
    static let screenPaddingH: CGFloat = 20
    static let screenPaddingHNarrow: CGFloat = 16
    /// Shared internal card padding.
    static let cardPadding: CGFloat = 16
    static let cardPaddingNarrow: CGFloat = 14
    /// Width below which layouts should compress (SE / mini).
    static let narrowWidth: CGFloat = 380

    // MARK: Shape

    static let cornerRadius: CGFloat = 24
    static let chipCornerRadius: CGFloat = 20
    static let borderWidth: CGFloat = 3

    static func screenPadding(for width: CGFloat) -> CGFloat {
        width < narrowWidth ? screenPaddingHNarrow : screenPaddingH
    }

    static func cardPadding(for width: CGFloat) -> CGFloat {
        width < narrowWidth ? cardPaddingNarrow : cardPadding
    }

    static func isNarrow(_ width: CGFloat) -> Bool {
        width < narrowWidth
    }

    // MARK: Motion

    static let forgivingSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let reorderSpring = Animation.spring(response: 0.35, dampingFraction: 0.78)
    static let successBump = Animation.spring(response: 0.28, dampingFraction: 0.55)
    static let focusFlash = Animation.easeOut(duration: 0.04)
    static let buddyBounce = Animation.spring(response: 0.5, dampingFraction: 0.55)
    static let floaty = Animation.easeInOut(duration: 2.4)

    static let magneticThreshold: CGFloat = 72

    // MARK: Color — sunny play world (teal + coral + sunshine)

    static let canvas = Color(red: 0.93, green: 0.97, blue: 0.99)
    static let skyTop = Color(red: 0.55, green: 0.84, blue: 0.95)
    static let skyBottom = Color(red: 0.98, green: 0.95, blue: 0.86)
    static let surface = Color.white
    static let ink = Color(red: 0.14, green: 0.22, blue: 0.32)
    static let mutedInk = Color(red: 0.38, green: 0.45, blue: 0.55)
    static let accent = Color(red: 0.08, green: 0.62, blue: 0.68)
    static let accentSoft = Color(red: 0.08, green: 0.62, blue: 0.68).opacity(0.16)
    static let coral = Color(red: 0.98, green: 0.45, blue: 0.38)
    static let coralSoft = Color(red: 0.98, green: 0.45, blue: 0.38).opacity(0.16)
    static let sunshine = Color(red: 1.0, green: 0.78, blue: 0.22)
    static let sunshineSoft = Color(red: 1.0, green: 0.78, blue: 0.22).opacity(0.28)
    static let success = Color(red: 0.22, green: 0.70, blue: 0.48)
    static let successSoft = Color(red: 0.22, green: 0.70, blue: 0.48).opacity(0.20)
    static let focus = Color(red: 1.0, green: 0.78, blue: 0.22)
    static let focusSoft = Color(red: 1.0, green: 0.78, blue: 0.22).opacity(0.30)
    static let slot = Color(red: 0.90, green: 0.94, blue: 0.96)
    static let border = Color(red: 0.22, green: 0.32, blue: 0.40)
    static let softMiss = Color(red: 0.98, green: 0.72, blue: 0.28)
    static let softMissFill = Color(red: 0.98, green: 0.72, blue: 0.28).opacity(0.22)
    static let cloud = Color.white.opacity(0.88)

    static func activityTint(for type: ActivityType) -> Color {
        switch type {
        case .dragAndDrop: return accent
        case .tapAndSelect: return coral
        case .sequenceOrder: return Color(red: 0.42, green: 0.58, blue: 0.95)
        case .storyTime: return Color(red: 0.55, green: 0.40, blue: 0.78)
        case .interactiveStorybook: return Color(red: 0.28, green: 0.32, blue: 0.72)
        case .memoryMatch: return Color(red: 0.98, green: 0.55, blue: 0.20)
        case .letterHunt: return Color(red: 0.20, green: 0.55, blue: 0.90)
        case .countTap: return Color(red: 0.95, green: 0.45, blue: 0.55)
        case .speakAndSay: return Color(red: 0.35, green: 0.72, blue: 0.55)
        case .traceWrite: return Color(red: 0.95, green: 0.55, blue: 0.25)
        }
    }

    static func activitySoft(for type: ActivityType) -> Color {
        activityTint(for: type).opacity(0.16)
    }

    /// Equal tile side that fits `count` items in `availableWidth` without overflowing.
    static func adaptiveTileSide(
        count: Int,
        availableWidth: CGFloat,
        spacing: CGFloat,
        ideal: CGFloat,
        floor: CGFloat = compactTileFloor
    ) -> CGFloat {
        let n = max(count, 1)
        let gaps = spacing * CGFloat(n - 1)
        let fitted = max(1, (availableWidth - gaps) / CGFloat(n))
        // Never exceed fitted width (avoids SE overflow). Soft floor only when it still fits.
        if fitted >= floor {
            return min(ideal, fitted)
        }
        return fitted
    }

    static func adaptiveSpacing(for availableWidth: CGFloat, comfortable: CGFloat = 16) -> CGFloat {
        availableWidth < 340 ? max(8, comfortable * 0.6) : comfortable
    }
}

// MARK: - Play world atmosphere

struct PlayWorldBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                LinearGradient(
                    colors: [LearningTheme.skyTop, LearningTheme.skyBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Soft sun — relative to canvas
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LearningTheme.sunshine.opacity(0.55),
                                LearningTheme.sunshine.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: min(w, h) * 0.28
                        )
                    )
                    .frame(width: min(w, h) * 0.55, height: min(w, h) * 0.55)
                    .position(x: w * 0.82, y: h * 0.12)

                FloatingCloud(width: min(120, w * 0.32), height: 44)
                    .position(x: w * 0.22, y: h * 0.16)
                FloatingCloud(width: min(90, w * 0.24), height: 34)
                    .position(x: w * 0.58, y: h * 0.22)
                FloatingCloud(width: min(140, w * 0.36), height: 48)
                    .position(x: w * 0.42, y: h * 0.72)
                    .opacity(0.7)

                // Gentle hill
                Ellipse()
                    .fill(LearningTheme.success.opacity(0.18))
                    .frame(width: w * 1.35, height: h * 0.22)
                    .position(x: w * 0.5, y: h * 0.95)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct FloatingCloud: View {
    let width: CGFloat
    let height: CGFloat
    @State private var drift = false

    var body: some View {
        Capsule(style: .continuous)
            .fill(LearningTheme.cloud)
            .frame(width: width, height: height)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(LearningTheme.cloud)
                    .frame(width: height * 1.35, height: height * 1.35)
                    .offset(x: width * 0.12, y: -height * 0.25)
            }
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(LearningTheme.cloud)
                    .frame(width: height * 1.1, height: height * 1.1)
                    .offset(x: -width * 0.08, y: -height * 0.15)
            }
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            .offset(x: drift ? 10 : -8)
            .onAppear {
                withAnimation(LearningTheme.floaty.repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
    }
}

// MARK: - Shared prompt header

struct ActivityPromptHeader: View {
    let title: String
    let prompt: String
    var tint: Color = LearningTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .minimumScaleFactor(0.8)
                .lineLimit(2)
                .accessibilityAddTraits(.isHeader)

            Text(prompt)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LearningTheme.surface.opacity(0.92))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(tint.opacity(0.35), lineWidth: 2)
                        }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
