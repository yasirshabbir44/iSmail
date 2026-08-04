//
//  ParentProgressView.swift
//  iSmail
//
//  Simple parent corner — skills practiced, streak & chapter progress.
//

import SwiftUI

struct ParentProgressView: View {
    let nickname: String
    let ageBandLabel: String
    let completedChapters: Int
    let totalChapters: Int
    let streakDays: Int
    let coinBalance: Int
    let practice: PracticeProgressStore
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private var completionPercent: Int {
        guard totalChapters > 0 else { return 0 }
        return Int((Double(completedChapters) / Double(totalChapters) * 100).rounded())
    }

    var body: some View {
        ZStack {
            PlayWorldBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    summaryCard

                    skillsCard

                    tipsCard
                }
                .padding(20)
                .padding(.bottom, 28)
                .frame(maxWidth: LearningTheme.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ScreenCloseButton {
                onClose?()
                dismiss()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Parent corner")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text("\(nickname)'s learning snapshot")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Progress")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)

            HStack(spacing: 12) {
                statPill(title: "Chapters", value: "\(completedChapters)/\(totalChapters)", tint: LearningTheme.accent)
                statPill(title: "Streak", value: "\(streakDays)d", tint: LearningTheme.coral)
                statPill(title: "Stars", value: "\(coinBalance)", tint: LearningTheme.sunshine)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Path complete")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(LearningTheme.mutedInk)
                    Spacer()
                    Text("\(completionPercent)%")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.accent)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(LearningTheme.slot)
                        Capsule()
                            .fill(LearningTheme.accent)
                            .frame(width: geo.size.width * CGFloat(completionPercent) / 100)
                    }
                }
                .frame(height: 12)
            }

            Text(ageBandLabel)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(LearningTheme.accentSoft))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(tint: LearningTheme.accent))
    }

    private var skillsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's practice")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)

            skillRow("Letters (ABC)", practice.lettersPlayed, Color(red: 0.20, green: 0.55, blue: 0.90))
            skillRow("Numbers (123)", practice.numbersPlayed, Color(red: 0.95, green: 0.45, blue: 0.55))
            skillRow("Speaking words", practice.wordsPlayed, Color(red: 0.35, green: 0.72, blue: 0.55))
            skillRow("Songs", practice.songsPlayed, Color(red: 0.55, green: 0.40, blue: 0.78))
            skillRow("Storybook", practice.storybooksPlayed, Color(red: 0.28, green: 0.32, blue: 0.72))
            skillRow("Trace & write", practice.tracePlayed, Color(red: 0.95, green: 0.55, blue: 0.25))

            if practice.practiceCountToday == 0 {
                Text("No practice yet today — open Learn on the home map.")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(tint: Color(red: 0.20, green: 0.55, blue: 0.90)))
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How iSmail helps")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)

            tipLine("Short 3-step chapters keep focus friendly.")
            tipLine("Learn Hub includes ABC, counting, words, songs & tracing.")
            tipLine("Buddy hints appear after misses — soft, never harsh.")
            tipLine("Calm Corner is always available when energy runs high.")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(tint: LearningTheme.success))
    }

    private func tipLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(LearningTheme.success)
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func skillRow(_ title: String, _ count: Int, _ tint: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint.opacity(0.2))
                .frame(width: 10, height: 10)
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text(count == 0 ? "—" : "\(count)×")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(tint)
                .fixedSize()
        }
    }

    private func statPill(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.mutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.12))
        }
    }

    private func cardBackground(tint: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(LearningTheme.surface.opacity(0.94))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(tint.opacity(0.22), lineWidth: 2)
            }
            .shadow(color: tint.opacity(0.1), radius: 10, y: 5)
    }
}
