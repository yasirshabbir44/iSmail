//
//  TapAndSelectTaskView.swift
//  iSmail
//
//  Multi-choice card grid with instant focus, wiggle on miss, hint pulse & audio.
//

import SwiftUI

struct TapAndSelectTaskView: View {
    let content: TapAndSelectContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var pressedChoiceID: UUID?
    @State private var selectedCorrectID: UUID?
    @State private var wigglingChoiceID: UUID?
    @State private var wigglePhase = false
    @State private var successScale: CGFloat = 1.0
    @State private var successTrigger = 0
    @State private var warningTrigger = 0
    @State private var isLocked = false
    @State private var generation = 0

    private var columnCount: Int {
        if dynamicTypeSize.isAccessibilitySize { return 1 }
        if horizontalSizeClass == .regular, content.choices.count >= 4 { return 3 }
        return 2
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(content.choices) { choice in
                choiceCard(choice)
            }
        }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.warning, trigger: warningTrigger)
        .padding(.vertical, 4)
        .onDisappear { generation += 1 }
    }

    // MARK: - Card

    private func choiceCard(_ choice: SelectChoice) -> some View {
        let isPressed = pressedChoiceID == choice.id
        let isCorrect = selectedCorrectID == choice.id
        let isWiggling = wigglingChoiceID == choice.id
        let isHinted = showHint && !isLocked && choice.id == content.correctChoiceID

        return Text(choice.label)
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(isCorrect ? LearningTheme.success : LearningTheme.ink)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .frame(minHeight: LearningTheme.cardMinHeight)
            .background {
                RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                    .fill(cardFill(isPressed: isPressed, isCorrect: isCorrect))
                    .overlay {
                        RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                            .strokeBorder(
                                cardBorder(isPressed: isPressed, isCorrect: isCorrect),
                                lineWidth: isPressed || isCorrect ? 4 : LearningTheme.borderWidth
                            )
                    }
            }
            .overlay(alignment: .topLeading) {
                Image(systemName: choice.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isCorrect ? LearningTheme.success : LearningTheme.accent)
                    .padding(12)
                    .opacity(0.9)
            }
            .scaleEffect(isCorrect ? successScale : (isPressed ? 0.97 : 1.0))
            .hintScalePulse(isActive: isHinted)
            .hintAura(isActive: isHinted)
            .offset(x: isWiggling ? (wigglePhase ? 10 : -10) : 0)
            .animation(LearningTheme.focusFlash, value: isPressed)
            .contentShape(RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous))
            .highPriorityGesture(pressGesture(for: choice))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(choice.label)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(isLocked ? "Answer locked" : "Double tap to choose")
    }

    private func cardFill(isPressed: Bool, isCorrect: Bool) -> Color {
        if isCorrect { return LearningTheme.successSoft }
        if isPressed { return LearningTheme.focusSoft }
        return LearningTheme.surface
    }

    private func cardBorder(isPressed: Bool, isCorrect: Bool) -> Color {
        if isCorrect { return LearningTheme.success }
        if isPressed { return LearningTheme.focus }
        return LearningTheme.border.opacity(0.65)
    }

    // MARK: - Interaction

    private func pressGesture(for choice: SelectChoice) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isLocked else { return }
                if pressedChoiceID != choice.id {
                    withAnimation(LearningTheme.focusFlash) {
                        pressedChoiceID = choice.id
                    }
                }
            }
            .onEnded { _ in
                guard !isLocked else {
                    pressedChoiceID = nil
                    return
                }
                let tapped = choice
                withAnimation(LearningTheme.focusFlash) {
                    pressedChoiceID = nil
                }
                evaluate(tapped)
            }
    }

    private func evaluate(_ choice: SelectChoice) {
        if choice.id == content.correctChoiceID {
            isLocked = true
            selectedCorrectID = choice.id
            successTrigger += 1
            AudioHapticManager.shared.playSuccess()
            onCorrectAttempt?()

            withAnimation(LearningTheme.successBump) {
                successScale = 1.12
            }

            let token = generation
            SafeAsync.after(0.18) {
                guard token == generation else { return }
                withAnimation(LearningTheme.forgivingSpring) {
                    successScale = 1.0
                }
                onComplete?()
            }
        } else {
            warningTrigger += 1
            AudioHapticManager.shared.playIncorrect()
            onIncorrectAttempt?()
            runWiggle(for: choice.id)
        }
    }

    private func runWiggle(for id: UUID) {
        let token = generation
        wigglingChoiceID = id
        wigglePhase = false
        withAnimation(.easeInOut(duration: 0.07)) { wigglePhase = true }

        SafeAsync.after(0.07) {
            guard token == generation else { return }
            withAnimation(.easeInOut(duration: 0.07)) { wigglePhase = false }
        }
        SafeAsync.after(0.14) {
            guard token == generation else { return }
            withAnimation(.easeInOut(duration: 0.07)) { wigglePhase = true }
        }
        SafeAsync.after(0.21) {
            guard token == generation else { return }
            withAnimation(.easeInOut(duration: 0.07)) { wigglePhase = false }
        }
        SafeAsync.after(0.28) {
            guard token == generation else { return }
            wigglingChoiceID = nil
        }
    }
}

#Preview {
    TapAndSelectTaskView(content: .previewFruit, showHint: true)
        .padding()
        .background(LearningTheme.canvas)
}
