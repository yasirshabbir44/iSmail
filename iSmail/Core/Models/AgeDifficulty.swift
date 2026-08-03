//
//  AgeDifficulty.swift
//  iSmail
//
//  Tailors lesson complexity from the child's age (DOB on profile).
//

import Foundation

/// Soft difficulty bands for ADHD-friendly pacing.
enum AgeBand: String, Sendable {
    case little   // ~3–5
    case explorer // ~6–8
    case adventurer // 9+

    static func from(ageYears: Int) -> AgeBand {
        switch ageYears {
        case ...5: return .little
        case 6...8: return .explorer
        default: return .adventurer
        }
    }

    /// How many choices / cards feel comfortable.
    var choiceCount: Int {
        switch self {
        case .little: return 3
        case .explorer: return 4
        case .adventurer: return 5
        }
    }

    /// Memory-match pair count.
    var memoryPairs: Int {
        switch self {
        case .little: return 3
        case .explorer: return 4
        case .adventurer: return 6
        }
    }

    /// Sequence length preference.
    var sequenceLength: Int {
        switch self {
        case .little: return 3
        case .explorer: return 4
        case .adventurer: return 5
        }
    }

    var friendlyLabel: String {
        switch self {
        case .little: return "Little Explorer"
        case .explorer: return "Curious Explorer"
        case .adventurer: return "Brave Adventurer"
        }
    }
}
