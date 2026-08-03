//
//  ChapterRunnerView.swift
//  iSmail
//
//  Guides kids through a multi-step chapter lesson (warm-up → play → wrap-up).
//

import SwiftUI

struct ChapterRunnerView: View {
    let lesson: ChapterLesson
    var onChapterCompleted: ((Int) -> Void)?

    @State private var stepIndex = 0
    @State private var didAwardChapter = false

    var body: some View {
        let safeIndex = min(max(stepIndex, 0), max(lesson.steps.count - 1, 0))
        let step = lesson.steps.isEmpty ? nil : lesson.steps[safeIndex]
        let finalStep = safeIndex >= lesson.steps.count - 1

        if let step {
            ActivityRunnerView(
                task: step.task,
                onTaskCompleted: { coins in
                    if finalStep {
                        awardChapterIfNeeded(fallbackCoins: coins)
                    }
                },
                chapterStep: safeIndex + 1,
                chapterStepCount: max(lesson.stepCount, 1),
                onContinueToNext: finalStep ? nil : { advanceStep() },
                displayedRewardCoins: finalStep ? lesson.rewardCoins : step.task.rewardCoins,
                continueButtonTitle: nextButtonTitle(after: safeIndex)
            )
            .id(step.id)
        } else {
            Text("Chapter is empty")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.mutedInk)
        }
    }

    private func nextButtonTitle(after index: Int) -> String {
        let next = index + 1
        guard lesson.steps.indices.contains(next) else { return "Next" }
        return "Next: \(lesson.steps[next].label)"
    }

    private func advanceStep() {
        guard stepIndex < lesson.steps.count - 1 else { return }
        withAnimation(LearningTheme.forgivingSpring) {
            stepIndex += 1
        }
    }

    private func awardChapterIfNeeded(fallbackCoins: Int) {
        guard !didAwardChapter else { return }
        didAwardChapter = true
        let coins = max(lesson.rewardCoins, fallbackCoins)
        onChapterCompleted?(coins)
    }
}

#Preview {
    NavigationStack {
        ChapterRunnerView(lesson: .previewAnimalFriends)
    }
}
