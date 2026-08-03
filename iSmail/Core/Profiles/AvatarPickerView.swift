//
//  AvatarPickerView.swift
//  iSmail
//
//  3×3 high-contrast animal avatar grid for profile creation.
//

import SwiftUI

struct AvatarPickerView: View {
    @Binding var selectedAvatarId: String?

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 72), spacing: 14),
        count: 3
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(AvatarCatalog.all) { option in
                avatarCard(option)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Choose an avatar")
    }

    private func avatarCard(_ option: AvatarOption) -> some View {
        let isSelected = selectedAvatarId == option.id

        return Button {
            withAnimation(LearningTheme.successBump) {
                selectedAvatarId = option.id
            }
        } label: {
            AvatarBadgeView(avatarId: option.id, size: 80)
                .overlay {
                    RoundedRectangle(cornerRadius: 80 * 0.28, style: .continuous)
                        .strokeBorder(
                            isSelected ? LearningTheme.accent : LearningTheme.border.opacity(0.55),
                            lineWidth: isSelected ? 5 : LearningTheme.borderWidth
                        )
                }
                .scaleEffect(isSelected ? 1.08 : 1.0)
                .shadow(
                    color: isSelected ? LearningTheme.accent.opacity(0.28) : .clear,
                    radius: 8,
                    y: 4
                )
        }
        .buttonStyle(KidBounceButtonStyle())
        .sensoryFeedback(.impact(weight: .medium), trigger: selectedAvatarId) { _, newValue in
            newValue == option.id
        }
        .accessibilityLabel(option.displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityHint(isSelected ? "Selected" : "Double tap to select")
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var selected: String? = "avatar_lion"
        var body: some View {
            AvatarPickerView(selectedAvatarId: $selected)
                .padding()
                .background(PlayWorldBackground())
        }
    }
    return PreviewHost()
}
