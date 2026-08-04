//
//  CountTapTaskView.swift
//  iSmail
//
//  Count the icons, then tap the matching number — LingoKids-style 123 play.
//

import SwiftUI

struct CountTapTaskView: View {
    let content: CountTapContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var selectedCorrect: Int?
    @State private var wigglingNumber: Int?
    @State private var wigglePhase = false
    @State private var isLocked = false
    @State private var bounceIcons = false
    @State private var successTrigger = 0
    @State private var warningTrigger = 0
    @State private var generation = 0

    private var numberColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: min(content.numberChoices.count, 4))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("How many \(content.itemLabel)?")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .multilineTextAlignment(.center)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: min(content.itemCount, 5)),
                spacing: 10
            ) {
                ForEach(0..<content.itemCount, id: \.self) { index in
                    Image(systemName: content.symbolName)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(LearningTheme.activityTint(for: .countTap))
                        .frame(width: 56, height: 56)
                        .background {
                            Circle()
                                .fill(LearningTheme.activitySoft(for: .countTap))
                        }
                        .scaleEffect(bounceIcons ? 1.08 : 1)
                        .animation(
                            LearningTheme.buddyBounce.delay(Double(index) * 0.05),
                            value: bounceIcons
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(content.itemCount) \(content.itemLabel)")

            LazyVGrid(columns: numberColumns, spacing: 12) {
                ForEach(content.numberChoices, id: \.self) { number in
                    numberButton(number)
                }
            }
        }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.warning, trigger: warningTrigger)
        .onAppear {
            bounceIcons = true
            SpeechManager.shared.speak(text: "How many \(content.itemLabel)?")
        }
        .onDisappear { generation += 1 }
    }

    private func numberButton(_ number: Int) -> some View {
        let isCorrect = selectedCorrect == number
        let isWiggling = wigglingNumber == number
        let isHinted = showHint && !isLocked && number == content.correctAnswer

        return Button {
            guard !isLocked else { return }
            handleTap(number)
        } label: {
            Text("\(number)")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(isCorrect ? LearningTheme.success : LearningTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: LearningTheme.minTouchTarget + 8)
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
                .hintAura(isActive: isHinted)
                .hintScalePulse(isActive: isHinted)
                .rotationEffect(.degrees(isWiggling ? (wigglePhase ? 5 : -5) : 0))
                .scaleEffect(isCorrect ? 1.08 : 1)
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel("Number \(number)")
    }

    private func handleTap(_ number: Int) {
        if number == content.correctAnswer {
            isLocked = true
            selectedCorrect = number
            successTrigger += 1
            AudioHapticManager.shared.playSuccess()
            SpeechManager.shared.speak(text: "\(number)! Great counting!")
            onCorrectAttempt?()
            let gen = generation
            SafeAsync.after(0.55) {
                guard gen == generation else { return }
                onComplete?()
            }
        } else {
            wigglingNumber = number
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
                wigglingNumber = nil
                wigglePhase = false
            }
        }
    }
}
