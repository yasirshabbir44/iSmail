//
//  TaskNode.swift
//  iSmail
//
//  Unified learning-task model for the Core Learning Engine.
//

import Foundation

/// A single interactive learning unit the runner can present.
struct TaskNode: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var prompt: String
    var activityType: ActivityType
    var payload: ActivityPayload
    /// Coins awarded to the child's token balance on completion.
    var rewardCoins: Int

    init(
        id: UUID = UUID(),
        title: String,
        prompt: String,
        activityType: ActivityType,
        payload: ActivityPayload,
        rewardCoins: Int = 5
    ) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.activityType = activityType
        self.payload = payload
        self.rewardCoins = max(0, rewardCoins)
    }
}

// MARK: - Payload

/// Type-safe content for each activity kind.
enum ActivityPayload: Hashable, Sendable {
    case dragAndDrop(DragAndDropContent)
    case tapAndSelect(TapAndSelectContent)
    case sequenceOrder(SequenceOrderContent)
}

// MARK: - Drag & Drop

struct DragAndDropContent: Hashable, Sendable {
    var items: [DragItem]
    var zones: [DropZone]
}

struct DragItem: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var symbolName: String
    /// Must match a `DropZone.matchKey` for a correct drop.
    var matchKey: String

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String,
        matchKey: String
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
        self.matchKey = matchKey
    }
}

struct DropZone: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var symbolName: String
    var matchKey: String

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String,
        matchKey: String
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
        self.matchKey = matchKey
    }
}

// MARK: - Tap & Select

struct TapAndSelectContent: Hashable, Sendable {
    var choices: [SelectChoice]
    /// ID of the correct choice.
    var correctChoiceID: UUID
}

struct SelectChoice: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var symbolName: String

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
    }
}

// MARK: - Sequence Order

struct SequenceOrderContent: Hashable, Sendable {
    /// Items shown in a shuffled starting order (3–5 recommended).
    var items: [SequenceItem]
    /// Correct order by item IDs from first → last.
    var correctOrder: [UUID]
}

struct SequenceItem: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var symbolName: String
    var stepNumber: Int

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String,
        stepNumber: Int
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
        self.stepNumber = stepNumber
    }
}
