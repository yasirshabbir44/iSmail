//
//  InteractiveStorybookTaskView.swift
//  iSmail
//
//  Nighttime page-turn storybook with tap hotspots — beyond listen-and-respond Story Time.
//

import SwiftUI

struct InteractiveStorybookTaskView: View {
    let content: InteractiveStorybookContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var pageIndex = 0
    @State private var foundHotspotIDs: Set<UUID> = []
    @State private var sparkleHotspotID: UUID?
    @State private var pageTurnForward = true
    @State private var pageScale: CGFloat = 0.94
    @State private var nudgePulse = false
    @State private var hotspotPulse = false
    @State private var isFinishing = false

    private let nightInk = Color(red: 0.28, green: 0.32, blue: 0.72)
    private let nightSoft = Color(red: 0.55, green: 0.58, blue: 0.95)

    private var pages: [StorybookPage] { content.pages }
    private var page: StorybookPage? {
        guard pages.indices.contains(pageIndex) else { return nil }
        return pages[pageIndex]
    }

    private var isLastPage: Bool {
        pageIndex >= pages.count - 1
    }

    private var requiredRemaining: [StoryHotspot] {
        guard let page else { return [] }
        guard page.requireAllHotspots else { return [] }
        return page.hotspots.filter { $0.isRequired && !foundHotspotIDs.contains($0.id) }
    }

    private var canAdvance: Bool {
        requiredRemaining.isEmpty
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 520

            VStack(spacing: compact ? 10 : 14) {
                bookChrome(compact: compact)

                if let page {
                    VStack(spacing: compact ? 10 : 14) {
                        illustration(page: page, compact: compact)
                            .frame(height: compact ? 200 : 248)

                        captionBlock(page: page, compact: compact)
                    }
                    .id(page.id)
                    .scaleEffect(pageScale)
                    .transition(pageTransition)
                    .gesture(pageSwipeGesture)
                }

                Spacer(minLength: 4)

                turnControls(compact: compact)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            withAnimation(LearningTheme.buddyBounce) { pageScale = 1 }
            withAnimation(LearningTheme.floaty.repeatForever(autoreverses: true)) {
                hotspotPulse = true
            }
            speakNarration()
        }
        .onChange(of: pageIndex) { _, _ in
            foundHotspotIDs = []
            sparkleHotspotID = nil
            nudgePulse = false
            pageScale = 0.94
            withAnimation(LearningTheme.buddyBounce) { pageScale = 1 }
            speakNarration()
        }
    }

    // MARK: - Chrome

    private func bookChrome(compact: Bool) -> some View {
        VStack(spacing: 8) {
            Text(content.bookTitle)
                .font(.system(compact ? .subheadline : .headline, design: .rounded).weight(.heavy))
                .foregroundStyle(nightInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(
                            index < pageIndex
                                ? nightInk
                                : (index == pageIndex ? nightSoft : LearningTheme.slot)
                        )
                        .frame(width: index == pageIndex ? 22 : 10, height: 10)
                        .animation(LearningTheme.forgivingSpring, value: pageIndex)
                }
            }
            .accessibilityLabel("Storybook page \(pageIndex + 1) of \(pages.count)")
        }
    }

    // MARK: - Caption

    private func captionBlock(page: StorybookPage, compact: Bool) -> some View {
        VStack(spacing: 8) {
            Text(page.narration)
                .font(.system(compact ? .callout : .title3, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.85)

            if !canAdvance {
                Text(page.seekHint)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(nightSoft)
                    .scaleEffect(nudgePulse ? 1.04 : 1)
                    .animation(LearningTheme.buddyBounce, value: nudgePulse)
            } else if !page.hotspots.isEmpty {
                Text(isLastPage ? "Ready for goodnight ✨" : "Nice finds — turn the page!")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.success)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Illustration

    private func illustration(page: StorybookPage, compact: Bool) -> some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.35, green: 0.38, blue: 0.75),
                                Color(red: 0.10, green: 0.12, blue: 0.32)
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: max(geo.size.width, geo.size.height) * 0.7
                        )
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.35), Color.white.opacity(0)],
                            center: .center,
                            startRadius: 4,
                            endRadius: compact ? 50 : 70
                        )
                    )
                    .frame(width: compact ? 90 : 120, height: compact ? 90 : 120)
                    .position(x: geo.size.width * 0.78, y: geo.size.height * 0.22)

                Image(systemName: page.backgroundSymbol)
                    .font(.system(size: compact ? 64 : 84, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.10))
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.48)

                Text(page.sceneEmoji)
                    .font(.system(size: compact ? 56 : 72))
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.48)
                    .accessibilityHidden(true)

                ForEach(page.hotspots) { hotspot in
                    hotspotButton(hotspot: hotspot, compact: compact, in: geo.size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(nightSoft.opacity(0.45), lineWidth: 2)
            }
            .shadow(color: nightInk.opacity(0.28), radius: 14, y: 8)
        }
    }

    private func hotspotButton(hotspot: StoryHotspot, compact: Bool, in size: CGSize) -> some View {
        let found = foundHotspotIDs.contains(hotspot.id)
        let sparkle = sparkleHotspotID == hotspot.id
        let hintThis = showHint && hotspot.isRequired && !found
        let side = compact ? 52.0 : 60.0

        return Button {
            discover(hotspot)
        } label: {
            ZStack {
                Circle()
                    .fill(found ? LearningTheme.successSoft : Color.white.opacity(0.94))
                    .frame(width: side, height: side)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                hintThis
                                    ? LearningTheme.sunshine
                                    : (found ? LearningTheme.success : nightSoft.opacity(0.6)),
                                lineWidth: hintThis || sparkle ? 3 : 2
                            )
                    }
                    .shadow(
                        color: (hintThis || (!found && hotspotPulse))
                            ? LearningTheme.sunshine.opacity(0.55)
                            : .black.opacity(0.12),
                        radius: hintThis || (!found && hotspotPulse) ? 10 : 4,
                        y: 2
                    )
                    .scaleEffect(sparkle ? 1.18 : (found ? 1.0 : (hotspotPulse && !found ? 1.06 : 1.0)))

                Text(hotspot.emoji)
                    .font(.system(size: compact ? 26 : 30))

                if found {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LearningTheme.success)
                        .offset(x: side * 0.32, y: -side * 0.32)
                }
            }
            .hintAura(isActive: hintThis)
        }
        .buttonStyle(KidBounceButtonStyle())
        .position(x: size.width * hotspot.x, y: size.height * hotspot.y)
        .accessibilityLabel(found ? "\(hotspot.label), found" : "Tap \(hotspot.label)")
        .disabled(isFinishing)
    }

    // MARK: - Controls

    private func turnControls(compact: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                turnBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(pageIndex == 0 ? LearningTheme.mutedInk.opacity(0.35) : LearningTheme.ink)
                    .frame(width: LearningTheme.minTouchTarget, height: LearningTheme.minTouchTarget)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LearningTheme.slot)
                    }
            }
            .buttonStyle(KidBounceButtonStyle())
            .disabled(pageIndex == 0 || isFinishing)
            .accessibilityLabel("Previous page")

            Button {
                tryAdvance()
            } label: {
                HStack(spacing: 8) {
                    Text(advanceLabel)
                    Image(systemName: isLastPage ? "star.fill" : "book.pages.fill")
                }
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: LearningTheme.minTouchTarget)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(canAdvance ? nightInk : LearningTheme.mutedInk.opacity(0.35))
                }
            }
            .buttonStyle(KidBounceButtonStyle())
            .disabled(isFinishing)
            .accessibilityLabel(advanceLabel)
        }
        .padding(.top, compact ? 2 : 4)
    }

    private var advanceLabel: String {
        if !canAdvance { return "Find them first" }
        return isLastPage ? "Finish storybook" : "Turn page"
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: pageTurnForward ? .trailing : .leading)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.96)),
            removal: .move(edge: pageTurnForward ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    private var pageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 48)
            .onEnded { value in
                let dx = value.translation.width
                let dy = abs(value.translation.height)
                guard abs(dx) > dy, abs(dx) > 56 else { return }
                if dx < 0 {
                    tryAdvance()
                } else {
                    turnBack()
                }
            }
    }

    // MARK: - Actions

    private func discover(_ hotspot: StoryHotspot) {
        guard !isFinishing else { return }

        if foundHotspotIDs.contains(hotspot.id) {
            SpeechManager.shared.speak(text: hotspot.speakText)
            AudioHapticManager.shared.playPop()
            return
        }

        foundHotspotIDs.insert(hotspot.id)
        sparkleHotspotID = hotspot.id
        AudioHapticManager.shared.playSuccess()
        onCorrectAttempt?()
        SpeechManager.shared.speak(text: hotspot.speakText)

        SafeAsync.after(0.45) {
            if sparkleHotspotID == hotspot.id { sparkleHotspotID = nil }
        }
    }

    private func tryAdvance() {
        guard !isFinishing else { return }
        guard canAdvance else {
            nudgePulse = true
            AudioHapticManager.shared.playIncorrect()
            onIncorrectAttempt?()
            if let first = requiredRemaining.first {
                SpeechManager.shared.speak(text: page?.seekHint ?? "Tap \(first.label)!")
            }
            SafeAsync.after(0.4) { nudgePulse = false }
            return
        }

        AudioHapticManager.shared.playPop()
        if isLastPage {
            isFinishing = true
            onCorrectAttempt?()
            SafeAsync.after(0.35) {
                onComplete?()
            }
        } else {
            onCorrectAttempt?()
            pageTurnForward = true
            withAnimation(LearningTheme.forgivingSpring) {
                pageIndex += 1
            }
        }
    }

    private func turnBack() {
        guard pageIndex > 0, !isFinishing else { return }
        AudioHapticManager.shared.playPop()
        pageTurnForward = false
        withAnimation(LearningTheme.forgivingSpring) {
            pageIndex -= 1
        }
    }

    private func speakNarration() {
        guard let page else { return }
        let hasRequired = page.requireAllHotspots && page.hotspots.contains(where: \.isRequired)
        if hasRequired {
            SpeechManager.shared.speak(text: "\(page.narration) \(page.seekHint)")
        } else {
            SpeechManager.shared.speak(text: page.narration)
        }
    }
}

#Preview {
    InteractiveStorybookTaskView(content: .previewMoonlight)
        .padding()
        .background(PlayWorldBackground())
}
