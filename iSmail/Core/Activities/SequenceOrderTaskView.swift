//
//  SequenceOrderTaskView.swift
//  iSmail
//
//  Horizontal reordering with fluid springs, soft miss hints & audio cues.
//

import SwiftUI

struct SequenceOrderTaskView: View {
    let content: SequenceOrderContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var orderedIDs: [UUID]
    @State private var draggingID: UUID?
    @State private var dragTranslation: CGFloat = 0
    @State private var slotWidth: CGFloat = 96
    @State private var rowSpacing: CGFloat = 12
    @State private var successTrigger = 0
    @State private var warningTrigger = 0
    @State private var isComplete = false
    @State private var highlightCorrect = false
    @State private var rowNudge: CGFloat = 0
    @State private var incorrectSlotIndexes: Set<Int> = []
    @State private var generation = 0

    private let comfortableSpacing: CGFloat = 12
    private let maxItems = 5

    init(
        content: SequenceOrderContent,
        showHint: Bool = false,
        onIncorrectAttempt: (() -> Void)? = nil,
        onCorrectAttempt: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.content = content
        self.showHint = showHint
        self.onIncorrectAttempt = onIncorrectAttempt
        self.onCorrectAttempt = onCorrectAttempt
        self.onComplete = onComplete
        let capped = Array(content.items.prefix(maxItems))
        _orderedIDs = State(initialValue: capped.map(\.id))
    }

    private var itemsByID: [UUID: SequenceItem] {
        Dictionary(content.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private var expectedOrder: [UUID] {
        Array(content.correctOrder.prefix(orderedIDs.count))
    }

    var body: some View {
        VStack(spacing: 20) {
            slotsRow
                .offset(x: rowNudge)
            checkButton
        }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.warning, trigger: warningTrigger)
        .padding(.vertical, 4)
        .onChange(of: showHint) { _, active in
            if active {
                refreshIncorrectSlots()
            } else {
                incorrectSlotIndexes = []
            }
        }
        .onDisappear { generation += 1 }
    }

    // MARK: - Slots

    private var slotsRow: some View {
        GeometryReader { geo in
            let count = max(orderedIDs.count, 1)
            let adaptiveSpacing = LearningTheme.adaptiveSpacing(for: geo.size.width, comfortable: comfortableSpacing)
            let computed = LearningTheme.adaptiveTileSide(
                count: count,
                availableWidth: geo.size.width,
                spacing: adaptiveSpacing,
                ideal: 110
            )

            HStack(spacing: adaptiveSpacing) {
                ForEach(Array(orderedIDs.enumerated()), id: \.element) { index, id in
                    slotView(id: id, index: index, side: computed)
                        .frame(width: computed)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(LearningTheme.reorderSpring, value: orderedIDs)
            .onAppear {
                slotWidth = computed
                rowSpacing = adaptiveSpacing
            }
            .onChange(of: geo.size.width) { _, _ in
                slotWidth = computed
                rowSpacing = adaptiveSpacing
            }
        }
        .frame(height: max(100, min(140, slotWidth * 1.25)))
    }

    private func slotView(id: UUID, index: Int, side: CGFloat) -> some View {
        let item = itemsByID[id]
        let isDragging = draggingID == id
        let xOffset: CGFloat = isDragging ? dragTranslation : 0
        let isSoftMiss = showHint && incorrectSlotIndexes.contains(index) && !isComplete
        let iconSize = max(18, side * 0.28)

        return ZStack {
            RoundedRectangle(cornerRadius: LearningTheme.chipCornerRadius, style: .continuous)
                .fill(LearningTheme.slot)
                .overlay {
                    RoundedRectangle(cornerRadius: LearningTheme.chipCornerRadius, style: .continuous)
                        .strokeBorder(
                            LearningTheme.border.opacity(0.25),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                        )
                }
                .opacity(isDragging ? 1 : 0)

            VStack(spacing: side < 72 ? 4 : 8) {
                Text("\(index + 1)")
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .foregroundStyle(isSoftMiss ? LearningTheme.softMiss : LearningTheme.mutedInk.opacity(0.7))

                if let item {
                    Image(systemName: item.symbolName)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(
                            highlightCorrect
                                ? LearningTheme.success
                                : (isSoftMiss ? LearningTheme.softMiss : LearningTheme.accent)
                        )

                    Text(item.label)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(highlightCorrect ? LearningTheme.success : LearningTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(side < 72 ? 6 : 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: LearningTheme.chipCornerRadius, style: .continuous)
                    .fill(
                        highlightCorrect
                            ? LearningTheme.successSoft
                            : (isSoftMiss ? LearningTheme.softMissFill : LearningTheme.surface)
                    )
                    .shadow(
                        color: .black.opacity(isDragging ? 0.24 : 0.10),
                        radius: isDragging ? 16 : 6,
                        y: isDragging ? 10 : 3
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: LearningTheme.chipCornerRadius, style: .continuous)
                            .strokeBorder(
                                highlightCorrect
                                    ? LearningTheme.success
                                    : (isSoftMiss ? LearningTheme.softMiss : LearningTheme.border.opacity(0.55)),
                                lineWidth: isSoftMiss ? 4 : LearningTheme.borderWidth
                            )
                    }
            }
            .hintAura(isActive: isSoftMiss)
            .scaleEffect(isDragging ? 1.06 : 1.0)
            .opacity(isDragging ? 0.95 : 1.0)
            .offset(x: xOffset)
            .zIndex(isDragging ? 50 : 0)
            .highPriorityGesture(reorderGesture(for: id))
            .accessibilityLabel(item.map { "\($0.label), position \(index + 1)" } ?? "Empty")
            .accessibilityHint("Drag to reorder")
        }
        .frame(minHeight: max(LearningTheme.compactTileFloor + 30, side * 1.05))
    }

    // MARK: - Gesture

    private func reorderGesture(for id: UUID) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard !isComplete else { return }
                if draggingID == nil {
                    draggingID = id
                }
                guard draggingID == id else { return }
                dragTranslation = value.translation.width
                maybeSwap(translation: value.translation.width)
            }
            .onEnded { _ in
                withAnimation(LearningTheme.reorderSpring) {
                    dragTranslation = 0
                    draggingID = nil
                }
                if showHint {
                    refreshIncorrectSlots()
                }
            }
    }

    private func maybeSwap(translation: CGFloat) {
        guard let draggingID,
              let from = orderedIDs.firstIndex(of: draggingID)
        else { return }

        let threshold = slotWidth * 0.45
        var target = from

        if translation > threshold {
            target = min(from + 1, orderedIDs.count - 1)
        } else if translation < -threshold {
            target = max(from - 1, 0)
        }

        guard target != from else { return }

        withAnimation(LearningTheme.reorderSpring) {
            orderedIDs.swapAt(from, target)
            dragTranslation = translation > 0
                ? translation - (slotWidth + rowSpacing)
                : translation + (slotWidth + rowSpacing)
        }
    }

    // MARK: - Check

    private var checkButton: some View {
        Button {
            validateOrder()
        } label: {
            Text(isComplete ? "Nice order!" : "Check order")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: LearningTheme.minTouchTarget)
                .background {
                    RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                        .fill(isComplete ? LearningTheme.success : LearningTheme.accent)
                }
        }
        .buttonStyle(KidBounceButtonStyle())
        .disabled(isComplete)
        .accessibilityHint("Checks if the sequence is correct")
    }

    private func validateOrder() {
        guard !isComplete else { return }

        if orderedIDs == expectedOrder {
            isComplete = true
            incorrectSlotIndexes = []
            successTrigger += 1
            AudioHapticManager.shared.playSuccess()
            onCorrectAttempt?()
            withAnimation(LearningTheme.successBump) {
                highlightCorrect = true
            }
            onComplete?()
        } else {
            warningTrigger += 1
            AudioHapticManager.shared.playIncorrect()
            onIncorrectAttempt?()
            refreshIncorrectSlots()
            let token = generation
            withAnimation(.easeInOut(duration: 0.08)) { rowNudge = 8 }
            SafeAsync.after(0.08) {
                guard token == generation else { return }
                withAnimation(.easeInOut(duration: 0.08)) { rowNudge = -8 }
            }
            SafeAsync.after(0.16) {
                guard token == generation else { return }
                withAnimation(LearningTheme.forgivingSpring) { rowNudge = 0 }
            }
        }
    }

    private func refreshIncorrectSlots() {
        var misses = Set<Int>()
        for (index, id) in orderedIDs.enumerated() where index < expectedOrder.count {
            if id != expectedOrder[index] {
                misses.insert(index)
            }
        }
        withAnimation(LearningTheme.forgivingSpring) {
            incorrectSlotIndexes = misses
        }
    }
}

#Preview {
    SequenceOrderTaskView(content: .previewMorning, showHint: true)
        .padding()
        .background(LearningTheme.canvas)
}
