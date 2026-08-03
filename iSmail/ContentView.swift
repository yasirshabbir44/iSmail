//
//  ContentView.swift
//  iSmail
//
//  Kids home hub — winding adventure path inspired by LingoKids-style learning apps.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Bindable var profile: ChildProfile
    @Environment(AppSession.self) private var session

    @State private var selectedTask: TaskNode?
    @State private var completedTaskIDs: Set<UUID> = []
    @State private var streakDays: Int = 3

    private let samples = TaskNode.chapter2Samples
    private let mapSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)

    private var completedCount: Int {
        samples.filter { completedTaskIDs.contains($0.id) }.count
    }

    private var streakStorageKey: String {
        "adventure.streak.\(profile.id.uuidString)"
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

                        AdventureMapView(
                            tasks: samples,
                            completedTaskIDs: completedTaskIDs
                        ) { task in
                            selectedTask = task
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
                            completedTaskIDs.insert(task.id)
                        }
                        bumpStreakIfNeeded()
                    }
                }
            }
        }
        .onAppear {
            let stored = UserDefaults.standard.integer(forKey: streakStorageKey)
            if stored > 0 {
                streakDays = stored
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
                total: samples.count,
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

    private var pathSubtitle: String {
        if completedCount == 0 {
            return "Follow the winding path — tap the glowing node!"
        }
        if completedCount >= samples.count {
            return "You finished today's path — replay any island!"
        }
        return "Great job! \(completedCount) of \(samples.count) islands cleared."
    }

    private func bumpStreakIfNeeded() {
        let dayKey = "adventure.streakDay.\(profile.id.uuidString)"
        let today = Calendar.current.startOfDay(for: .now).timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: dayKey)
        guard last != today else { return }

        withAnimation(mapSpring) {
            // First tracked day keeps the seeded streak; later days increment.
            if last != 0 {
                streakDays += 1
            }
            streakDays = max(streakDays, 1)
        }
        UserDefaults.standard.set(today, forKey: dayKey)
        UserDefaults.standard.set(streakDays, forKey: streakStorageKey)
    }
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
