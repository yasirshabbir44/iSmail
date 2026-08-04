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
    @State private var practiceStore: PracticeProgressStore
    @State private var selectedLesson: ChapterLesson?
    @State private var streakDays: Int = 3
    @State private var showDailySpin = false
    @State private var bonusDestination: BonusDestination?
    @State private var newlyUnlockedSticker: StickerBadge?
    @State private var stickerStore: StickerBookStore
    @State private var completedChapterToday = false
    @State private var learnLaunchCategory: LearnPracticeCategory?

    private let mapSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)

    private var completedCount: Int { progress.completedCount }

    private var ageBand: AgeBand {
        AgeBand.from(ageYears: profile.ageInYears)
    }

    private var streakStorageKey: String {
        "adventure.streak.\(profile.id.uuidString)"
    }

    private var chapterDoneTodayKey: String {
        "adventure.chapterDoneDay.\(profile.id.uuidString)"
    }

    private var missionChapter: ChapterNode? {
        if let today = progress.todaysChapter, !today.isCompleted {
            return today
        }
        return progress.currentFocusChapter ?? progress.todaysChapter
    }

    private var missionChapterDone: Bool {
        if completedChapterToday { return true }
        if let today = progress.todaysChapter {
            return today.isCompleted
        }
        return progress.currentFocusChapter == nil && completedCount > 0
    }

    init(profile: ChildProfile) {
        self.profile = profile
        _progress = State(
            initialValue: DailyProgressManager(profileID: profile.id)
        )
        _practiceStore = State(
            initialValue: PracticeProgressStore(profileID: profile.id)
        )
        _stickerStore = State(
            initialValue: StickerBookStore(profileID: profile.id)
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isNarrow = LearningTheme.isNarrow(geo.size.width)
                let hPad = LearningTheme.screenPadding(for: geo.size.width)

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

                        DailyMissionCard(
                            chapterTitle: missionChapter?.title,
                            chapterDone: missionChapterDone,
                            practiceDone: practiceStore.hasPracticedToday,
                            bonusClaimed: practiceStore.missionBonusClaimedToday,
                            onPlayChapter: { openMissionChapter() },
                            onOpenLearn: { openLearnHub() }
                        )

                        worldsStrip(narrow: isNarrow, contentWidth: geo.size.width - hPad * 2)

                        playZones(narrow: isNarrow)

                        chapterPathHeader

                        AdventureMapView(
                            chapters: progress.chapters,
                            progress: progress,
                            avatarId: profile.avatarId
                        ) { chapter in
                            selectedLesson = ChapterRepository.lesson(
                                for: chapter,
                                ageYears: profile.ageInYears
                            )
                        }
                    }
                    .padding(.horizontal, hPad)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                    .frame(maxWidth: LearningTheme.contentMaxWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
                .background(PlayWorldBackground())
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: $selectedLesson) { lesson in
                    ChapterRunnerView(lesson: lesson) { coins in
                        withAnimation(LearningTheme.successBump) {
                            profile.totalCoins = min(profile.totalCoins + max(0, coins), 9_999)
                            progress.markCompleted(id: lesson.id)
                        }
                        markChapterDoneToday()
                        bumpStreakIfNeeded()
                        checkStickers()
                        claimMissionBonusIfNeeded()
                    }
                }
                .navigationDestination(item: $bonusDestination) { destination in
                    bonusDestinationView(destination)
                }
            }
        }
        .overlay {
            if showDailySpin {
                dailySpinOverlay
            }
            if let sticker = newlyUnlockedSticker {
                stickerUnlockOverlay(sticker)
            }
        }
        .onAppear {
            let stored = UserDefaults.standard.integer(forKey: streakStorageKey)
            if stored > 0 {
                streakDays = stored
            }
            refreshChapterDoneToday()
            progress.refreshSpinClaimIfNeeded()
            stickerStore.sync(completedCount: completedCount)
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
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Today's lesson")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 8)

                    ageBadge
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's lesson")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                    ageBadge
                }
            }

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
        .padding(narrow ? LearningTheme.cardPaddingNarrow : LearningTheme.cardPadding)
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

    private var ageBadge: some View {
        Text(ageBand.friendlyLabel)
            .font(.system(.caption, design: .rounded).weight(.heavy))
            .foregroundStyle(LearningTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule(style: .continuous)
                    .fill(LearningTheme.accentSoft)
            }
            .accessibilityLabel("Difficulty \(ageBand.friendlyLabel)")
    }

    // MARK: - Worlds strip

    private func worldsStrip(narrow: Bool, contentWidth: CGFloat) -> some View {
        let cardWidth = min(narrow ? 168 : 180, max(148, contentWidth * 0.72))

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Learning worlds", subtitle: "Chapter packs — finish one to unlock the next")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: narrow ? 10 : 12) {
                    ForEach(LearningWorld.allCases, id: \.self) { world in
                        worldCard(world, cardWidth: cardWidth)
                    }
                }
                .padding(.vertical, 2)
                .padding(.trailing, 8)
            }
            .scrollClipDisabled()
        }
    }

    private func worldCard(_ world: LearningWorld, cardWidth: CGFloat) -> some View {
        let chapters = progress.chapters.filter { world.dayRange.contains($0.dayNumber) }
        let done = chapters.filter(\.isCompleted).count
        let total = max(chapters.count, 1)
        let unlocked = chapters.contains { progress.isPlayable($0) }
        let isCurrent = chapters.contains { progress.isCurrentFocus($0) }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: world.symbolName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(unlocked ? world.tint : LearningTheme.mutedInk)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(unlocked ? world.tint.opacity(0.16) : LearningTheme.slot)
                    }

                if isCurrent {
                    Text("NOW")
                        .font(.system(.caption2, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(world.tint))
                }

                Spacer(minLength: 0)
            }

            Text(world.title)
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(world.subtitle)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            LessonProgressPips(
                total: total,
                completed: done,
                tint: world.tint
            )

            Text("\(done)/\(total) chapters")
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.mutedInk)
        }
        .padding(14)
        .frame(width: cardWidth, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.94))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            isCurrent ? world.tint.opacity(0.55) : world.tint.opacity(0.22),
                            lineWidth: isCurrent ? 3 : 2
                        )
                }
                .shadow(color: world.tint.opacity(isCurrent ? 0.18 : 0.08), radius: 10, y: 5)
        }
        .opacity(unlocked || done > 0 ? 1 : 0.72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(world.title), \(done) of \(total) chapters complete")
    }

    // MARK: - Play zones

    private func playZones(narrow: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Learn anytime", subtitle: "ABC, counting, words, songs, storybooks & tracing")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: narrow ? 10 : 14), GridItem(.flexible(), spacing: narrow ? 10 : 14)],
                spacing: narrow ? 10 : 14
            ) {
                bonusButton(title: "Letters", symbol: "textformat", tint: Color(red: 0.20, green: 0.55, blue: 0.90)) {
                    openLearnHub(.letters)
                }
                bonusButton(title: "Numbers", symbol: "number.circle.fill", tint: Color(red: 0.95, green: 0.45, blue: 0.55)) {
                    openLearnHub(.numbers)
                }
                bonusButton(title: "Words", symbol: "mouth.fill", tint: Color(red: 0.35, green: 0.72, blue: 0.55)) {
                    openLearnHub(.words)
                }
                bonusButton(title: "Songs", symbol: "music.note.list", tint: Color(red: 0.55, green: 0.40, blue: 0.78)) {
                    openLearnHub(.songs)
                }
                bonusButton(title: "Storybook", symbol: "moon.stars.fill", tint: Color(red: 0.28, green: 0.32, blue: 0.72)) {
                    openLearnHub(.storybook)
                }
                bonusButton(title: "Trace", symbol: "pencil.and.outline", tint: Color(red: 0.95, green: 0.55, blue: 0.25)) {
                    openLearnHub(.trace)
                }
            }

            sectionTitle("Feel good", subtitle: "Calm, dress up & celebrate")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: narrow ? 10 : 14), GridItem(.flexible(), spacing: narrow ? 10 : 14)],
                spacing: narrow ? 10 : 14
            ) {
                bonusButton(title: "Calm Corner", symbol: "wind", tint: LearningTheme.accent) {
                    bonusDestination = .calmCorner
                }
                bonusButton(title: "Pet Shop", symbol: "tshirt.fill", tint: LearningTheme.coral) {
                    bonusDestination = .petShop
                }
                bonusButton(title: "Stickers", symbol: "seal.fill", tint: Color(red: 0.55, green: 0.40, blue: 0.78)) {
                    bonusDestination = .stickerBook
                }
                bonusButton(title: "Daily Spin", symbol: "gift.fill", tint: LearningTheme.sunshine) {
                    withAnimation(LearningTheme.forgivingSpring) {
                        showDailySpin = true
                    }
                }
                bonusButton(title: "Parents", symbol: "figure.and.child.holdinghands", tint: LearningTheme.mutedInk) {
                    bonusDestination = .parentProgress
                }
            }

            sectionTitle("Quick play", subtitle: "Short sensory games anytime")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: narrow ? 10 : 14), GridItem(.flexible(), spacing: narrow ? 10 : 14)],
                spacing: narrow ? 10 : 14
            ) {
                bonusButton(title: "Bubble Pop", symbol: "bubbles.and.sparkles.fill", tint: LearningTheme.accent) {
                    bonusDestination = .bubblePop
                }
                bonusButton(title: "Patterns", symbol: "square.grid.3x3.fill", tint: Color(red: 0.42, green: 0.58, blue: 0.95)) {
                    bonusDestination = .patternConstructor
                }
                bonusButton(title: "Focus Pilot", symbol: "paperplane.fill", tint: LearningTheme.sunshine) {
                    bonusDestination = .focusPilot
                }
                bonusButton(title: "Rhythm Tap", symbol: "music.note", tint: LearningTheme.coral) {
                    bonusDestination = .rhythmTap
                }
                bonusButton(title: "Memory", symbol: "rectangle.on.rectangle.angled", tint: Color(red: 0.98, green: 0.55, blue: 0.20)) {
                    bonusDestination = .memoryMatch
                }
            }
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(subtitle)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chapterPathHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Chapter path")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
            Text("Each chapter has 3 short plays — warm-up, game, wrap-up")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .minimumScaleFactor(0.75)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
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

    // MARK: - Destinations

    @ViewBuilder
    private func bonusDestinationView(_ destination: BonusDestination) -> some View {
        switch destination {
        case .petShop:
            PetShopView(profile: profile, onClose: { bonusDestination = nil })
        case .bubblePop:
            BubblePopView(
                onRoundFinished: awardBonusCoins,
                onReturnToMap: { bonusDestination = nil }
            )
        case .patternConstructor:
            PatternConstructorView(
                onRoundFinished: awardBonusCoins,
                onReturnToMap: { bonusDestination = nil }
            )
        case .focusPilot:
            FocusPilotView(
                onRoundFinished: awardBonusCoins,
                onReturnToMap: { bonusDestination = nil }
            )
        case .calmCorner:
            CalmCornerView(onReturnToMap: { bonusDestination = nil })
        case .rhythmTap:
            RhythmTapView(
                onRoundFinished: awardBonusCoins,
                onReturnToMap: { bonusDestination = nil }
            )
        case .memoryMatch:
            MemoryMatchBonusView(
                pairCount: ageBand.memoryPairs,
                onRoundFinished: awardBonusCoins,
                onReturnToMap: { bonusDestination = nil }
            )
        case .stickerBook:
            StickerBookView(
                completedCount: completedCount,
                onClose: { bonusDestination = nil }
            )
        case .learnHub:
            LearnHubView(
                ageYears: profile.ageInYears,
                initialCategory: learnLaunchCategory,
                onPracticeFinished: { category, coins in
                    practiceStore.recordPractice(category: category)
                    awardBonusCoins(coins)
                    claimMissionBonusIfNeeded()
                },
                onClose: {
                    learnLaunchCategory = nil
                    bonusDestination = nil
                }
            )
        case .parentProgress:
            ParentProgressView(
                nickname: profile.nickname,
                ageBandLabel: ageBand.friendlyLabel,
                completedChapters: completedCount,
                totalChapters: progress.chapters.count,
                streakDays: streakDays,
                coinBalance: profile.totalCoins,
                practice: practiceStore,
                onClose: { bonusDestination = nil }
            )
        }
    }

    private func awardBonusCoins(_ coins: Int) {
        withAnimation(LearningTheme.successBump) {
            profile.totalCoins = min(profile.totalCoins + max(0, coins), 9_999)
        }
    }

    // MARK: - Overlays

    private var dailySpinOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(LearningTheme.forgivingSpring) {
                        showDailySpin = false
                    }
                }

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

    private func stickerUnlockOverlay(_ sticker: StickerBadge) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(LearningTheme.forgivingSpring) {
                        newlyUnlockedSticker = nil
                    }
                }

            VStack(spacing: 14) {
                Image(systemName: sticker.symbolName)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(sticker.tint)
                    .padding(18)
                    .background {
                        Circle().fill(sticker.tint.opacity(0.18))
                    }

                Text("New sticker!")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)

                Text(sticker.title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(sticker.tint)

                Text(sticker.subtitle)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation(LearningTheme.forgivingSpring) {
                        newlyUnlockedSticker = nil
                    }
                } label: {
                    Text("Yay!")
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
            .padding(22)
            .frame(maxWidth: 340)
            .background {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(LearningTheme.surface)
                    .shadow(color: .black.opacity(0.14), radius: 20, y: 10)
            }
            .padding(24)
            .transition(.scale(scale: 0.88).combined(with: .opacity))
        }
        .animation(LearningTheme.forgivingSpring, value: newlyUnlockedSticker?.id)
    }

    // MARK: - Helpers

    private var pathSubtitle: String {
        if let today = progress.todaysChapter, !today.isCompleted {
            return "Chapter \(today.dayNumber) · \(today.world.title) — 3 short plays await!"
        }
        if let focus = progress.currentFocusChapter {
            if progress.isEarlyUnlocked(focus) {
                return "Chapter \(focus.dayNumber) unlocked early — keep the streak going!"
            }
            return "Chapter \(focus.dayNumber) · \(focus.world.title) is ready to play!"
        }
        if completedCount == 0 {
            return "Follow the chapter path — each lesson has a warm-up, game & wrap-up!"
        }
        if completedCount >= progress.chapters.count {
            return "You cleared every chapter — amazing explorer!"
        }
        return "Great job! \(completedCount) of \(progress.chapters.count) chapters cleared."
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

    private func markChapterDoneToday() {
        let today = Calendar.current.startOfDay(for: .now).timeIntervalSince1970
        UserDefaults.standard.set(today, forKey: chapterDoneTodayKey)
        completedChapterToday = true
    }

    private func refreshChapterDoneToday() {
        let today = Calendar.current.startOfDay(for: .now).timeIntervalSince1970
        let stored = UserDefaults.standard.double(forKey: chapterDoneTodayKey)
        completedChapterToday = stored == today
    }

    private func openMissionChapter() {
        guard let chapter = missionChapter else { return }
        selectedLesson = ChapterRepository.lesson(
            for: chapter,
            ageYears: profile.ageInYears
        )
    }

    private func openLearnHub(_ category: LearnPracticeCategory? = nil) {
        learnLaunchCategory = category
        bonusDestination = .learnHub
    }

    private func claimMissionBonusIfNeeded() {
        let bonus = practiceStore.claimMissionBonusIfEligible(
            chapterDoneToday: missionChapterDone
        )
        guard bonus > 0 else { return }
        withAnimation(LearningTheme.successBump) {
            profile.totalCoins = min(profile.totalCoins + bonus, 9_999)
        }
        AudioHapticManager.shared.playSuccess()
    }

    private func checkStickers() {
        let fresh = stickerStore.sync(completedCount: progress.completedCount)
        if let first = fresh.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(LearningTheme.buddyBounce) {
                    newlyUnlockedSticker = first
                }
                AudioHapticManager.shared.playSuccess()
            }
        }
    }
}

// MARK: - Bonus destinations

private enum BonusDestination: String, Identifiable, Hashable {
    case petShop
    case bubblePop
    case patternConstructor
    case focusPilot
    case calmCorner
    case rhythmTap
    case memoryMatch
    case stickerBook
    case learnHub
    case parentProgress

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
