//
//  ShopItem.swift
//  iSmail
//
//  Cosmetic wardrobe for the buddy mascot — hats, glasses, accessories.
//

import Foundation
import SwiftUI

enum ShopItemCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case hat
    case glasses
    case accessory

    var displayName: String {
        switch self {
        case .hat: return "Hats"
        case .glasses: return "Glasses"
        case .accessory: return "Extras"
        }
    }

    var tint: Color {
        switch self {
        case .hat: return LearningTheme.coral
        case .glasses: return LearningTheme.accent
        case .accessory: return LearningTheme.sunshine
        }
    }
}

struct ShopItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let category: ShopItemCategory
    let costCoins: Int
    var isUnlocked: Bool
    /// SF Symbol used to render the wearable on the mascot canvas.
    let assetName: String
}

// MARK: - Catalog

enum ShopCatalog {
    /// Base catalog — unlock / equip state is applied per profile at runtime.
    static let all: [ShopItem] = [
        ShopItem(id: "hat_party", name: "Party Hat", category: .hat,
                 costCoins: 40, isUnlocked: false, assetName: "party.popper.fill"),
        ShopItem(id: "hat_crown", name: "Crown", category: .hat,
                 costCoins: 80, isUnlocked: false, assetName: "crown.fill"),
        ShopItem(id: "hat_cap", name: "Sunny Cap", category: .hat,
                 costCoins: 55, isUnlocked: false, assetName: "graduationcap.fill"),
        ShopItem(id: "glasses_star", name: "Star Specs", category: .glasses,
                 costCoins: 45, isUnlocked: false, assetName: "eyeglasses"),
        ShopItem(id: "glasses_cool", name: "Cool Shades", category: .glasses,
                 costCoins: 70, isUnlocked: false, assetName: "sunglasses"),
        ShopItem(id: "acc_bow", name: "Gift Bow", category: .accessory,
                 costCoins: 35, isUnlocked: false, assetName: "gift.fill"),
        ShopItem(id: "acc_sparkle", name: "Sparkle", category: .accessory,
                 costCoins: 60, isUnlocked: false, assetName: "sparkles"),
        ShopItem(id: "acc_heart", name: "Heart Pin", category: .accessory,
                 costCoins: 50, isUnlocked: false, assetName: "heart.fill")
    ]

    static func item(id: String) -> ShopItem? {
        all.first { $0.id == id }
    }
}

// MARK: - Per-profile wardrobe persistence

@Observable
@MainActor
final class PetWardrobeStore {
    private let profileID: UUID
    private let defaults: UserDefaults

    private(set) var items: [ShopItem]
    /// One equipped item id per category (nil = bare).
    private(set) var equipped: [ShopItemCategory: String]

    private var unlockedKey: String { "shop.unlocked.\(profileID.uuidString)" }
    private var equippedKey: String { "shop.equipped.\(profileID.uuidString)" }

    init(profileID: UUID, defaults: UserDefaults = .standard) {
        self.profileID = profileID
        self.defaults = defaults

        let unlocked = Set(defaults.stringArray(forKey: "shop.unlocked.\(profileID.uuidString)") ?? [])
        self.items = ShopCatalog.all.map { item in
            var copy = item
            copy.isUnlocked = unlocked.contains(item.id)
            return copy
        }

        if let data = defaults.data(forKey: "shop.equipped.\(profileID.uuidString)"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            var map: [ShopItemCategory: String] = [:]
            for (raw, id) in decoded {
                if let category = ShopItemCategory(rawValue: raw) {
                    map[category] = id
                }
            }
            self.equipped = map
        } else {
            self.equipped = [:]
        }
    }

    func item(id: String) -> ShopItem? {
        items.first { $0.id == id }
    }

    func equippedItem(for category: ShopItemCategory) -> ShopItem? {
        guard let id = equipped[category] else { return nil }
        return item(id: id)
    }

    func unlockAndEquip(_ item: ShopItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isUnlocked = true
        equipped[item.category] = item.id
        persist()
    }

    func equip(_ item: ShopItem) {
        guard item.isUnlocked || items.first(where: { $0.id == item.id })?.isUnlocked == true else { return }
        equipped[item.category] = item.id
        persist()
    }

    func unequip(category: ShopItemCategory) {
        equipped[category] = nil
        persist()
    }

    nonisolated static func clear(for profileID: UUID, defaults: UserDefaults = .standard) {
        let id = profileID.uuidString
        defaults.removeObject(forKey: "shop.unlocked.\(id)")
        defaults.removeObject(forKey: "shop.equipped.\(id)")
    }

    private func persist() {
        let unlockedIDs = items.filter(\.isUnlocked).map(\.id)
        defaults.set(unlockedIDs, forKey: unlockedKey)

        var raw: [String: String] = [:]
        for (category, id) in equipped {
            raw[category.rawValue] = id
        }
        if let data = try? JSONEncoder().encode(raw) {
            defaults.set(data, forKey: equippedKey)
        }
    }
}
