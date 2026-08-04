//
//  LearnHubView.swift
//  iSmail
//
//  Anytime Learn zone — Letters, Numbers, Words, Songs, Storybook & Trace.
//

import SwiftUI

struct LearnHubView: View {
    let ageYears: Int
    var initialCategory: LearnPracticeCategory? = nil
    var onPracticeFinished: ((LearnPracticeCategory, Int) -> Void)?
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: LearnPracticeCategory?
    @State private var practiceTasks: [TaskNode] = []
    @State private var taskIndex = 0
    @State private var earnedCoins = 0
    @State private var showRoundDone = false
    @State private var didAutoLaunch = false

    private var ageBand: AgeBand { AgeBand.from(ageYears: ageYears) }

    var body: some View {
        ZStack {
            PlayWorldBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if let category = selectedCategory, practiceTasks.indices.contains(taskIndex) {
                    practiceRunner(category: category)
                } else if showRoundDone {
                    roundCompleteCard
                        .padding(20)
                } else {
                    categoryGrid
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: LearningTheme.contentMaxWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !didAutoLaunch, let initialCategory else { return }
            didAutoLaunch = true
            startPractice(initialCategory)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ScreenBackButton {
                if selectedCategory != nil || showRoundDone {
                    withAnimation(LearningTheme.forgivingSpring) {
                        selectedCategory = nil
                        practiceTasks = []
                        taskIndex = 0
                        showRoundDone = false
                        earnedCoins = 0
                    }
                } else {
                    onClose?()
                    dismiss()
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Learn")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                Text(selectedCategory?.title ?? "Practice anytime — easy & fun")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Text(ageBand.friendlyLabel)
                .font(.system(.caption2, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(LearningTheme.accentSoft))
                .layoutPriority(0)
        }
        .frame(maxWidth: .infinity)
    }

    private var categoryGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BuddyCoachBanner(
                    message: "Pick Letters, Numbers, Words, Songs, or Trace!",
                    mood: .idle,
                    tint: LearningTheme.accent,
                    buddySize: 56
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                    spacing: 14
                ) {
                    ForEach(LearnPracticeCategory.allCases) { category in
                        categoryCard(category)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private func categoryCard(_ category: LearnPracticeCategory) -> some View {
        let tint = Color(red: category.tintRed, green: category.tintGreen, blue: category.tintBlue)

        return Button {
            startPractice(category)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: category.symbolName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 52, height: 52)
                    .background { Circle().fill(tint.opacity(0.16)) }

                Text(category.title)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(category.subtitle)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LearningTheme.surface.opacity(0.94))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(tint.opacity(0.35), lineWidth: 2)
                    }
                    .shadow(color: tint.opacity(0.14), radius: 10, y: 5)
            }
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel("\(category.title). \(category.subtitle)")
    }

    @ViewBuilder
    private func practiceRunner(category: LearnPracticeCategory) -> some View {
        let task = practiceTasks[taskIndex]
        let isLast = taskIndex >= practiceTasks.count - 1

        ActivityRunnerView(
            task: task,
            onTaskCompleted: { _ in
                earnedCoins += max(0, task.rewardCoins)
                if isLast {
                    // Let the celebration flash briefly, then show the practice-complete card.
                    SafeAsync.after(1.15) {
                        finishRound(category: category)
                    }
                }
            },
            chapterStep: taskIndex + 1,
            chapterStepCount: practiceTasks.count,
            onContinueToNext: isLast ? nil : {
                withAnimation(LearningTheme.forgivingSpring) {
                    taskIndex += 1
                }
            },
            displayedRewardCoins: task.rewardCoins,
            continueButtonTitle: "Next"
        )
        .id(task.id)
    }

    private var roundCompleteCard: some View {
        VStack(spacing: 16) {
            BuddyCoachView(mood: .celebrating, size: 90)

            Text("Practice complete!")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)

            Text("+\(earnedCoins) stars for practicing")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.mutedInk)

            Button {
                withAnimation(LearningTheme.forgivingSpring) {
                    showRoundDone = false
                    earnedCoins = 0
                }
            } label: {
                Text("Learn more")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: LearningTheme.minTouchTarget)
                    .background {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(LearningTheme.accent)
                    }
            }
            .buttonStyle(KidBounceButtonStyle())

            Button {
                onClose?()
                dismiss()
            } label: {
                Text("Back to map")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.accent)
            }
            .buttonStyle(KidBounceButtonStyle())
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LearningTheme.surface)
                .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
        }
    }

    private func startPractice(_ category: LearnPracticeCategory) {
        let tasks = LearnPracticeCatalog.tasks(for: category, ageYears: ageYears)
        guard !tasks.isEmpty else { return }
        withAnimation(LearningTheme.forgivingSpring) {
            selectedCategory = category
            practiceTasks = tasks
            taskIndex = 0
            earnedCoins = 0
            showRoundDone = false
        }
    }

    private func finishRound(category: LearnPracticeCategory) {
        onPracticeFinished?(category, earnedCoins)
        withAnimation(LearningTheme.forgivingSpring) {
            selectedCategory = nil
            practiceTasks = []
            taskIndex = 0
            showRoundDone = true
        }
    }
}
