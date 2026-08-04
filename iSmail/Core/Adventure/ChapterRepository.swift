//
//  ChapterRepository.swift
//  iSmail
//
//  Themed multi-step chapter catalog — one new chapter unlocks each calendar day.
//

import CryptoKit
import Foundation

/// Builds the rolling daily chapter path and resolves playable `ChapterLesson` content.
enum ChapterRepository: Sendable {
    /// Default campaign length shown on the winding map.
    nonisolated static let defaultChapterCount = 21

    private struct CatalogEntry {
        let title: String
        let subtitle: String
        let type: ActivityType
        let coins: Int
        let stepCount: Int
    }

    private static let catalog: [CatalogEntry] = [
        CatalogEntry(title: "Animal Sounds", subtitle: "Meet animal pals and match their sounds", type: .dragAndDrop, coins: 12, stepCount: 3),
        CatalogEntry(title: "Fruit Friends", subtitle: "Find fruits and match sunny colors", type: .tapAndSelect, coins: 12, stepCount: 3),
        CatalogEntry(title: "Pet Homes", subtitle: "Help every pet find a cozy home", type: .dragAndDrop, coins: 12, stepCount: 3),
        CatalogEntry(title: "Color World", subtitle: "Colors, shapes, and morning routines", type: .dragAndDrop, coins: 12, stepCount: 3),
        CatalogEntry(title: "Morning Star", subtitle: "Start the day with stars and steps", type: .sequenceOrder, coins: 15, stepCount: 3),
        CatalogEntry(title: "Cozy Bedtime", subtitle: "A calm bedtime from bath to sleep", type: .sequenceOrder, coins: 12, stepCount: 3),
        CatalogEntry(title: "Snack Heroes", subtitle: "Healthy snacks and happy choices", type: .tapAndSelect, coins: 12, stepCount: 3),
        CatalogEntry(title: "Ready, Go!", subtitle: "Getting ready to go out into the world", type: .sequenceOrder, coins: 12, stepCount: 3),
        CatalogEntry(title: "Big Feelings", subtitle: "Name feelings and cheer for friends", type: .tapAndSelect, coins: 12, stepCount: 3),
        CatalogEntry(title: "Brave Little Fox", subtitle: "A brave fox story and forest friends", type: .storyTime, coins: 18, stepCount: 3),
        CatalogEntry(title: "Weather Day", subtitle: "Match weather to what you might need", type: .dragAndDrop, coins: 12, stepCount: 3),
        CatalogEntry(title: "Park Adventure", subtitle: "Pack, play, snack — a perfect park day", type: .sequenceOrder, coins: 12, stepCount: 3),
        CatalogEntry(title: "Memory Garden", subtitle: "Flip cards in a blooming memory garden", type: .memoryMatch, coins: 12, stepCount: 3),
        CatalogEntry(title: "Kind Wishes", subtitle: "Practice kindness before the finale", type: .storyTime, coins: 12, stepCount: 3),
        CatalogEntry(title: "Star Wish", subtitle: "The big star-wish story — you made it!", type: .storyTime, coins: 20, stepCount: 3),
        CatalogEntry(title: "Letter A Hunt", subtitle: "Find A and say its friendly sound", type: .letterHunt, coins: 14, stepCount: 3),
        CatalogEntry(title: "Letter Friends", subtitle: "Hunt B, C & D with phonics tips", type: .letterHunt, coins: 14, stepCount: 3),
        CatalogEntry(title: "Word Whispers", subtitle: "Speak everyday words out loud", type: .speakAndSay, coins: 15, stepCount: 3),
        CatalogEntry(title: "Count to Three", subtitle: "Count stars, hearts & apples", type: .countTap, coins: 14, stepCount: 3),
        CatalogEntry(title: "Number Party", subtitle: "Bigger counts and number choices", type: .countTap, coins: 14, stepCount: 3),
        CatalogEntry(title: "Math Stars", subtitle: "Count, speak & celebrate Number Town", type: .countTap, coins: 20, stepCount: 3)
    ]

    /// Generates `count` chapters starting at local midnight of `startDate`.
    static func chapters(
        startingFrom startDate: Date,
        count: Int = defaultChapterCount,
        calendar: Calendar = .current,
        completedIDs: Set<UUID> = []
    ) -> [ChapterNode] {
        let start = calendar.startOfDay(for: startDate)
        let total = max(1, count)

        return (0..<total).map { index in
            let dayNumber = index + 1
            let entry = catalog[index % catalog.count]
            let unlock = calendar.date(byAdding: .day, value: index, to: start) ?? start
            let id = deterministicID(dayNumber: dayNumber, start: start)
            let isChest = dayNumber.isMultiple(of: 5)
            let coins = isChest ? max(entry.coins, 18) : entry.coins
            let world = LearningWorld.world(forDay: dayNumber)

            return ChapterNode(
                id: id,
                dayNumber: dayNumber,
                title: isChest ? "\(entry.title) Chest" : entry.title,
                subtitle: entry.subtitle,
                world: world,
                type: entry.type,
                stepCount: entry.stepCount,
                unlockDate: unlock,
                isCompleted: completedIDs.contains(id),
                isChestReward: isChest,
                rewardCoins: coins
            )
        }
    }

    /// Maps a chapter to a full multi-step lesson, tailored by age.
    static func lesson(for chapter: ChapterNode, ageYears: Int = 6) -> ChapterLesson {
        CurriculumCatalog.lesson(for: chapter, ageYears: ageYears)
    }

    /// Legacy single-task resolve.
    static func task(for chapter: ChapterNode, ageYears: Int = 6) -> TaskNode {
        CurriculumCatalog.task(for: chapter, ageYears: ageYears)
    }

    // MARK: - Deterministic IDs

    private static func deterministicID(dayNumber: Int, start: Date) -> UUID {
        let stamp = Int(start.timeIntervalSince1970)
        let seed = "iSmail.chapter.\(stamp).\(dayNumber)"
        let digest = Insecure.SHA1.hash(data: Data(seed.utf8))
        var bytes = Array(digest.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50 // version 5
        bytes[8] = (bytes[8] & 0x3F) | 0x80 // RFC 4122 variant
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
