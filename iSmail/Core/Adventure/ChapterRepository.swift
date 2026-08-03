//
//  ChapterRepository.swift
//  iSmail
//
//  Dynamic chapter catalog — one new chapter unlocks each calendar day.
//

import CryptoKit
import Foundation

/// Builds the rolling daily chapter path and resolves playable `TaskNode` content.
enum ChapterRepository: Sendable {
    /// Default campaign length shown on the winding map.
    nonisolated static let defaultChapterCount = 15

    private static let catalog: [(title: String, type: ActivityType, coins: Int)] = [
        ("Animal Sounds", .dragAndDrop, 5),
        ("Pick the Fruit", .tapAndSelect, 6),
        ("Morning Steps", .sequenceOrder, 7),
        ("Color Match", .dragAndDrop, 5),
        ("Find the Shape", .tapAndSelect, 6),
        ("Bedtime Order", .sequenceOrder, 7),
        ("Pet Pals", .dragAndDrop, 5),
        ("Snack Time", .tapAndSelect, 6),
        ("Get Ready", .sequenceOrder, 7),
        ("Sound Safari", .dragAndDrop, 8),
        ("Pick a Flower", .tapAndSelect, 6),
        ("Park Day Steps", .sequenceOrder, 7),
        ("Toy Sort", .dragAndDrop, 5),
        ("Guess the Fruit", .tapAndSelect, 6),
        ("Morning Quest", .sequenceOrder, 8)
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
            let coins = isChest ? max(entry.coins, 15) : entry.coins

            return ChapterNode(
                id: id,
                dayNumber: dayNumber,
                title: isChest ? "\(entry.title) Chest" : entry.title,
                type: entry.type,
                unlockDate: unlock,
                isCompleted: completedIDs.contains(id),
                isChestReward: isChest,
                rewardCoins: coins
            )
        }
    }

    /// Maps a chapter to a runnable learning task (cycled sample payloads).
    static func task(for chapter: ChapterNode) -> TaskNode {
        let samples = TaskNode.chapter2Samples
        let sample = samples.first { $0.activityType == chapter.type } ?? samples[0]

        return TaskNode(
            id: chapter.id,
            title: chapter.title,
            prompt: sample.prompt,
            activityType: chapter.type,
            payload: sample.payload,
            rewardCoins: chapter.rewardCoins
        )
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
