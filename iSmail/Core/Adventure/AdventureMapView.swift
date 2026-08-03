//
//  AdventureMapView.swift
//  iSmail
//
//  ADHD-friendly winding island adventure path for daily chapters.
//

import SwiftUI

struct AdventureMapView: View {
    let chapters: [ChapterNode]
    let progress: DailyProgressManager
    let avatarId: String
    var onStartLesson: (ChapterNode) -> Void

    @State private var previewChapter: ChapterNode?
    @State private var successTrigger = 0

    private let mapSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    private let nodeSize: CGFloat = 84
    private let estimatedMinutes = 2

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let positions = Self.nodePositions(
                count: chapters.count,
                width: width,
                nodeSize: nodeSize
            )
            let mapHeight = Self.mapContentHeight(
                count: chapters.count,
                nodeSize: nodeSize
            )

            ZStack(alignment: .topLeading) {
                IslandPathDecoration(width: width, height: mapHeight)

                AdventurePathStroke(points: positions)
                    .stroke(
                        LearningTheme.accent.opacity(0.35),
                        style: StrokeStyle(
                            lineWidth: 10,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: [14, 12]
                        )
                    )

                AdventurePathStroke(points: positions)
                    .stroke(
                        Color.white.opacity(0.65),
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: [14, 12]
                        )
                    )

                ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                    let point = positions[index]
                    let chapterStatus = progress.status(for: chapter)
                    let state = progress.mapState(for: chapter)

                    Button {
                        handleTap(chapter: chapter)
                    } label: {
                        MapNodeView(
                            step: chapter.dayNumber,
                            symbolName: chapter.type.systemImage,
                            tint: LearningTheme.activityTint(for: chapter.type),
                            state: state,
                            size: nodeSize,
                            isChestReward: chapter.isChestReward,
                            avatarId: avatarId,
                            countdownLabel: progress.countdownLabel(for: chapter),
                            isTodaysNode: progress.isCurrentFocus(chapter)
                        )
                    }
                    .buttonStyle(KidBounceButtonStyle())
                    .disabled(state == .locked)
                    .position(point)
                    .accessibilityHint(accessibilityHint(for: chapterStatus))
                }
            }
            .frame(width: width, height: mapHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(height: Self.mapContentHeight(count: chapters.count, nodeSize: nodeSize))
        .animation(mapSpring, value: progress.completedCount)
        .sheet(item: $previewChapter) { chapter in
            LessonPreviewSheet(
                chapter: chapter,
                estimatedMinutes: estimatedMinutes,
                onStart: {
                    let selected = chapter
                    previewChapter = nil
                    onStartLesson(selected)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sensoryFeedback(.success, trigger: successTrigger)
    }

    // MARK: - Interaction

    private func handleTap(chapter: ChapterNode) {
        guard progress.isPlayable(chapter) else { return }
        AudioHapticManager.shared.playSuccess()
        successTrigger &+= 1
        withAnimation(mapSpring) {
            previewChapter = chapter
        }
    }

    private func accessibilityHint(for status: ChapterNodeStatus) -> String {
        switch status {
        case .completed: return "Opens lesson preview"
        case .activeToday: return "Today's chapter — opens lesson preview"
        case .available: return "Unlocked — opens lesson preview to start"
        case .lockedFuture: return "Finish the previous day or wait for the unlock date"
        }
    }

    // MARK: - Zig-zag layout

    /// Alternating left / right waypoints down the island.
    static func nodePositions(
        count: Int,
        width: CGFloat,
        nodeSize: CGFloat
    ) -> [CGPoint] {
        guard count > 0 else { return [] }

        let inset = max(56, nodeSize * 0.85)
        let usable = max(width - inset * 2, nodeSize * 2)
        let leftX = inset + usable * 0.18
        let rightX = inset + usable * 0.82
        let centerX = width * 0.5
        // Extra top room for the floating avatar above today's node.
        let topPad: CGFloat = nodeSize * 1.25
        let stepY: CGFloat = nodeSize * 1.75

        return (0..<count).map { index in
            let y = topPad + CGFloat(index) * stepY
            let x: CGFloat
            if count == 1 {
                x = centerX
            } else {
                x = index.isMultiple(of: 2) ? leftX : rightX
            }
            return CGPoint(x: x, y: y)
        }
    }

    static func mapContentHeight(count: Int, nodeSize: CGFloat) -> CGFloat {
        guard count > 0 else { return nodeSize * 2 }
        let topPad = nodeSize * 1.25
        let stepY = nodeSize * 1.75
        // Extra bottom room for locked countdown badges.
        let bottomPad = nodeSize * 1.45
        return topPad + CGFloat(count - 1) * stepY + bottomPad
    }
}

// MARK: - Path geometry

private struct AdventurePathStroke: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        guard let first = points.first else { return Path() }
        var path = Path()
        path.move(to: first)

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midY = (previous.y + current.y) / 2
            let control1 = CGPoint(x: previous.x, y: midY)
            let control2 = CGPoint(x: current.x, y: midY)
            path.addCurve(to: current, control1: control1, control2: control2)
        }
        return path
    }
}

// MARK: - Soft island accents under the path

private struct IslandPathDecoration: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            Ellipse()
                .fill(LearningTheme.success.opacity(0.16))
                .frame(width: width * 0.92, height: height * 0.28)
                .position(x: width * 0.5, y: height * 0.22)

            Ellipse()
                .fill(LearningTheme.accentSoft)
                .frame(width: width * 0.78, height: height * 0.24)
                .position(x: width * 0.55, y: height * 0.55)

            Ellipse()
                .fill(LearningTheme.sunshineSoft.opacity(0.55))
                .frame(width: width * 0.7, height: height * 0.2)
                .position(x: width * 0.4, y: height * 0.82)

            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 18 + CGFloat(i % 2) * 8, height: 14 + CGFloat(i % 2) * 4)
                    .position(
                        x: width * (0.22 + CGFloat(i) * 0.18),
                        y: height * (0.18 + CGFloat(i % 3) * 0.28)
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Lesson preview sheet

private struct LessonPreviewSheet: View {
    let chapter: ChapterNode
    let estimatedMinutes: Int
    var onStart: () -> Void

    private let mapSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    private var tint: Color { LearningTheme.activityTint(for: chapter.type) }

    var body: some View {
        VStack(spacing: 22) {
            Capsule()
                .fill(LearningTheme.slot)
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            ZStack {
                if chapter.isChestReward {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.62, blue: 0.18),
                                    LearningTheme.sunshine
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)

                    Image(systemName: "treasurechest.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .fill(LearningTheme.activitySoft(for: chapter.type))
                        .frame(width: 96, height: 96)

                    Image(systemName: chapter.type.systemImage)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(tint)
                }
            }

            Text(chapter.title)
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)

            HStack(spacing: 12) {
                metaChip(
                    icon: "clock.fill",
                    label: "\(estimatedMinutes) mins",
                    color: LearningTheme.accent
                )
                metaChip(
                    icon: "star.fill",
                    label: "+\(chapter.rewardCoins) Coins",
                    color: LearningTheme.sunshine
                )
            }

            Button(action: onStart) {
                Text("START")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(tint, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: tint.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(KidBounceButtonStyle())
            .padding(.top, 4)
            .accessibilityLabel("Start \(chapter.title)")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.97, blue: 0.94),
                    LearningTheme.skyBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .animation(mapSpring, value: chapter.id)
    }

    private func metaChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Capsule(style: .continuous)
                .fill(LearningTheme.surface.opacity(0.95))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(color.opacity(0.35), lineWidth: 2)
                }
        }
    }
}

#Preview {
    let manager = DailyProgressManager(profileID: UUID())
    return ScrollView {
        AdventureMapView(
            chapters: manager.chapters,
            progress: manager,
            avatarId: "avatar_lion",
            onStartLesson: { _ in }
        )
        .padding(.horizontal, 16)
    }
    .background(PlayWorldBackground())
}
