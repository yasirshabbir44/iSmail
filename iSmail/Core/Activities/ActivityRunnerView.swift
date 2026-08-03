//
//  ActivityRunnerView.swift
//  iSmail
//
//  Guided lesson runner with buddy coach, progress, hints & celebration.
//

import SwiftUI

struct ActivityRunnerView: View {
    let task: TaskNode
    var onTaskCompleted: ((Int) -> Void)?
    /// When `true`, the prompt is read aloud once each time an activity loads.
    var autoReadPrompts: Bool = true
    /// 1-based index inside a multi-step chapter (nil = standalone task).
    var chapterStep: Int? = nil
    /// Total activities in the chapter lesson.
    var chapterStepCount: Int? = nil
    /// When set, celebration offers "Next" instead of dismissing home.
    var onContinueToNext: (() -> Void)? = nil
    /// Coins shown / awarded — chapter runner may override with chapter total on the final step.
    var displayedRewardCoins: Int? = nil
    /// Title shown under the coach when completing a mid-chapter step.
    var continueButtonTitle: String = "Next"

    @Environment(\.dismiss) private var dismiss

    @State private var hintManager = HintManager()
    @State private var frustrationDetector = FrustrationDetector()
    @State private var didComplete = false
    @State private var showBurst = false
    @State private var missPulse = 0
    @State private var coachMood: BuddyMood = .idle
    @State private var appearScale: CGFloat = 0.92
    @State private var stepProgress = 0
    @State private var celebrationLine = "Yay! Super star!"
    @State private var generation = 0

    private var tint: Color {
        LearningTheme.activityTint(for: task.activityType)
    }

    private var rewardCoins: Int {
        displayedRewardCoins ?? task.rewardCoins
    }

    private var isChapterFinalStep: Bool {
        guard let chapterStep, let chapterStepCount else { return true }
        return chapterStep >= chapterStepCount
    }

    private var hasChapterContinue: Bool {
        onContinueToNext != nil && !isChapterFinalStep
    }

    private var coachMessage: String {
        if didComplete {
            return celebrationLine
        }
        if hintManager.isHintActive {
            return hintMessage
        }
        if missPulse > 0 {
            return encouragementLines[missPulse % encouragementLines.count]
        }
        return task.prompt
    }

    private var hintMessage: String {
        switch task.activityType {
        case .dragAndDrop:
            return "Look for the glowing match — drag it over!"
        case .tapAndSelect:
            return "The glowing card is a friendly clue…"
        case .sequenceOrder:
            return "Warm slots need a swap — you've got this!"
        case .storyTime:
            return "Listen closely — the glowing answer is a clue!"
        case .memoryMatch:
            return "Remember the glowing pair — you've got this!"
        }
    }

    private let encouragementLines = [
        "Nice try! Have another go.",
        "Almost there — keep going!",
        "No worries — try a different one."
    ]

    private let celebrationLines = [
        "Yay! Super star!",
        "You did it — high five!",
        "Brilliant brain power!"
    ]

    var body: some View {
        GeometryReader { geo in
            let isCompactHeight = geo.size.height < 700
            let isNarrow = geo.size.width < 380

            ZStack {
                PlayWorldBackground()

                // No ScrollView around drag stages — avoids gesture fights that freeze/kill interaction.
                VStack(spacing: 0) {
                    topChrome
                        .padding(.horizontal, 16)
                        .padding(.top, isCompactHeight ? 4 : 8)
                        .padding(.bottom, isCompactHeight ? 6 : 10)

                    promptRow(compact: isCompactHeight || isNarrow)
                        .padding(.horizontal, 16)

                    Text(task.title)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, isCompactHeight ? 8 : 14)
                        .padding(.bottom, isCompactHeight ? 6 : 10)

                    activityStage
                        .padding(.horizontal, 16)
                        .frame(maxWidth: LearningTheme.contentMaxWidth)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: LearningTheme.contentMaxWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(appearScale)
                .opacity(appearScale == 1 ? 1 : 0.85)

                if showBurst {
                    RewardBurstView(
                        coinCount: min(max(task.rewardCoins, 5), 8),
                        symbolName: "star.fill",
                        isActive: $showBurst
                    )
                }

                if frustrationDetector.showCalmBanner {
                    calmBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(15)
                }

                if didComplete {
                    celebrationOverlay(narrow: isNarrow)
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                        .zIndex(20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(LearningTheme.forgivingSpring, value: didComplete)
        .animation(LearningTheme.forgivingSpring, value: hintManager.isHintActive)
        .animation(LearningTheme.forgivingSpring, value: coachMessage)
        .animation(LearningTheme.forgivingSpring, value: frustrationDetector.showCalmBanner)
        .sensoryFeedback(.impact(weight: .light), trigger: hintManager.hintUnlockTrigger)
        .sensoryFeedback(.impact(weight: .medium), trigger: frustrationDetector.calmTrigger)
        .onAppear {
            beginSession()
        }
        .onDisappear {
            generation += 1
            SpeechManager.shared.stop()
        }
        .onChange(of: task.id) { _, _ in
            resetSession()
        }
        .onChange(of: hintManager.isHintActive) { _, active in
            if active {
                coachMood = .thinking
            }
        }
    }

    // MARK: - Chrome

    private var topChrome: some View {
        HStack(spacing: 12) {
            ScreenBackButton {
                dismiss()
            }

            VStack(alignment: .leading, spacing: 6) {
                if let chapterStep, let chapterStepCount {
                    Text("Activity \(chapterStep) of \(chapterStepCount)")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    LessonProgressPips(
                        total: chapterStepCount,
                        completed: didComplete ? chapterStep : max(chapterStep - 1, 0),
                        tint: tint
                    )
                } else {
                    Text(task.activityType.displayName)
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    LessonProgressPips(
                        total: progressTotal,
                        completed: progressCompleted,
                        tint: tint
                    )
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(LearningTheme.sunshine)
                Text("+\(rewardCoins)")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                Capsule(style: .continuous)
                    .fill(LearningTheme.surface.opacity(0.95))
            }
            .accessibilityLabel("Reward \(rewardCoins) stars")
        }
    }

    private func promptRow(compact: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            BuddyCoachBanner(
                message: coachMessage,
                mood: coachMood,
                tint: didComplete
                    ? LearningTheme.success
                    : (hintManager.isHintActive ? LearningTheme.sunshine : tint),
                buddySize: compact ? 48 : 64
            )

            Button {
                SpeechManager.shared.speak(text: task.prompt)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(tint)
                    .frame(
                        width: compact ? 56 : LearningTheme.minTouchTarget,
                        height: compact ? 56 : LearningTheme.minTouchTarget
                    )
                    .background {
                        Circle()
                            .fill(LearningTheme.surface.opacity(0.95))
                            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                    }
            }
            .buttonStyle(KidBounceButtonStyle())
            .accessibilityLabel("Read prompt aloud")
        }
    }

    private var progressTotal: Int {
        switch task.payload {
        case .dragAndDrop(let content):
            return max(content.items.count, 1)
        case .memoryMatch(let content):
            return max(content.pairs.count, 1)
        case .storyTime(let content):
            return max(content.pages.count, 1)
        case .tapAndSelect, .sequenceOrder:
            return 1
        }
    }

    private var progressCompleted: Int {
        if didComplete { return progressTotal }
        return min(max(stepProgress, 0), progressTotal)
    }

    // MARK: - Stage

    private var activityStage: some View {
        activityBody
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LearningTheme.surface.opacity(0.94))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(tint.opacity(0.22), lineWidth: 2)
                    }
                    .shadow(color: tint.opacity(0.12), radius: 14, y: 8)
            }
            .idleAttentionAnchor(after: 10, scale: 1.04) {
                frustrationDetector.recordTap()
            }
            .allowsHitTesting(!frustrationDetector.isCoolingDown && !didComplete)
            .opacity(frustrationDetector.isCoolingDown ? 0.72 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: frustrationDetector.isCoolingDown)
    }

    @ViewBuilder
    private var activityBody: some View {
        switch task.payload {
        case .dragAndDrop(let content):
            DragAndDropTaskView(
                content: content,
                showHint: hintManager.isHintActive,
                onIncorrectAttempt: handleMiss,
                onCorrectAttempt: {
                    handleHit()
                    stepProgress = min(stepProgress + 1, progressTotal)
                },
                onComplete: handleComplete
            )
        case .tapAndSelect(let content):
            TapAndSelectTaskView(
                content: content,
                showHint: hintManager.isHintActive,
                onIncorrectAttempt: handleMiss,
                onCorrectAttempt: {
                    handleHit()
                    stepProgress = 1
                },
                onComplete: handleComplete
            )
        case .sequenceOrder(let content):
            SequenceOrderTaskView(
                content: content,
                showHint: hintManager.isHintActive,
                onIncorrectAttempt: handleMiss,
                onCorrectAttempt: {
                    handleHit()
                    stepProgress = 1
                },
                onComplete: handleComplete
            )
        case .storyTime(let content):
            StoryTimeTaskView(
                content: content,
                showHint: hintManager.isHintActive,
                onIncorrectAttempt: handleMiss,
                onCorrectAttempt: {
                    handleHit()
                    stepProgress = min(stepProgress + 1, progressTotal)
                },
                onComplete: handleComplete
            )
        case .memoryMatch(let content):
            MemoryMatchTaskView(
                content: content,
                showHint: hintManager.isHintActive,
                onIncorrectAttempt: handleMiss,
                onCorrectAttempt: {
                    handleHit()
                    stepProgress = min(stepProgress + 1, progressTotal)
                },
                onComplete: handleComplete
            )
        }
    }

    // MARK: - Calm banner

    private var calmBanner: some View {
        VStack {
            HStack(spacing: 12) {
                Text("Take a deep breath! 🌬️ Let's look closely.")
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(LearningTheme.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LearningTheme.surface)
                    .shadow(color: LearningTheme.accent.opacity(0.18), radius: 16, y: 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(LearningTheme.accent.opacity(0.28), lineWidth: 2)
                    }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Take a deep breath. Let's look closely.")
    }

    // MARK: - Celebration

    private func celebrationOverlay(narrow: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()
                .allowsHitTesting(true)

            VStack {
                Spacer()

                VStack(spacing: 14) {
                    BuddyCoachView(mood: .celebrating, size: narrow ? 80 : 100)

                    Text(hasChapterContinue ? "Nice work!" : "You got it!")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)

                    Text(
                        hasChapterContinue
                            ? "Next activity is ready"
                            : "+\(rewardCoins) stars added"
                    )
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(LearningTheme.mutedInk)

                    ViewThatFits(in: .horizontal) {
                        celebrationButtons(axis: .horizontal)
                        celebrationButtons(axis: .vertical)
                    }
                    .padding(.top, 6)
                }
                .padding(narrow ? 18 : 22)
                .frame(maxWidth: LearningTheme.contentMaxWidth)
                .background {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(LearningTheme.surface)
                        .shadow(color: .black.opacity(0.12), radius: 24, y: 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .safeAreaPadding(.bottom, 8)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func celebrationButtons(axis: Axis) -> some View {
        if hasChapterContinue {
            Button {
                onContinueToNext?()
            } label: {
                Text(continueButtonTitle)
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
        } else {
            Group {
                if axis == .horizontal {
                    HStack(spacing: 12) {
                        celebrationHomeButton
                        celebrationMoreButton
                    }
                } else {
                    VStack(spacing: 10) {
                        celebrationMoreButton
                        celebrationHomeButton
                    }
                }
            }
        }
    }

    private var celebrationHomeButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Home")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: LearningTheme.minTouchTarget)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LearningTheme.slot)
                }
        }
        .buttonStyle(KidBounceButtonStyle())
    }

    private var celebrationMoreButton: some View {
        Button {
            dismiss()
        } label: {
            Text("More play")
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

    // MARK: - Events

    private func beginSession() {
        hintManager.reset()
        frustrationDetector.reset()
        coachMood = .idle
        withAnimation(LearningTheme.buddyBounce) {
            appearScale = 1
        }
        maybeAutoReadPrompt()
    }

    private func maybeAutoReadPrompt() {
        guard autoReadPrompts else { return }
        // Story Time speaks each page itself — avoid double TTS.
        if task.activityType == .storyTime { return }
        let token = generation
        // Brief delay so the stage can settle before speaking.
        SafeAsync.after(0.35) {
            guard token == generation, !didComplete else { return }
            SpeechManager.shared.speak(text: task.prompt)
        }
    }

    private func handleMiss() {
        frustrationDetector.recordTap()
        hintManager.recordMiss()
        missPulse += 1
        coachMood = .thinking
    }

    private func handleHit() {
        frustrationDetector.recordTap()
        hintManager.recordHit()
        coachMood = .cheering
        let token = generation
        SafeAsync.after(0.55) {
            guard token == generation, !didComplete else { return }
            coachMood = hintManager.isHintActive ? .thinking : .idle
        }
    }

    private func handleComplete() {
        guard !didComplete else { return }
        didComplete = true
        hintManager.reset()
        frustrationDetector.reset()
        SpeechManager.shared.stop()
        showBurst = true
        celebrationLine = celebrationLines.randomElement() ?? "Yay! You did it!"
        coachMood = .celebrating
        stepProgress = progressTotal
        // Mid-chapter steps don't award coins — chapter runner awards the full reward at the end.
        let coins = hasChapterContinue ? 0 : rewardCoins
        onTaskCompleted?(coins)
    }

    private func resetSession() {
        generation += 1
        SpeechManager.shared.stop()
        hintManager.reset()
        frustrationDetector.reset()
        didComplete = false
        showBurst = false
        missPulse = 0
        stepProgress = 0
        coachMood = .idle
        appearScale = 0.92
        withAnimation(LearningTheme.buddyBounce) {
            appearScale = 1
        }
        maybeAutoReadPrompt()
    }
}

#Preview("Drag & Drop") {
    NavigationStack {
        ActivityRunnerView(task: .previewDragAndDrop)
    }
}

#Preview("Tap & Select") {
    NavigationStack {
        ActivityRunnerView(task: .previewTapAndSelect)
    }
}

#Preview("Sequence Order") {
    NavigationStack {
        ActivityRunnerView(task: .previewSequenceOrder)
    }
}

#Preview("Story Time") {
    NavigationStack {
        ActivityRunnerView(task: .previewStoryTime)
    }
}

#Preview("Memory Match") {
    NavigationStack {
        ActivityRunnerView(task: .previewMemoryMatch)
    }
}
