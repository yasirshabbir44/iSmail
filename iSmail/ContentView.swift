//
//  ContentView.swift
//  iSmail
//
//  Kids home hub — brand-first play world inspired by LingoKids-style learning apps.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Bindable var profile: ChildProfile
    @Environment(AppSession.self) private var session

    @State private var selectedTask: TaskNode?
    @State private var completedTaskIDs: Set<UUID> = []
    @State private var heroBounce = false
    private let samples = TaskNode.chapter2Samples

    private var completedCount: Int {
        samples.filter { completedTaskIDs.contains($0.id) }.count
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isNarrow = geo.size.width < 380

                ScrollView {
                    VStack(alignment: .leading, spacing: isNarrow ? 22 : 28) {
                        topBar
                        heroSection(narrow: isNarrow)
                        todaysPath(narrow: isNarrow)
                    }
                    .padding(.horizontal, isNarrow ? 16 : 20)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                    .frame(maxWidth: LearningTheme.contentMaxWidth)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .background(PlayWorldBackground())
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: $selectedTask) { task in
                    ActivityRunnerView(task: task) { coins in
                        // Cap runaway awards if a completion somehow fires twice.
                        withAnimation(LearningTheme.successBump) {
                            profile.totalCoins = min(profile.totalCoins + max(0, coins), 9_999)
                            completedTaskIDs.insert(task.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(LearningTheme.forgivingSpring) {
                    session.clearActiveProfile()
                }
            } label: {
                HStack(spacing: 10) {
                    AvatarBadgeView(avatarId: profile.avatarId, size: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: 44 * 0.28, style: .continuous)
                                .strokeBorder(LearningTheme.accent.opacity(0.5), lineWidth: 2)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.nickname)
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(LearningTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text("Switch")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundStyle(LearningTheme.accent)
                    }
                }
                .padding(.trailing, 6)
            }
            .buttonStyle(KidBounceButtonStyle())
            .accessibilityLabel("\(profile.nickname), switch profile")

            Spacer()

            starWallet
        }
    }

    private var starWallet: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(LearningTheme.sunshine)
                .symbolEffect(.bounce, value: profile.totalCoins)

            Text("\(profile.totalCoins)")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Capsule(style: .continuous)
                .fill(LearningTheme.surface.opacity(0.95))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(LearningTheme.sunshine.opacity(0.45), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
        .accessibilityLabel("Star balance \(profile.totalCoins)")
    }

    // MARK: - Hero

    private func heroSection(narrow: Bool) -> some View {
        let buddy = BuddyCoachView(mood: .cheering, size: narrow ? 72 : 96)
            .scaleEffect(heroBounce ? 1.04 : 1.0)
            .onAppear {
                withAnimation(LearningTheme.floaty.repeatForever(autoreverses: true)) {
                    heroBounce = true
                }
            }

        let copy = VStack(alignment: .leading, spacing: 10) {
            Text("Hi \(profile.nickname)!")
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

            Text(heroSubtitle)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            LessonProgressPips(
                total: samples.count,
                completed: completedCount,
                tint: LearningTheme.accent
            )
            .padding(.top, 2)
        }

        return Group {
            if narrow {
                VStack(alignment: .leading, spacing: 14) {
                    buddy
                    copy
                }
            } else {
                HStack(alignment: .center, spacing: 14) {
                    buddy
                    copy
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
                }
                .shadow(color: LearningTheme.accent.opacity(0.12), radius: 16, y: 8)
        }
    }

    private var heroSubtitle: String {
        if completedCount == 0 {
            return "Pick a bright lesson below. Big buttons, fun sounds!"
        }
        if completedCount >= samples.count {
            return "Wow — you finished today's path! Play again anytime."
        }
        return "Great job! \(completedCount) of \(samples.count) lessons done."
    }

    // MARK: - Lesson path

    private func todaysPath(narrow: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's path")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)

            Text("One lesson at a time — take your time.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)

            VStack(spacing: 16) {
                ForEach(Array(samples.enumerated()), id: \.element.id) { index, task in
                    lessonIsland(
                        task: task,
                        step: index + 1,
                        isDone: completedTaskIDs.contains(task.id),
                        narrow: narrow
                    )
                }
            }
        }
    }

    private func lessonIsland(task: TaskNode, step: Int, isDone: Bool, narrow: Bool) -> some View {
        let tint = LearningTheme.activityTint(for: task.activityType)
        let soft = LearningTheme.activitySoft(for: task.activityType)
        let iconSide: CGFloat = narrow ? 64 : 76
        let playSide: CGFloat = LearningTheme.minTouchTarget

        return Button {
            selectedTask = task
        } label: {
            HStack(spacing: narrow ? 10 : 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(soft)
                        .frame(width: iconSide, height: iconSide)

                    Image(systemName: task.activityType.systemImage)
                        .font(.system(size: iconSide * 0.4, weight: .bold))
                        .foregroundStyle(tint)
                        .symbolEffect(.pulse, options: .repeating.speed(0.4), isActive: !isDone)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Lesson \(step)")
                            .font(.system(.caption, design: .rounded).weight(.heavy))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(soft, in: Capsule(style: .continuous))

                        if isDone {
                            Label("Done", systemImage: "checkmark.circle.fill")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(LearningTheme.success)
                        }
                    }

                    Text(task.title)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(kidFriendlyVerb(for: task.activityType))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(LearningTheme.mutedInk)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(LearningTheme.sunshine)
                        Text("Earn \(task.rewardCoins)")
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundStyle(LearningTheme.mutedInk)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: playSide, height: playSide)
                    .background(tint, in: Circle())
                    .shadow(color: tint.opacity(0.35), radius: 8, y: 4)
            }
            .padding(narrow ? 12 : 16)
            .frame(minHeight: narrow ? 96 : 108)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LearningTheme.surface.opacity(0.95))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(tint.opacity(isDone ? 0.55 : 0.28), lineWidth: isDone ? 3 : 2)
                    }
                    .shadow(color: tint.opacity(0.14), radius: 12, y: 6)
            }
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel("\(task.title), lesson \(step)")
        .accessibilityHint(isDone ? "Play again" : "Start lesson")
    }

    private func kidFriendlyVerb(for type: ActivityType) -> String {
        switch type {
        case .dragAndDrop: return "Drag & match — big targets!"
        case .tapAndSelect: return "Tap the right answer"
        case .sequenceOrder: return "Put the steps in order"
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ChildProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let profile = ChildProfile(
        nickname: "Sam",
        dateOfBirth: .now.addingTimeInterval(-7 * 365 * 24 * 3600),
        avatarId: "avatar_lion",
        totalCoins: 12
    )
    container.mainContext.insert(profile)
    return ContentView(profile: profile)
        .environment(AppSession())
        .modelContainer(container)
}
