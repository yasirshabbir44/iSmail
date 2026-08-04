//
//  MascotHeaderView.swift
//  iSmail
//
//  Interactive adventure-map top bar — avatar, streak, and coin wallet.
//

import SwiftUI

struct MascotHeaderView: View {
    let nickname: String
    let avatarId: String
    let streakDays: Int
    let coinBalance: Int
    var onBack: (() -> Void)?
    var onAvatarTap: (() -> Void)?

    @State private var streakPulse = false
    @State private var coinWiggle = false

    private let mapSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)

    var body: some View {
        HStack(spacing: 8) {
            if let onBack {
                ScreenBackButton(accessibilityLabel: "Back to profiles", action: onBack)
            }

            avatarChip
                .layoutPriority(-1)

            Spacer(minLength: 4)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    streakChip(compact: false)
                    coinChip
                }
                HStack(spacing: 6) {
                    streakChip(compact: true)
                    coinChip
                }
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.94))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.85), lineWidth: 2)
                }
                .shadow(color: LearningTheme.accent.opacity(0.12), radius: 12, y: 6)
        }
        .onAppear {
            withAnimation(LearningTheme.floaty.repeatForever(autoreverses: true)) {
                streakPulse = true
            }
        }
        .onChange(of: coinBalance) { _, _ in
            withAnimation(mapSpring) {
                coinWiggle = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 280_000_000)
                withAnimation(mapSpring) { coinWiggle = false }
            }
        }
    }

    // MARK: - Left: avatar + name

    private var avatarChip: some View {
        Button {
            onAvatarTap?()
        } label: {
            HStack(spacing: 8) {
                AvatarBadgeView(avatarId: avatarId, size: 44)
                    .overlay {
                        RoundedRectangle(cornerRadius: 44 * 0.28, style: .continuous)
                            .strokeBorder(LearningTheme.accent.opacity(0.55), lineWidth: 2)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(nickname)
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if onAvatarTap != nil {
                        Text("Switch")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundStyle(LearningTheme.accent)
                    }
                }
                .frame(minWidth: 0, alignment: .leading)
            }
        }
        .buttonStyle(KidBounceButtonStyle())
        .disabled(onAvatarTap == nil)
        .accessibilityLabel("\(nickname), switch profile")
    }

    // MARK: - Center: streak

    private func streakChip(compact: Bool) -> some View {
        HStack(spacing: 5) {
            Text("🔥")
                .font(.system(size: 16))
                .scaleEffect(streakPulse ? 1.12 : 1.0)
                .offset(y: streakPulse ? -1 : 1)

            Text("\(streakDays)")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .contentTransition(.numericText())
                .monospacedDigit()
                .animation(mapSpring, value: streakDays)

            if !compact {
                Text(streakDays == 1 ? "Day" : "Days")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(LearningTheme.mutedInk)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, 8)
        .background {
            Capsule(style: .continuous)
                .fill(LearningTheme.coralSoft)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(LearningTheme.coral.opacity(0.35), lineWidth: 2)
                }
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Daily streak \(streakDays) days")
    }

    // MARK: - Right: coins

    private var coinChip: some View {
        HStack(spacing: 5) {
            Text("🪙")
                .font(.system(size: 16))
                .rotationEffect(.degrees(coinWiggle ? 12 : 0))
                .scaleEffect(coinWiggle ? 1.12 : 1.0)

            Text("\(coinBalance)")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .contentTransition(.numericText())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .animation(mapSpring, value: coinBalance)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule(style: .continuous)
                .fill(LearningTheme.sunshineSoft)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(LearningTheme.sunshine.opacity(0.5), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Coin balance \(coinBalance)")
    }
}

#Preview {
    MascotHeaderView(
        nickname: "Ismail",
        avatarId: "avatar_lion",
        streakDays: 3,
        coinBalance: 120,
        onBack: {},
        onAvatarTap: {}
    )
    .padding()
    .background(PlayWorldBackground())
}
