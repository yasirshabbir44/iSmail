//
//  DailyMissionCard.swift
//  iSmail
//
//  Clear daily goals — chapter + practice — LingoKids-style easy learning loop.
//

import SwiftUI

struct DailyMissionCard: View {
    let chapterTitle: String?
    let chapterDone: Bool
    let practiceDone: Bool
    let bonusClaimed: Bool
    var onPlayChapter: (() -> Void)?
    var onOpenLearn: (() -> Void)?

    private var bothDone: Bool { chapterDone && practiceDone }
    private var progress: Int {
        (chapterDone ? 1 : 0) + (practiceDone ? 1 : 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: bothDone ? "checkmark.seal.fill" : "flag.checkered")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(bothDone ? LearningTheme.success : LearningTheme.coral)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's mission")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(LearningTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(bothDone ? "Mission complete — super star!" : "2 easy goals · earn bonus stars")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(LearningTheme.mutedInk)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                Text("\(progress)/2")
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule().fill(bothDone ? LearningTheme.success : LearningTheme.coral)
                    }
                    .fixedSize()
            }

            missionRow(
                done: chapterDone,
                title: chapterTitle.map { "Play \($0)" } ?? "Play today's chapter",
                symbol: "map.fill",
                tint: LearningTheme.accent,
                actionTitle: chapterDone ? "Done" : "Play",
                action: chapterDone ? nil : onPlayChapter
            )

            missionRow(
                done: practiceDone,
                title: "Practice Letters, Numbers, or Words",
                symbol: "textformat",
                tint: Color(red: 0.20, green: 0.55, blue: 0.90),
                actionTitle: practiceDone ? "Done" : "Learn",
                action: practiceDone ? nil : onOpenLearn
            )

            if bothDone {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(LearningTheme.sunshine)
                    Text(bonusClaimed ? "Bonus stars collected!" : "Bonus stars unlocked!")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(LearningTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .padding(.top, 2)
            }
        }
        .padding(LearningTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            bothDone ? LearningTheme.success.opacity(0.45) : LearningTheme.coral.opacity(0.35),
                            lineWidth: 2
                        )
                }
                .shadow(color: LearningTheme.coral.opacity(0.12), radius: 12, y: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's mission, \(progress) of 2 complete")
    }

    private func missionRow(
        done: Bool,
        title: String,
        symbol: String,
        tint: Color,
        actionTitle: String,
        action: (() -> Void)?
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            missionRowContent(
                done: done,
                title: title,
                symbol: symbol,
                tint: tint,
                actionTitle: actionTitle,
                action: action,
                stacked: false
            )
            missionRowContent(
                done: done,
                title: title,
                symbol: symbol,
                tint: tint,
                actionTitle: actionTitle,
                action: action,
                stacked: true
            )
        }
    }

    @ViewBuilder
    private func missionRowContent(
        done: Bool,
        title: String,
        symbol: String,
        tint: Color,
        actionTitle: String,
        action: (() -> Void)?,
        stacked: Bool
    ) -> some View {
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        rowIcon(done: done, symbol: symbol, tint: tint)
                        Text(title)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(LearningTheme.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    rowAction(actionTitle: actionTitle, tint: tint, action: action)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(spacing: 10) {
                    rowIcon(done: done, symbol: symbol, tint: tint)

                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(LearningTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)

                    rowAction(actionTitle: actionTitle, tint: tint, action: action)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(done ? LearningTheme.successSoft.opacity(0.5) : LearningTheme.slot.opacity(0.65))
        }
    }

    private func rowIcon(done: Bool, symbol: String, tint: Color) -> some View {
        Image(systemName: done ? "checkmark.circle.fill" : symbol)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(done ? LearningTheme.success : tint)
            .frame(width: 36, height: 36)
            .background {
                Circle().fill(done ? LearningTheme.successSoft : tint.opacity(0.14))
            }
    }

    @ViewBuilder
    private func rowAction(
        actionTitle: String,
        tint: Color,
        action: (() -> Void)?
    ) -> some View {
        if let action {
            Button(action: action) {
                Text(actionTitle)
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule().fill(tint)
                    }
            }
            .buttonStyle(KidBounceButtonStyle())
            .fixedSize()
        } else {
            Text(actionTitle)
                .font(.system(.caption, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.success)
                .fixedSize()
        }
    }
}
