//
//  PracticeProgressStore.swift
//  iSmail
//
//  Tracks daily Learn Hub practice for missions & parent reports.
//

import Foundation
import Observation

@Observable
@MainActor
final class PracticeProgressStore {
    private let profileID: UUID
    private let defaults: UserDefaults
    private let calendar: Calendar

    private(set) var practiceCountToday: Int
    private(set) var lettersPlayed: Int
    private(set) var numbersPlayed: Int
    private(set) var wordsPlayed: Int
    private(set) var songsPlayed: Int
    private(set) var storybooksPlayed: Int
    private(set) var tracePlayed: Int
    private(set) var missionBonusClaimedToday: Bool

    private var dayKey: String { "learn.practiceDay.\(profileID.uuidString)" }
    private var countKey: String { "learn.practiceCount.\(profileID.uuidString)" }
    private var lettersKey: String { "learn.letters.\(profileID.uuidString)" }
    private var numbersKey: String { "learn.numbers.\(profileID.uuidString)" }
    private var wordsKey: String { "learn.words.\(profileID.uuidString)" }
    private var songsKey: String { "learn.songs.\(profileID.uuidString)" }
    private var storybooksKey: String { "learn.storybooks.\(profileID.uuidString)" }
    private var traceKey: String { "learn.trace.\(profileID.uuidString)" }
    private var bonusKey: String { "learn.missionBonusDay.\(profileID.uuidString)" }

    init(
        profileID: UUID,
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.profileID = profileID
        self.defaults = defaults
        self.calendar = calendar

        let todayStamp = Self.dayStamp(calendar: calendar)
        let storedDay = defaults.double(forKey: "learn.practiceDay.\(profileID.uuidString)")

        if storedDay == todayStamp {
            practiceCountToday = defaults.integer(forKey: "learn.practiceCount.\(profileID.uuidString)")
            lettersPlayed = defaults.integer(forKey: "learn.letters.\(profileID.uuidString)")
            numbersPlayed = defaults.integer(forKey: "learn.numbers.\(profileID.uuidString)")
            wordsPlayed = defaults.integer(forKey: "learn.words.\(profileID.uuidString)")
            songsPlayed = defaults.integer(forKey: "learn.songs.\(profileID.uuidString)")
            storybooksPlayed = defaults.integer(forKey: "learn.storybooks.\(profileID.uuidString)")
            tracePlayed = defaults.integer(forKey: "learn.trace.\(profileID.uuidString)")
            missionBonusClaimedToday = defaults.double(forKey: "learn.missionBonusDay.\(profileID.uuidString)") == todayStamp
        } else {
            practiceCountToday = 0
            lettersPlayed = 0
            numbersPlayed = 0
            wordsPlayed = 0
            songsPlayed = 0
            storybooksPlayed = 0
            tracePlayed = 0
            missionBonusClaimedToday = false
            defaults.set(todayStamp, forKey: "learn.practiceDay.\(profileID.uuidString)")
            defaults.set(0, forKey: "learn.practiceCount.\(profileID.uuidString)")
            defaults.set(0, forKey: "learn.letters.\(profileID.uuidString)")
            defaults.set(0, forKey: "learn.numbers.\(profileID.uuidString)")
            defaults.set(0, forKey: "learn.words.\(profileID.uuidString)")
            defaults.set(0, forKey: "learn.songs.\(profileID.uuidString)")
            defaults.set(0, forKey: "learn.storybooks.\(profileID.uuidString)")
            defaults.set(0, forKey: "learn.trace.\(profileID.uuidString)")
        }
    }

    var hasPracticedToday: Bool { practiceCountToday > 0 }

    func recordPractice(category: LearnPracticeCategory) {
        refreshDayIfNeeded()
        practiceCountToday += 1
        switch category {
        case .letters: lettersPlayed += 1
        case .numbers: numbersPlayed += 1
        case .words: wordsPlayed += 1
        case .songs: songsPlayed += 1
        case .storybook: storybooksPlayed += 1
        case .trace: tracePlayed += 1
        }
        persist()
    }

    /// Returns bonus coins when chapter + practice are done and bonus not yet claimed.
    @discardableResult
    func claimMissionBonusIfEligible(chapterDoneToday: Bool) -> Int {
        refreshDayIfNeeded()
        guard chapterDoneToday, hasPracticedToday, !missionBonusClaimedToday else { return 0 }
        missionBonusClaimedToday = true
        defaults.set(Self.dayStamp(calendar: calendar), forKey: bonusKey)
        return 8
    }

    private func refreshDayIfNeeded() {
        let today = Self.dayStamp(calendar: calendar)
        let stored = defaults.double(forKey: dayKey)
        guard stored != today else { return }
        practiceCountToday = 0
        lettersPlayed = 0
        numbersPlayed = 0
        wordsPlayed = 0
        songsPlayed = 0
        storybooksPlayed = 0
        tracePlayed = 0
        missionBonusClaimedToday = false
        defaults.set(today, forKey: dayKey)
        defaults.set(0, forKey: countKey)
        defaults.set(0, forKey: lettersKey)
        defaults.set(0, forKey: numbersKey)
        defaults.set(0, forKey: wordsKey)
        defaults.set(0, forKey: songsKey)
        defaults.set(0, forKey: storybooksKey)
        defaults.set(0, forKey: traceKey)
    }

    private func persist() {
        defaults.set(practiceCountToday, forKey: countKey)
        defaults.set(lettersPlayed, forKey: lettersKey)
        defaults.set(numbersPlayed, forKey: numbersKey)
        defaults.set(wordsPlayed, forKey: wordsKey)
        defaults.set(songsPlayed, forKey: songsKey)
        defaults.set(storybooksPlayed, forKey: storybooksKey)
        defaults.set(tracePlayed, forKey: traceKey)
    }

    private static func dayStamp(calendar: Calendar) -> Double {
        calendar.startOfDay(for: .now).timeIntervalSince1970
    }
}
