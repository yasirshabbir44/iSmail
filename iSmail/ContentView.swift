//
//  ContentView.swift
//  iSmail
//
//  Kids home hub — winding adventure path with daily chapter unlocks.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Bindable var profile: ChildProfile
    @Environment(AppSession.self) private var session

    @State private var progress: DailyProgressManager
    @State private var selectedTask: TaskNode?
    @State private var streakDays: Int = 3
    @State private var showDailySpin = false
    @State private var bonusDestination: BonusDestination?

    private let mapSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)

    private var completedCount: Int { progress.completedCount }

    private var streakStorageKey: String {
        "adventure.streak.\(profile.id.uuidString)"
    }

    init(profile: ChildProfile) {
        self.profile = profile
        _progress = State(
            initialValue: DailyProgressManager(profileID: profile.id)
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isNarrow = geo.size.width < 380

                ScrollView {
                    VStack(alignment: .leading, spacing: isNarrow ? 18 : 24) {
                        MascotHeaderView(
                            nickname: profile.nickname,
                            avatarId: profile.avatarId,
                            streakDays: streakDays,
                            coinBalance: profile.totalCoins,
                            onAvatarTap: {
                                withAnimation(LearningTheme.forgivingSpring) {
                                    session.clearActiveProfile()
                                }
                            }
                        )

                        pathIntro(narrow: isNarrow)

                        bonusActions(narrow: isNarrow)

                        AdventureMapView(
                            chapters: progress.chapters,
                            progress: progress,
                            avatarId: profile.avatarId
                        ) { chapter in
                            selectedTask = ChapterRepository.task(for: chapter)
                        }
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
                        withAnimation(LearningTheme.successBump) {
                            profile.totalCoins = min(profile.totalCoins + max(0, coins), 9_999)
                            progress.markCompleted(id: task.id)
                        }
                        bumpStreakIfNeeded()
                    }
                }
                .navigationDestination(item: $bonusDestination) { destination in
                    switch destination {
                    case .petShop:
                        PetShopView(profile: profile)
                    case .bubblePop:
                        BubblePopView(
                            onRoundFinished: { coins in
                                withAnimation(LearningTheme.successBump) {
                                    profile.totalCoins = min(profile.totalCoins + max(0, coins), 9_999)
                                }
                            },
                            onReturnToMap: {
                                bonusDestination = nil
                            }
                        )
                    }
                }
            }
        }
        .overlay {
            if showDailySpin {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { /* require claim via button */ }

                    DailySpinSheet(
                        onClaim: { coins in
                            let awarded = progress.claimDailySpin(rewardCoins: coins)
                            withAnimation(LearningTheme.successBump) {
                                profile.totalCoins = min(profile.totalCoins + awarded, 9_999)
                            }
                        },
                        onDismiss: {
                            withAnimation(LearningTheme.forgivingSpring) {
                                showDailySpin = false
                            }
                        }
                    )
                    .transition(.scale(scale: 0.86).combined(with: .opacity))
                }
                .animation(LearningTheme.forgivingSpring, value: showDailySpin)
            }
        }
        .onAppear {
            let stored = UserDefaults.standard.integer(forKey: streakStorageKey)
            if stored > 0 {
                streakDays = stored
            }
            progress.refreshSpinClaimIfNeeded()
            if !progress.hasClaimedDailySpin {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(LearningTheme.forgivingSpring) {
                        showDailySpin = true
                    }
                }
            }
        }
    }

    // MARK: - Path intro

    private func pathIntro(narrow: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's adventure")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)

            Text(pathSubtitle)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            LessonProgressPips(
                total: progress.chapters.count,
                completed: completedCount,
                tint: LearningTheme.accent
            )
            .padding(.top, 4)
        }
        .padding(narrow ? 14 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.88))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.75), lineWidth: 2)
                }
                .shadow(color: LearningTheme.accent.opacity(0.10), radius: 12, y: 6)
        }
        .animation(mapSpring, value: completedCount)
    }

    // MARK: - Bonus actions

    private func bonusActions(narrow: Bool) -> some View {
        HStack(spacing: narrow ? 10 : 14) {
            bonusButton(
                title: "Pet Shop",
                symbol: "tshirt.fill",
                tint: LearningTheme.coral
            ) {
                bonusDestination = .petShop
            }

            bonusButton(
                title: "Bubble Pop",
                symbol: "bubbles.and.sparkles.fill",
                tint: LearningTheme.accent
            ) {
                bonusDestination = .bubblePop
            }
        }
    }

    private func bonusButton(
        title: String,
        symbol: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(tint.opacity(0.16))
                    }

                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: LearningTheme.minTouchTarget)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LearningTheme.surface.opacity(0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(tint.opacity(0.35), lineWidth: 2)
                    }
                    .shadow(color: tint.opacity(0.12), radius: 8, y: 4)
            }
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel(title)
    }

    private var pathSubtitle: String {
        if let today = progress.todaysChapter, !today.isCompleted {
            return "Day \(today.dayNumber) is unlocked — tap the glowing island!"
        }
        if let focus = progress.currentFocusChapter {
            if progress.isEarlyUnlocked(focus) {
                return "Day \(focus.dayNumber) unlocked early — keep going!"
            }
            return "Day \(focus.dayNumber) is ready — tap the glowing island!"
        }
        if completedCount == 0 {
            return "Follow the winding path — finish a day to unlock the next!"
        }
        if completedCount >= progress.chapters.count {
            return "You cleared the whole path — amazing!"
        }
        return "Great job! \(completedCount) of \(progress.chapters.count) islands cleared."
    }

    private func bumpStreakIfNeeded() {
        let dayKey = "adventure.streakDay.\(profile.id.uuidString)"
        let today = Calendar.current.startOfDay(for: .now).timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: dayKey)
        guard last != today else { return }

        withAnimation(mapSpring) {
            if last != 0 {
                streakDays += 1
            }
            streakDays = max(streakDays, 1)
        }
        UserDefaults.standard.set(today, forKey: dayKey)
        UserDefaults.standard.set(streakDays, forKey: streakStorageKey)
    }
}

// MARK: - Bonus destinations

private enum BonusDestination: String, Identifiable, Hashable {
    case petShop
    case bubblePop

    var id: String { rawValue }
}

#Preview {
    let container = try! ModelContainer(
        for: ChildProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let profile = ChildProfile(
        nickname: "Ismail",
        dateOfBirth: .now.addingTimeInterval(-7 * 365 * 24 * 3600),
        avatarId: "avatar_lion",
        totalCoins: 120
    )
    container.mainContext.insert(profile)
    return ContentView(profile: profile)
        .environment(AppSession())
        .modelContainer(container)
}
