//
//  ActivityType.swift
//  iSmail
//
//  Core Learning Engine — activity kind discriminator.
//

import Foundation

/// The interactive activity rendered by `ActivityRunnerView`.
enum ActivityType: String, Codable, CaseIterable, Hashable, Sendable {
    case dragAndDrop
    case tapAndSelect
    case sequenceOrder
    case storyTime
    case memoryMatch

    var displayName: String {
        switch self {
        case .dragAndDrop: "Match"
        case .tapAndSelect: "Choose"
        case .sequenceOrder: "Order"
        case .storyTime: "Story"
        case .memoryMatch: "Memory"
        }
    }

    var systemImage: String {
        switch self {
        case .dragAndDrop: "hand.draw.fill"
        case .tapAndSelect: "hand.tap.fill"
        case .sequenceOrder: "arrow.left.arrow.right"
        case .storyTime: "book.fill"
        case .memoryMatch: "rectangle.on.rectangle.angled"
        }
    }

    /// Short skill tag for parents / badge system.
    var skillTag: String {
        switch self {
        case .dragAndDrop: "Matching"
        case .tapAndSelect: "Focus"
        case .sequenceOrder: "Sequencing"
        case .storyTime: "Listening"
        case .memoryMatch: "Working memory"
        }
    }
}
