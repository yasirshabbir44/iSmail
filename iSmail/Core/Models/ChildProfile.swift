//
//  ChildProfile.swift
//  iSmail
//
//  SwiftData child identity — nickname, avatar, age for difficulty tailoring.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ChildProfile {
    @Attribute(.unique) var id: UUID
    /// Display name, capped at 12 characters at the UI layer.
    var nickname: String
    var dateOfBirth: Date
    /// Matches `AvatarOption.id` (e.g. "avatar_lion").
    var avatarId: String
    var createdDate: Date
    var totalCoins: Int

    var ageInYears: Int {
        let years = Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
        return max(0, years)
    }

    init(
        id: UUID = UUID(),
        nickname: String,
        dateOfBirth: Date,
        avatarId: String,
        createdDate: Date = .now,
        totalCoins: Int = 0
    ) {
        self.id = id
        self.nickname = Self.clampedNickname(nickname)
        self.dateOfBirth = dateOfBirth
        self.avatarId = avatarId
        self.createdDate = createdDate
        self.totalCoins = max(0, totalCoins)
    }

    static let nicknameMaxLength = 12

    static func clampedNickname(_ raw: String) -> String {
        String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(nicknameMaxLength))
    }

    /// Removes per-profile UserDefaults progress so deleted profiles leave no orphans.
    @MainActor static func clearLocalProgress(for profileID: UUID) {
        let defaults = UserDefaults.standard
        let id = profileID.uuidString
        defaults.removeObject(forKey: "adventure.streak.\(id)")
        defaults.removeObject(forKey: "adventure.streakDay.\(id)")
        PetWardrobeStore.clear(for: profileID, defaults: defaults)
        StickerBookStore.clear(for: profileID, defaults: defaults)
    }
}

// MARK: - Avatar catalog

struct AvatarOption: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let systemImage: String
    /// RGB 0…1 — stored as components so the catalog stays `Sendable`.
    let tintRed: Double
    let tintGreen: Double
    let tintBlue: Double

    var tint: Color {
        Color(red: tintRed, green: tintGreen, blue: tintBlue)
    }

    var softTint: Color {
        tint.opacity(0.22)
    }
}

enum AvatarCatalog {
    static let all: [AvatarOption] = [
        AvatarOption(id: "avatar_lion", displayName: "Lion", systemImage: "flame.fill",
                     tintRed: 0.98, tintGreen: 0.55, tintBlue: 0.20),
        AvatarOption(id: "avatar_falcon", displayName: "Falcon", systemImage: "bird.fill",
                     tintRed: 0.42, tintGreen: 0.58, tintBlue: 0.95),
        AvatarOption(id: "avatar_bear", displayName: "Bear", systemImage: "pawprint.fill",
                     tintRed: 0.62, tintGreen: 0.42, tintBlue: 0.28),
        AvatarOption(id: "avatar_fox", displayName: "Fox", systemImage: "hare.fill",
                     tintRed: 0.98, tintGreen: 0.45, tintBlue: 0.38),
        AvatarOption(id: "avatar_owl", displayName: "Owl", systemImage: "moon.stars.fill",
                     tintRed: 0.55, tintGreen: 0.40, tintBlue: 0.78),
        AvatarOption(id: "avatar_turtle", displayName: "Turtle", systemImage: "tortoise.fill",
                     tintRed: 0.22, tintGreen: 0.70, tintBlue: 0.48),
        AvatarOption(id: "avatar_fish", displayName: "Fish", systemImage: "fish.fill",
                     tintRed: 0.08, tintGreen: 0.62, tintBlue: 0.68),
        AvatarOption(id: "avatar_bug", displayName: "Bug", systemImage: "ladybug.fill",
                     tintRed: 0.90, tintGreen: 0.28, tintBlue: 0.35),
        AvatarOption(id: "avatar_cat", displayName: "Cat", systemImage: "cat.fill",
                     tintRed: 1.0, tintGreen: 0.78, tintBlue: 0.22)
    ]

    static func option(for id: String) -> AvatarOption {
        all.first { $0.id == id } ?? all[0]
    }
}

// MARK: - Avatar badge

struct AvatarBadgeView: View {
    let avatarId: String
    var size: CGFloat = 80

    private var option: AvatarOption {
        AvatarCatalog.option(for: avatarId)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(option.softTint)
                .frame(width: size, height: size)

            Image(systemName: option.systemImage)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(option.tint)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityLabel("\(option.displayName) avatar")
    }
}
