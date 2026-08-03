//
//  ChapterNode.swift
//  iSmail
//
//  Daily adventure-map chapter model — one unlockable node per calendar day.
//

import Foundation

/// A single calendar-gated lesson island on the adventure path.
struct ChapterNode: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    /// 1-based day index along the campaign path.
    var dayNumber: Int
    var title: String
    var type: ActivityType
    /// Local midnight of the unlock calendar day.
    var unlockDate: Date
    var isCompleted: Bool
    /// Treasure-chest milestone — every 5th node.
    var isChestReward: Bool
    var rewardCoins: Int

    init(
        id: UUID = UUID(),
        dayNumber: Int,
        title: String,
        type: ActivityType,
        unlockDate: Date,
        isCompleted: Bool = false,
        isChestReward: Bool = false,
        rewardCoins: Int = 5
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.title = title
        self.type = type
        self.unlockDate = unlockDate
        self.isCompleted = isCompleted
        self.isChestReward = isChestReward
        self.rewardCoins = max(0, rewardCoins)
    }
}

/// Visual / interaction status derived from calendar + completion.
enum ChapterNodeStatus: Equatable, Sendable {
    /// Child finished this chapter (green checkmark).
    case completed
    /// Unlocks today and is not yet completed (pulse + floating avatar).
    case activeToday
    /// Unlock day is in the past and not completed (playable, no today pulse).
    case available
    /// Unlock day is still in the future (lock + cloud + countdown).
    case lockedFuture
}
