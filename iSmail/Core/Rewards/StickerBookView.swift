//
//  StickerBookView.swift
//  iSmail
//
//  Kid-friendly sticker album celebrating learning milestones.
//

import SwiftUI

struct StickerBookView: View {
    let completedCount: Int
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var appear = false

    private var unlocked: Set<String> {
        // Recompute from catalog thresholds so UI stays in sync even without store mutation.
        Set(
            StickerCatalog.all
                .filter { completedCount >= $0.requiredCompletions }
                .map(\.id)
        )
    }

    var body: some View {
        GeometryReader { geo in
            let narrow = geo.size.width < 380

            ZStack {
                PlayWorldBackground()

                VStack(spacing: 16) {
                    topChrome

                    Text("Your sticker book")
                        .font(.system(.title, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Finish lessons to unlock shiny stickers!")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(LearningTheme.mutedInk)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(StickerCatalog.all) { badge in
                            stickerCard(badge, unlocked: unlocked.contains(badge.id), narrow: narrow)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, narrow ? 16 : 20)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .frame(maxWidth: LearningTheme.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(LearningTheme.buddyBounce) { appear = true }
        }
    }

    private var topChrome: some View {
        HStack {
            ScreenBackButton(accessibilityLabel: "Back to map") {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
            }
            Spacer()
            Text("\(unlocked.count)/\(StickerCatalog.all.count)")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    Capsule(style: .continuous)
                        .fill(LearningTheme.surface.opacity(0.95))
                }
        }
    }

    private func stickerCard(_ badge: StickerBadge, unlocked: Bool, narrow: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(unlocked ? badge.tint.opacity(0.22) : LearningTheme.slot)
                    .frame(width: narrow ? 64 : 72, height: narrow ? 64 : 72)

                Image(systemName: badge.symbolName)
                    .font(.system(size: narrow ? 26 : 30, weight: .bold))
                    .foregroundStyle(unlocked ? badge.tint : LearningTheme.mutedInk.opacity(0.35))
            }

            Text(unlocked ? badge.title : "???")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(unlocked ? badge.subtitle : "Keep playing to unlock")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.94))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            unlocked ? badge.tint.opacity(0.45) : Color.white.opacity(0.7),
                            lineWidth: 2
                        )
                }
                .shadow(color: (unlocked ? badge.tint : LearningTheme.accent).opacity(0.12), radius: 10, y: 5)
        }
        .accessibilityLabel(unlocked ? "\(badge.title). \(badge.subtitle)" : "Locked sticker")
    }
}

#Preview {
    StickerBookView(completedCount: 4)
}
