//
//  PetShopView.swift
//  iSmail
//
//  Virtual pet closet — spend coins to unlock & dress the buddy mascot.
//

import SwiftData
import SwiftUI

struct PetShopView: View {
    @Bindable var profile: ChildProfile
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var wardrobe: PetWardrobeStore
    @State private var selectedCategory: ShopItemCategory = .hat
    @State private var purchasePulse = 0
    @State private var successTrigger = 0
    @State private var buddyMood: BuddyMood = .idle
    @State private var insufficientFlash = false

    private let mascotSize: CGFloat = 140

    init(profile: ChildProfile, onClose: (() -> Void)? = nil) {
        self.profile = profile
        self.onClose = onClose
        _wardrobe = State(initialValue: PetWardrobeStore(profileID: profile.id))
    }

    private var filteredItems: [ShopItem] {
        wardrobe.items.filter { $0.category == selectedCategory }
    }

    var body: some View {
        GeometryReader { geo in
            let isNarrow = geo.size.width < 380

            ZStack {
                PlayWorldBackground()

                VStack(spacing: isNarrow ? 14 : 18) {
                    topBar
                    characterCanvas
                    categoryPicker
                    itemScroller(narrow: isNarrow)
                }
                .padding(.horizontal, isNarrow ? 16 : 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .frame(maxWidth: LearningTheme.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: successTrigger)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .frame(width: 48, height: 48)
                    .background {
                        Circle()
                            .fill(LearningTheme.surface.opacity(0.94))
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
                            }
                    }
            }
            .buttonStyle(KidBounceButtonStyle())
            .accessibilityLabel("Close pet shop")

            VStack(alignment: .leading, spacing: 2) {
                Text("Pet Closet")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                Text("Dress your buddy!")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(LearningTheme.mutedInk)
            }

            Spacer(minLength: 8)

            coinChip
        }
    }

    private var coinChip: some View {
        HStack(spacing: 6) {
            Text("🪙")
                .font(.system(size: 20))
                .scaleEffect(purchasePulse > 0 ? 1.14 : 1.0)

            Text("\(profile.totalCoins)")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .contentTransition(.numericText())
                .monospacedDigit()
                .animation(LearningTheme.successBump, value: profile.totalCoins)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Capsule(style: .continuous)
                .fill(insufficientFlash ? LearningTheme.coralSoft : LearningTheme.sunshineSoft)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            (insufficientFlash ? LearningTheme.coral : LearningTheme.sunshine).opacity(0.5),
                            lineWidth: 2
                        )
                }
        }
        .accessibilityLabel("Coin balance \(profile.totalCoins)")
    }

    // MARK: - Character canvas

    private var characterCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(LearningTheme.accent.opacity(0.28), lineWidth: 2)
                }
                .shadow(color: LearningTheme.accent.opacity(0.12), radius: 14, y: 8)

            DressedBuddyView(
                mood: buddyMood,
                size: mascotSize,
                hat: wardrobe.equippedItem(for: .hat),
                glasses: wardrobe.equippedItem(for: .glasses),
                accessory: wardrobe.equippedItem(for: .accessory)
            )
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .animation(LearningTheme.forgivingSpring, value: wardrobe.equipped)
    }

    // MARK: - Category + grid

    private var categoryPicker: some View {
        HStack(spacing: 8) {
            ForEach(ShopItemCategory.allCases, id: \.self) { category in
                let selected = selectedCategory == category
                Button {
                    withAnimation(LearningTheme.forgivingSpring) {
                        selectedCategory = category
                    }
                } label: {
                    Text(category.displayName)
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(selected ? .white : LearningTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            Capsule(style: .continuous)
                                .fill(selected ? category.tint : LearningTheme.surface.opacity(0.9))
                                .overlay {
                                    Capsule(style: .continuous)
                                        .strokeBorder(
                                            selected ? category.tint : Color.white.opacity(0.7),
                                            lineWidth: 2
                                        )
                                }
                        }
                }
                .buttonStyle(KidBounceButtonStyle())
                .accessibilityLabel(category.displayName)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func itemScroller(narrow: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: narrow ? 12 : 16) {
                ForEach(filteredItems) { item in
                    shopCard(for: item)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
    }

    private func shopCard(for item: ShopItem) -> some View {
        let unlocked = item.isUnlocked
        let equipped = wardrobe.equipped[item.category] == item.id
        let canAfford = profile.totalCoins >= item.costCoins

        return VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(item.category.tint.opacity(0.16))
                    .frame(width: 96, height: 96)

                Image(systemName: item.assetName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(item.category.tint)
                    .symbolRenderingMode(.hierarchical)

                if equipped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(LearningTheme.success)
                        .offset(x: 34, y: -34)
                }
            }

            Text(item.name)
                .font(.system(.caption, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button {
                handleTap(item)
            } label: {
                Group {
                    if unlocked {
                        Text(equipped ? "On" : "Wear")
                    } else {
                        HStack(spacing: 4) {
                            Text("🪙")
                            Text("\(item.costCoins)")
                        }
                    }
                }
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(buttonFill(unlocked: unlocked, equipped: equipped, canAfford: canAfford))
                }
                .shadow(
                    color: buttonFill(unlocked: unlocked, equipped: equipped, canAfford: canAfford).opacity(0.35),
                    radius: 8,
                    y: 4
                )
            }
            .buttonStyle(KidBounceButtonStyle())
            .accessibilityLabel(accessibilityLabel(for: item, unlocked: unlocked, equipped: equipped))
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.94))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            equipped ? LearningTheme.success.opacity(0.55) : Color.white.opacity(0.75),
                            lineWidth: 2
                        )
                }
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
    }

    private func buttonFill(unlocked: Bool, equipped: Bool, canAfford: Bool) -> Color {
        if unlocked {
            return equipped ? LearningTheme.success : LearningTheme.accent
        }
        return canAfford ? LearningTheme.coral : LearningTheme.mutedInk.opacity(0.55)
    }

    private func accessibilityLabel(for item: ShopItem, unlocked: Bool, equipped: Bool) -> String {
        if unlocked {
            return equipped ? "\(item.name), wearing" : "Wear \(item.name)"
        }
        return "Buy \(item.name) for \(item.costCoins) coins"
    }

    // MARK: - Actions

    private func handleTap(_ item: ShopItem) {
        if item.isUnlocked {
            withAnimation(LearningTheme.forgivingSpring) {
                if wardrobe.equipped[item.category] == item.id {
                    wardrobe.unequip(category: item.category)
                    buddyMood = .idle
                } else {
                    wardrobe.equip(item)
                    buddyMood = .cheering
                }
            }
            return
        }

        guard profile.totalCoins >= item.costCoins else {
            withAnimation(LearningTheme.successBump) {
                insufficientFlash = true
            }
            AudioHapticManager.shared.playIncorrect()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 420_000_000)
                withAnimation(LearningTheme.forgivingSpring) {
                    insufficientFlash = false
                }
            }
            return
        }

        withAnimation(LearningTheme.successBump) {
            profile.totalCoins = max(0, profile.totalCoins - item.costCoins)
            wardrobe.unlockAndEquip(item)
            buddyMood = .celebrating
            purchasePulse += 1
            successTrigger += 1
        }
        AudioHapticManager.shared.playSuccess()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(LearningTheme.forgivingSpring) {
                buddyMood = .cheering
            }
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

// MARK: - Dressed mascot

struct DressedBuddyView: View {
    var mood: BuddyMood = .idle
    var size: CGFloat = 140
    var hat: ShopItem?
    var glasses: ShopItem?
    var accessory: ShopItem?

    var body: some View {
        ZStack {
            BuddyCoachView(mood: mood, size: size)

            if let hat {
                Image(systemName: hat.assetName)
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(hat.category.tint)
                    .symbolRenderingMode(.hierarchical)
                    .offset(y: -size * 0.62)
                    .transition(.scale.combined(with: .opacity))
            }

            if let glasses {
                Image(systemName: glasses.assetName)
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundStyle(LearningTheme.ink.opacity(0.85))
                    .offset(y: -size * 0.06)
                    .transition(.scale.combined(with: .opacity))
            }

            if let accessory {
                Image(systemName: accessory.assetName)
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(accessory.category.tint)
                    .offset(x: size * 0.42, y: size * 0.28)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ChildProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let profile = ChildProfile(
        nickname: "Ismail",
        dateOfBirth: .now.addingTimeInterval(-7 * 365 * 24 * 3600),
        avatarId: "avatar_lion",
        totalCoins: 200
    )
    container.mainContext.insert(profile)
    return PetShopView(profile: profile)
        .modelContainer(container)
}
