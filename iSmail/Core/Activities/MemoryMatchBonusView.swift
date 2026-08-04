//
//  MemoryMatchBonusView.swift
//  iSmail
//
//  Free-play memory match with coin rewards — same engine as curriculum memory.
//

import SwiftUI

struct MemoryMatchBonusView: View {
    var pairCount: Int = 4
    var onRoundFinished: ((Int) -> Void)?
    var onReturnToMap: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var content: MemoryMatchContent
    @State private var didComplete = false
    @State private var didAward = false
    @State private var showBurst = false
    @State private var missCount = 0

    init(
        pairCount: Int = 4,
        onRoundFinished: ((Int) -> Void)? = nil,
        onReturnToMap: (() -> Void)? = nil
    ) {
        self.pairCount = pairCount
        self.onRoundFinished = onRoundFinished
        self.onReturnToMap = onReturnToMap
        let pairs = Array(
            [
                MemoryPair(label: "Sun", symbolName: "sun.max.fill"),
                MemoryPair(label: "Moon", symbolName: "moon.fill"),
                MemoryPair(label: "Star", symbolName: "star.fill"),
                MemoryPair(label: "Heart", symbolName: "heart.fill"),
                MemoryPair(label: "Leaf", symbolName: "leaf.fill"),
                MemoryPair(label: "Fish", symbolName: "fish.fill")
            ].prefix(max(2, pairCount))
        )
        _content = State(initialValue: MemoryMatchContent(pairs: pairs))
    }

    private var coinsEarned: Int {
        max(2, content.pairs.count * 2 - missCount / 2)
    }

    var body: some View {
        ZStack {
            PlayWorldBackground()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ScreenBackButton(accessibilityLabel: "Back to map") {
                        returnToMap()
                    }

                    Text("Memory Match")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 6) {
                        Text("🪙")
                        Text("+\(didComplete ? coinsEarned : content.pairs.count * 2)")
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule(style: .continuous)
                            .fill(LearningTheme.sunshineSoft)
                    }
                    .fixedSize()
                }

                Text("Flip two cards — find every pair!")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)
                    .frame(maxWidth: .infinity, alignment: .leading)

                MemoryMatchTaskView(
                    content: content,
                    onIncorrectAttempt: {
                        missCount += 1
                    },
                    onComplete: {
                        guard !didComplete else { return }
                        didComplete = true
                        showBurst = true
                        if !didAward {
                            didAward = true
                            onRoundFinished?(coinsEarned)
                        }
                        AudioHapticManager.shared.playSuccess()
                    }
                )
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LearningTheme.surface.opacity(0.94))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(LearningTheme.coral.opacity(0.25), lineWidth: 2)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .frame(maxWidth: LearningTheme.contentMaxWidth)
            .frame(maxWidth: .infinity)

            if showBurst {
                RewardBurstView(
                    coinCount: min(max(coinsEarned, 4), 8),
                    symbolName: "star.fill",
                    isActive: $showBurst
                )
            }

            if didComplete {
                completionOverlay
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(LearningTheme.forgivingSpring, value: didComplete)
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()

            VStack(spacing: 14) {
                BuddyCoachView(mood: .celebrating, size: 84)
                Text("Memory hero!")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                Text("+\(coinsEarned) coins")
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
            }
            .padding(22)
            .frame(maxWidth: 360)
            .background {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(LearningTheme.surface)
            }
            .padding(24)
        }
    }

    private func returnToMap() {
        if let onReturnToMap {
            onReturnToMap()
        } else {
            dismiss()
        }
    }
}

#Preview {
    MemoryMatchBonusView()
}
