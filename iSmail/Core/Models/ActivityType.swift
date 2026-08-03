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

    var displayName: String {
        switch self {
        case .dragAndDrop: "Match"
        case .tapAndSelect: "Choose"
        case .sequenceOrder: "Order"
        }
    }

    var systemImage: String {
        switch self {
        case .dragAndDrop: "hand.draw.fill"
        case .tapAndSelect: "hand.tap.fill"
        case .sequenceOrder: "arrow.left.arrow.right"
        }
    }
}
