//
//  ChapterLesson.swift
//  iSmail
//
//  Multi-step chapter lesson — warm-up → play → wrap-up (LingoKids-style).
//

import Foundation

/// A full chapter with several short activities kids complete in order.
struct ChapterLesson: Identifiable, Hashable, Sendable {
    let id: UUID
    var dayNumber: Int
    var title: String
    var subtitle: String
    var world: LearningWorld
    var skillTag: String
    /// Primary activity type shown on the map node.
    var primaryType: ActivityType
    var steps: [LessonStep]
    var rewardCoins: Int
    var isChestReward: Bool

    var stepCount: Int { steps.count }

    init(
        id: UUID,
        dayNumber: Int,
        title: String,
        subtitle: String,
        world: LearningWorld,
        skillTag: String,
        primaryType: ActivityType,
        steps: [LessonStep],
        rewardCoins: Int,
        isChestReward: Bool = false
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.title = title
        self.subtitle = subtitle
        self.world = world
        self.skillTag = skillTag
        self.primaryType = primaryType
        self.steps = steps
        self.rewardCoins = max(0, rewardCoins)
        self.isChestReward = isChestReward
    }
}

/// One playable beat inside a chapter.
struct LessonStep: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var task: TaskNode

    init(id: UUID = UUID(), label: String, task: TaskNode) {
        self.id = id
        self.label = label
        self.task = task
    }
}
