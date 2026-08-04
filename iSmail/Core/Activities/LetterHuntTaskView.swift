//
//  LetterHuntTaskView.swift
//  iSmail
//
//  ABC letter hunt — big letter cards with phonics coaching (LingoKids-style).
//

import SwiftUI

struct LetterHuntTaskView: View {
    let content: LetterHuntContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var selectedCorrect: String?
    @State private var wigglingLetter: String?
    @State private var wigglePhase = false
    @State private var isLocked = false
    @State private var successTrigger = 0
    @State private var warningTrigger = 0
    @State private var generation = 0

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: content.choices.count <= 3 ? content.choices.count : 2)
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(content.targetLetter)
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundStyle(LearningTheme.activityTint(for: .letterHunt))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LearningTheme.activitySoft(for: .letterHunt))
                }
                .accessibilityLabel("Look for letter \(content.targetLetter)")

            Text(content.soundHint)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.mutedInk)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(content.choices, id: \.self) { letter in
                    letterCard(letter)
                }
            }
        }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.warning, trigger: warningTrigger)
        .onDisappear { generation += 1 }
    }

    private func letterCard(_ letter: String) -> some View {
        let isCorrect = selectedCorrect == letter
        let isWiggling = wigglingLetter == letter
        let isHinted = showHint && !isLocked && letter == content.targetLetter

        return Button {
            guard !isLocked else { return }
            handleTap(letter)
        } label: {
            Text(letter)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(isCorrect ? LearningTheme.success : LearningTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: LearningTheme.minTouchTarget + 24)
                .background {
                    RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                        .fill(isCorrect ? LearningTheme.successSoft : LearningTheme.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                                .strokeBorder(
                                    isCorrect
                                        ? LearningTheme.success
                                        : (isHinted ? LearningTheme.sunshine : LearningTheme.border.opacity(0.25)),
                                    lineWidth: isCorrect || isHinted ? 4 : LearningTheme.borderWidth
                                )
                        }
                }
                .shadow(color: LearningTheme.activityTint(for: .letterHunt).opacity(0.12), radius: 8, y: 4)
                .hintAura(isActive: isHinted)
                .hintScalePulse(isActive: isHinted)
                .rotationEffect(.degrees(isWiggling ? (wigglePhase ? 6 : -6) : 0))
                .scaleEffect(isCorrect ? 1.06 : 1)
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel("Letter \(letter)")
    }

    private func handleTap(_ letter: String) {
        if letter == content.targetLetter {
            isLocked = true
            selectedCorrect = letter
            successTrigger += 1
            AudioHapticManager.shared.playSuccess()
            SpeechManager.shared.speak(text: "\(letter)! \(content.soundHint)")
            onCorrectAttempt?()
            let gen = generation
            SafeAsync.after(0.55) {
                guard gen == generation else { return }
                onComplete?()
            }
        } else {
            wigglingLetter = letter
            wigglePhase = false
            warningTrigger += 1
            AudioHapticManager.shared.playIncorrect()
            onIncorrectAttempt?()
            withAnimation(.easeInOut(duration: 0.08).repeatCount(4, autoreverses: true)) {
                wigglePhase = true
            }
            let gen = generation
            SafeAsync.after(0.35) {
                guard gen == generation else { return }
                wigglingLetter = nil
                wigglePhase = false
            }
        }
    }
}
