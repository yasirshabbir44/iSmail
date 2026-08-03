//
//  ChapterNode.swift
//  iSmail
//
//  Adventure-map chapter model — themed multi-step lesson island.
//

import Foundation

/// A single unlockable chapter island on the adventure path.
struct ChapterNode: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    /// 1-based day index along the campaign path.
    var dayNumber: Int
    var title: String
    var subtitle: String
    var world: LearningWorld
    var type: ActivityType
    /// How many play activities are inside this chapter.
    var stepCount: Int
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
        subtitle: String = "",
        world: LearningWorld = .animalFriends,
        type: ActivityType,
        stepCount: Int = 3,
        unlockDate: Date,
        isCompleted: Bool = false,
        isChestReward: Bool = false,
        rewardCoins: Int = 5
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.title = title
        self.subtitle = subtitle
        self.world = world
        self.type = type
        self.stepCount = max(1, stepCount)
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
