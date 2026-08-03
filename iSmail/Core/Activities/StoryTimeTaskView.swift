//
//  StoryTimeTaskView.swift
//  iSmail
//
//  Tap-to-advance story with optional comprehension beat — Lingokids-style listening.
//

import SwiftUI

struct StoryTimeTaskView: View {
    let content: StoryTimeContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var pageIndex = 0
    @State private var selectedChoiceID: UUID?
    @State private var softMissID: UUID?
    @State private var pageScale: CGFloat = 0.94
    @State private var celebrateAsk = false

    private var pages: [StoryPage] { content.pages }
    private var page: StoryPage? {
        guard pages.indices.contains(pageIndex) else { return nil }
        return pages[pageIndex]
    }

    private var isLastPage: Bool {
        pageIndex >= pages.count - 1
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 520

            VStack(spacing: compact ? 12 : 18) {
                pageDots

                if let page {
                    storyCard(page: page, compact: compact)
                        .scaleEffect(pageScale)
                        .animation(LearningTheme.buddyBounce, value: pageIndex)
                }

                Spacer(minLength: 4)

                if let page, page.hasQuestion {
                    askSection(page: page, compact: compact)
                } else {
                    nextButton
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            withAnimation(LearningTheme.buddyBounce) { pageScale = 1 }
            speakCurrentPage()
        }
        .onChange(of: pageIndex) { _, _ in
            selectedChoiceID = nil
            softMissID = nil
            pageScale = 0.94
            withAnimation(LearningTheme.buddyBounce) { pageScale = 1 }
            speakCurrentPage()
        }
    }

    // MARK: - Dots

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index <= pageIndex ? LearningTheme.accent : LearningTheme.slot)
                    .frame(width: index == pageIndex ? 22 : 10, height: 10)
                    .animation(LearningTheme.forgivingSpring, value: pageIndex)
            }
        }
        .accessibilityLabel("Story page \(pageIndex + 1) of \(pages.count)")
    }

    // MARK: - Card

    private func storyCard(page: StoryPage, compact: Bool) -> some View {
        VStack(spacing: compact ? 12 : 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [LearningTheme.sunshineSoft, LearningTheme.accentSoft],
                            center: .center,
                            startRadius: 4,
                            endRadius: 80
                        )
                    )
                    .frame(width: compact ? 110 : 140, height: compact ? 110 : 140)

                Text(page.emoji)
                    .font(.system(size: compact ? 52 : 64))
                    .accessibilityHidden(true)

                Image(systemName: page.symbolName)
                    .font(.system(size: compact ? 28 : 34, weight: .bold))
                    .foregroundStyle(LearningTheme.accent.opacity(0.35))
                    .offset(x: compact ? 36 : 44, y: compact ? 36 : 44)
            }

            Text(page.text)
                .font(.system(compact ? .title3 : .title2, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .minimumScaleFactor(0.85)
        }
        .padding(compact ? 16 : 22)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LearningTheme.slot.opacity(0.65))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(LearningTheme.accent.opacity(0.22), lineWidth: 2)
                }
        }
    }

    // MARK: - Ask

    private func askSection(page: StoryPage, compact: Bool) -> some View {
        VStack(spacing: 10) {
            if let ask = page.askLabel {
                Text(ask)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.coral)
            }

            let choices = page.askChoices ?? []
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(choices) { choice in
                    askChoiceButton(choice: choice, page: page, compact: compact)
                }
            }
        }
    }

    private func askChoiceButton(choice: SelectChoice, page: StoryPage, compact: Bool) -> some View {
        let isCorrect = choice.id == page.correctChoiceID
        let isSelected = selectedChoiceID == choice.id
        let isMiss = softMissID == choice.id
        let hintThis = showHint && isCorrect

        return Button {
            guard !celebrateAsk else { return }
            if isCorrect {
                selectedChoiceID = choice.id
                celebrateAsk = true
                AudioHapticManager.shared.playSuccess()
                onCorrectAttempt?()
                SafeAsync.after(0.55) {
                    onComplete?()
                }
            } else {
                softMissID = choice.id
                AudioHapticManager.shared.playIncorrect()
                onIncorrectAttempt?()
                SafeAsync.after(0.45) {
                    if softMissID == choice.id { softMissID = nil }
                }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: choice.symbolName)
                    .font(.system(size: compact ? 22 : 26, weight: .bold))
                Text(choice.label)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(LearningTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: LearningTheme.minTouchTarget)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isSelected || celebrateAsk && isCorrect
                            ? LearningTheme.successSoft
                            : (isMiss ? LearningTheme.softMissFill : LearningTheme.surface)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                hintThis
                                    ? LearningTheme.sunshine
                                    : (isSelected ? LearningTheme.success : LearningTheme.border.opacity(0.2)),
                                lineWidth: hintThis ? 3 : 2
                            )
                    }
            }
            .hintAura(isActive: hintThis)
        }
        .buttonStyle(KidBounceButtonStyle())
        .disabled(celebrateAsk)
        .accessibilityLabel(choice.label)
    }

    // MARK: - Next

    private var nextButton: some View {
        Button {
            AudioHapticManager.shared.playPop()
            if isLastPage {
                onCorrectAttempt?()
                onComplete?()
            } else {
                onCorrectAttempt?()
                withAnimation(LearningTheme.forgivingSpring) {
                    pageIndex += 1
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(isLastPage ? "Finish story" : "Next page")
                Image(systemName: isLastPage ? "star.fill" : "arrow.right")
            }
            .font(.system(.title3, design: .rounded).weight(.heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: LearningTheme.minTouchTarget)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LearningTheme.accent)
            }
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel(isLastPage ? "Finish story" : "Next page")
    }

    private func speakCurrentPage() {
        guard let page else { return }
        let text = page.askLabel.map { "\(page.text) \($0)" } ?? page.text
        SpeechManager.shared.speak(text: text)
    }
}

#Preview {
    StoryTimeTaskView(content: .previewFox)
        .padding()
        .background(PlayWorldBackground())
}
