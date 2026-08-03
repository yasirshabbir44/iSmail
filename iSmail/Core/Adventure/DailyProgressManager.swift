//
//  DailyProgressManager.swift
//  iSmail
//
//  Calendar-aware chapter unlock status + daily spin claim persistence.
//

import Foundation
import Observation

/// Owns the live chapter path for one child and derives node status from `Calendar.current`.
@Observable
@MainActor
final class DailyProgressManager {
    private let profileID: UUID
    private let calendar: Calendar
    private let defaults: UserDefaults

    private(set) var chapters: [ChapterNode]
    /// Resets each local calendar day — gates the Daily Spin modal.
    private(set) var hasClaimedDailySpin: Bool

    private var completedKey: String { "adventure.completed.\(profileID.uuidString)" }
    private var spinClaimedDayKey: String { "adventure.dailySpinDay.\(profileID.uuidString)" }

    init(
        profileID: UUID,
        chapterCount: Int = ChapterRepository.defaultChapterCount,
        calendar: Calendar = .current,
        defaults: UserDefaults = .standard
    ) {
        self.profileID = profileID
        self.calendar = calendar
        self.defaults = defaults

        // Campaign anchors to first launch of the daily engine.
        let start = Self.resolvedCampaignStart(
            profileID: profileID,
            calendar: calendar,
            defaults: defaults
        )
        let completedKey = "adventure.completed.\(profileID.uuidString)"
        let spinKey = "adventure.dailySpinDay.\(profileID.uuidString)"
        let completed = Self.loadCompletedIDs(key: completedKey, defaults: defaults)
        self.chapters = ChapterRepository.chapters(
            startingFrom: start,
            count: chapterCount,
            calendar: calendar,
            completedIDs: completed
        )
        self.hasClaimedDailySpin = Self.loadSpinClaimedToday(
            key: spinKey,
            calendar: calendar,
            defaults: defaults
        )
    }

    // MARK: - Status

    /// Applies the daily unlock rules against `Calendar.current`.
    func status(for node: ChapterNode, now: Date = .now) -> ChapterNodeStatus {
        if node.isCompleted {
            return .completed
        }
        if calendar.isDateInToday(node.unlockDate) {
            return .activeToday
        }
        // Future midnight is still strictly after "now" until that day begins.
        if node.unlockDate > now {
            return .lockedFuture
        }
        return .available
    }

    /// Map-node visual state used by `MapNodeView`.
    func mapState(for node: ChapterNode, now: Date = .now) -> MapNodeState {
        switch status(for: node, now: now) {
        case .completed: return .completed
        case .activeToday, .available: return .active
        case .lockedFuture: return .locked
        }
    }

    /// True when the node may open a lesson preview.
    func isPlayable(_ node: ChapterNode, now: Date = .now) -> Bool {
        switch status(for: node, now: now) {
        case .completed, .activeToday, .available: return true
        case .lockedFuture: return false
        }
    }

    /// Kid-friendly countdown under locked future nodes.
    func countdownLabel(for node: ChapterNode, now: Date = .now) -> String? {
        guard status(for: node, now: now) == .lockedFuture else { return nil }

        if calendar.isDateInTomorrow(node.unlockDate) {
            return "Tomorrow"
        }

        let startToday = calendar.startOfDay(for: now)
        let startUnlock = calendar.startOfDay(for: node.unlockDate)
        let days = calendar.dateComponents([.day], from: startToday, to: startUnlock).day ?? 0
        if days > 1 {
            return "\(days) days"
        }

        // Same calendar day edge cases / clock skew — show hours remaining.
        let hours = max(1, calendar.dateComponents([.hour], from: now, to: node.unlockDate).hour ?? 1)
        return hours == 1 ? "1 hr" : "\(hours) hrs"
    }

    var todaysChapter: ChapterNode? {
        chapters.first { calendar.isDateInToday($0.unlockDate) }
    }

    var completedCount: Int {
        chapters.filter(\.isCompleted).count
    }

    // MARK: - Mutations

    func markCompleted(id: UUID) {
        guard let index = chapters.firstIndex(where: { $0.id == id }) else { return }
        chapters[index].isCompleted = true
        persistCompletedIDs()
    }

    /// Awards spin coins and marks today's spin claimed.
    @discardableResult
    func claimDailySpin(rewardCoins: Int) -> Int {
        hasClaimedDailySpin = true
        let today = calendar.startOfDay(for: .now).timeIntervalSince1970
        defaults.set(today, forKey: spinClaimedDayKey)
        return max(0, rewardCoins)
    }

    func refreshSpinClaimIfNeeded() {
        hasClaimedDailySpin = Self.loadSpinClaimedToday(
            key: spinClaimedDayKey,
            calendar: calendar,
            defaults: defaults
        )
    }

    // MARK: - Persistence

    private func persistCompletedIDs() {
        let ids = chapters.filter(\.isCompleted).map(\.id.uuidString)
        defaults.set(ids, forKey: completedKey)
    }

    private static func loadCompletedIDs(key: String, defaults: UserDefaults) -> Set<UUID> {
        let raw = defaults.stringArray(forKey: key) ?? []
        return Set(raw.compactMap(UUID.init(uuidString:)))
    }

    private static func loadSpinClaimedToday(
        key: String,
        calendar: Calendar,
        defaults: UserDefaults
    ) -> Bool {
        let stored = defaults.double(forKey: key)
        guard stored > 0 else { return false }
        let storedDay = Date(timeIntervalSince1970: stored)
        return calendar.isDateInToday(storedDay)
    }

    private static func resolvedCampaignStart(
        profileID: UUID,
        calendar: Calendar,
        defaults: UserDefaults
    ) -> Date {
        let key = "adventure.campaignStart.\(profileID.uuidString)"
        let stored = defaults.double(forKey: key)
        if stored > 0 {
            return calendar.startOfDay(for: Date(timeIntervalSince1970: stored))
        }
        // Prefer "today" so the drip starts now instead of unlocking a backlog.
        let start = calendar.startOfDay(for: .now)
        defaults.set(start.timeIntervalSince1970, forKey: key)
        return start
    }
}
