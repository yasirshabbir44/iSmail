//
//  StickerBookStore.swift
//  iSmail
//
//  Collectible stickers unlocked by play milestones — dopamine-friendly progress.
//

import Foundation
import SwiftUI

struct StickerBadge: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let tintRed: Double
    let tintGreen: Double
    let tintBlue: Double
    let requiredCompletions: Int

    var tint: Color {
        Color(red: tintRed, green: tintGreen, blue: tintBlue)
    }
}

enum StickerCatalog {
    static let all: [StickerBadge] = [
        StickerBadge(
            id: "first_star",
            title: "First Star",
            subtitle: "Finished your first lesson",
            symbolName: "star.fill",
            tintRed: 1.0, tintGreen: 0.78, tintBlue: 0.22,
            requiredCompletions: 1
        ),
        StickerBadge(
            id: "focus_friend",
            title: "Focus Friend",
            subtitle: "3 lessons completed",
            symbolName: "lightbulb.fill",
            tintRed: 0.08, tintGreen: 0.62, tintBlue: 0.68,
            requiredCompletions: 3
        ),
        StickerBadge(
            id: "story_lover",
            title: "Story Lover",
            subtitle: "5 islands cleared",
            symbolName: "book.fill",
            tintRed: 0.98, tintGreen: 0.45, tintBlue: 0.38,
            requiredCompletions: 5
        ),
        StickerBadge(
            id: "streak_spark",
            title: "Streak Spark",
            subtitle: "Keep showing up",
            symbolName: "flame.fill",
            tintRed: 0.98, tintGreen: 0.55, tintBlue: 0.20,
            requiredCompletions: 7
        ),
        StickerBadge(
            id: "path_hero",
            title: "Path Hero",
            subtitle: "10 islands cleared",
            symbolName: "flag.fill",
            tintRed: 0.42, tintGreen: 0.58, tintBlue: 0.95,
            requiredCompletions: 10
        ),
        StickerBadge(
            id: "world_champ",
            title: "World Champ",
            subtitle: "Cleared the whole path",
            symbolName: "trophy.fill",
            tintRed: 0.55, tintGreen: 0.40, tintBlue: 0.78,
            requiredCompletions: 15
        )
    ]
}

@MainActor
final class StickerBookStore {
    private let profileID: UUID
    private let defaults: UserDefaults

    private var unlockedKey: String {
        "stickers.unlocked.\(profileID.uuidString)"
    }

    init(profileID: UUID, defaults: UserDefaults = .standard) {
        self.profileID = profileID
        self.defaults = defaults
    }

    func unlockedIDs() -> Set<String> {
        Set(defaults.stringArray(forKey: unlockedKey) ?? [])
    }

    /// Unlocks any stickers newly earned from `completedCount`. Returns freshly unlocked badges.
    @discardableResult
    func sync(completedCount: Int) -> [StickerBadge] {
        var unlocked = unlockedIDs()
        var freshly: [StickerBadge] = []
        for badge in StickerCatalog.all where completedCount >= badge.requiredCompletions {
            if unlocked.insert(badge.id).inserted {
                freshly.append(badge)
            }
        }
        defaults.set(Array(unlocked), forKey: unlockedKey)
        return freshly
    }

    func isUnlocked(_ id: String) -> Bool {
        unlockedIDs().contains(id)
    }

    static func clear(for profileID: UUID, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: "stickers.unlocked.\(profileID.uuidString)")
    }
}
