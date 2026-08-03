//
//  LearningWorld.swift
//  iSmail
//
//  Themed learning worlds — LingoKids-style subject packs that group chapters.
//

import SwiftUI

/// A themed pack of chapters kids progress through on the adventure path.
enum LearningWorld: String, CaseIterable, Codable, Hashable, Sendable {
    case animalFriends
    case dailyLife
    case feelings
    case nature
    case storyStars

    var title: String {
        switch self {
        case .animalFriends: "Animal Friends"
        case .dailyLife: "Daily Life"
        case .feelings: "Feelings"
        case .nature: "Nature"
        case .storyStars: "Story Stars"
        }
    }

    var subtitle: String {
        switch self {
        case .animalFriends: "Sounds, pets & cozy homes"
        case .dailyLife: "Routines, snacks & getting ready"
        case .feelings: "Happy hearts & kind wishes"
        case .nature: "Weather, park days & gardens"
        case .storyStars: "Brave foxes & twinkling stars"
        }
    }

    var symbolName: String {
        switch self {
        case .animalFriends: "pawprint.fill"
        case .dailyLife: "house.fill"
        case .feelings: "heart.fill"
        case .nature: "leaf.fill"
        case .storyStars: "sparkles"
        }
    }

    /// Inclusive 1-based day range covered by this world.
    var dayRange: ClosedRange<Int> {
        switch self {
        case .animalFriends: 1...3
        case .dailyLife: 4...6
        case .feelings: 7...9
        case .nature: 10...12
        case .storyStars: 13...15
        }
    }

    var tint: Color {
        switch self {
        case .animalFriends: LearningTheme.coral
        case .dailyLife: LearningTheme.accent
        case .feelings: Color(red: 0.55, green: 0.40, blue: 0.78)
        case .nature: LearningTheme.success
        case .storyStars: LearningTheme.sunshine
        }
    }

    static func world(forDay dayNumber: Int) -> LearningWorld {
        allCases.first { $0.dayRange.contains(dayNumber) } ?? .animalFriends
    }
}
