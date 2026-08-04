//
//  DragAndDropTaskView.swift
//  iSmail
//
//  Matching engine with magnetic drop zones, forgiving spring reset, hints & audio.
//  Drag uses the same local-translation pattern as SequenceOrderTaskView (morning routine).
//

import SwiftUI

struct DragAndDropTaskView: View {
    let content: DragAndDropContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var itemOffsets: [UUID: CGSize] = [:]
    @State private var draggingItemID: UUID?
    @State private var hoveringZoneID: UUID?
    @State private var matchedPairs: [UUID: UUID] = [:]
    @State private var occupiedZones: Set<UUID> = []
    @State private var successTrigger = 0
    @State private var warningTrigger = 0
    @State private var zoneFrames: [UUID: CGRect] = [:]
    @State private var itemFrames: [UUID: CGRect] = [:]
    @State private var didNotifyComplete = false
    /// Bumps to cancel pending match animations if the view goes away mid-flight.
    @State private var generation = 0

    private var isComplete: Bool {
        !content.items.isEmpty && matchedPairs.count == content.items.count
    }

    private var hintPair: (itemID: UUID, zoneID: UUID)? {
        guard showHint else { return nil }
        guard let item = content.items.first(where: { matchedPairs[$0.id] == nil }),
              let zone = content.zones.first(where: {
                  $0.matchKey == item.matchKey && !occupiedZones.contains($0.id)
              })
        else { return nil }
        return (item.id, zone.id)
    }

    var body: some View {
        GeometryReader { geo in
            let narrow = geo.size.height < 420 || geo.size.width < 340
            let stackSpacing: CGFloat = narrow ? 16 : 28

            VStack(spacing: stackSpacing) {
                dropZonesRow(availableWidth: geo.size.width)
                Spacer(minLength: narrow ? 6 : 12)
                dragTray(availableWidth: geo.size.width)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .coordinateSpace(name: "dndCanvas")
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.warning, trigger: warningTrigger)
        .onChange(of: isComplete) { _, done in
            guard done, !didNotifyComplete else { return }
            didNotifyComplete = true
            onComplete?()
        }
        .onDisappear {
            generation += 1
        }
    }

    // MARK: - Drop Zones

    private func dropZonesRow(availableWidth: CGFloat) -> some View {
        let count = content.zones.count
        let spacing = LearningTheme.adaptiveSpacing(for: availableWidth, comfortable: 16)

        return Group {
            if count > 3, availableWidth < 400 {
                // Explicit 2×2 (not LazyVGrid) so every zone measures immediately.
                let gridSide = LearningTheme.adaptiveTileSide(
                    count: 2,
                    availableWidth: availableWidth,
                    spacing: spacing,
                    ideal: LearningTheme.dropZoneSize
                )
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        ForEach(Array(content.zones.prefix(2))) { zone in
                            dropZoneView(zone, side: gridSide)
                        }
                    }
                    HStack(spacing: spacing) {
                        ForEach(Array(content.zones.dropFirst(2))) { zone in
                            dropZoneView(zone, side: gridSide)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                let side = LearningTheme.adaptiveTileSide(
                    count: count,
                    availableWidth: availableWidth,
                    spacing: spacing,
                    ideal: LearningTheme.dropZoneSize
                )
                HStack(spacing: spacing) {
                    ForEach(content.zones) { zone in
                        dropZoneView(zone, side: side)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onPreferenceChange(ZoneFramePreferenceKey.self) { frames in
            let merged = Self.mergedFrames(zoneFrames, with: frames)
            if merged != zoneFrames {
                zoneFrames = merged
            }
        }
    }

    private func dropZoneView(_ zone: DropZone, side: CGFloat) -> some View {
        let isMagnetized = hoveringZoneID == zone.id
        let matchedItem = content.items.first { matchedPairs[$0.id] == zone.id }
        let isFilled = matchedItem != nil
        let isHinted = hintPair?.zoneID == zone.id
        let iconSize = max(18, side * 0.26)

        return ZStack {
            RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                .fill(isFilled ? LearningTheme.successSoft : (isMagnetized ? LearningTheme.focusSoft : LearningTheme.slot))
                .overlay {
                    RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                        .strokeBorder(
                            isFilled ? LearningTheme.success : (isMagnetized ? LearningTheme.focus : LearningTheme.border.opacity(0.35)),
                            style: StrokeStyle(
                                lineWidth: isMagnetized ? 4 : LearningTheme.borderWidth,
                                dash: isFilled ? [] : [10, 8]
                            )
                        )
                }
                .scaleEffect(isMagnetized ? 1.06 : 1.0)
                .animation(LearningTheme.forgivingSpring, value: isMagnetized)

            VStack(spacing: side < 80 ? 3 : 6) {
                if let matchedItem {
                    Image(systemName: matchedItem.symbolName)
                        .font(.system(size: iconSize + 4, weight: .semibold))
                        .foregroundStyle(LearningTheme.success)
                        .transition(.scale.combined(with: .opacity))

                    Text(matchedItem.label)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(LearningTheme.success)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else {
                    Image(systemName: zone.symbolName)
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundStyle(isMagnetized ? LearningTheme.focus : LearningTheme.mutedInk.opacity(0.55))

                    Text(zone.label)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(LearningTheme.mutedInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(side < 80 ? 4 : 8)
        }
        .frame(width: side, height: side)
        .hintAura(isActive: isHinted)
        .background {
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ZoneFramePreferenceKey.self,
                        value: [zone.id: geo.frame(in: .named("dndCanvas"))]
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Drop zone \(zone.label)")
        .accessibilityValue(isFilled ? "Filled with \(matchedItem?.label ?? "")" : "Empty")
    }

    // MARK: - Drag Tray

    private func dragTray(availableWidth: CGFloat) -> some View {
        let visibleCount = max(content.items.count, 1)
        let spacing = LearningTheme.adaptiveSpacing(for: availableWidth, comfortable: 18)
        let side = LearningTheme.adaptiveTileSide(
            count: visibleCount,
            availableWidth: availableWidth,
            spacing: spacing,
            ideal: LearningTheme.dragChipSize
        )

        return HStack(spacing: spacing) {
            ForEach(content.items) { item in
                if matchedPairs[item.id] == nil {
                    draggableChip(item, side: side)
                } else {
                    Color.clear
                        .frame(width: side, height: side)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: side + 12)
        .onPreferenceChange(ItemFramePreferenceKey.self) { frames in
            let merged = Self.mergedFrames(itemFrames, with: frames)
            if merged != itemFrames {
                itemFrames = merged
            }
        }
    }

    private func draggableChip(_ item: DragItem, side: CGFloat) -> some View {
        let offset = itemOffsets[item.id] ?? .zero
        let isDragging = draggingItemID == item.id
        let isHinted = hintPair?.itemID == item.id
        let iconSize = max(18, side * 0.30)

        return VStack(spacing: side < 72 ? 3 : 6) {
            Image(systemName: item.symbolName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(LearningTheme.accent)

            Text(item.label)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(side < 72 ? 6 : 10)
        .frame(width: side, height: side)
        .background {
            RoundedRectangle(cornerRadius: LearningTheme.chipCornerRadius, style: .continuous)
                .fill(LearningTheme.surface)
                .shadow(color: .black.opacity(isDragging ? 0.22 : 0.10), radius: isDragging ? 14 : 6, y: isDragging ? 8 : 3)
                .overlay {
                    RoundedRectangle(cornerRadius: LearningTheme.chipCornerRadius, style: .continuous)
                        .strokeBorder(LearningTheme.border.opacity(0.55), lineWidth: LearningTheme.borderWidth)
                }
        }
        .hintAura(isActive: isHinted && !isDragging)
        .scaleEffect(isDragging ? 1.08 : 1.0)
        .offset(offset)
        .zIndex(isDragging ? 100 : 0)
        // Same local DragGesture pattern as morning routine reorder.
        .highPriorityGesture(dragGesture(for: item))
        .background {
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ItemFramePreferenceKey.self,
                        value: [item.id: geo.frame(in: .named("dndCanvas"))]
                    )
            }
        }
        .accessibilityLabel(item.label)
        .accessibilityHint("Drag to matching zone")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Gesture (morning-routine style)

    private func dragGesture(for item: DragItem) -> some Gesture {
        // Local space + low minimumDistance — matches SequenceOrderTaskView.
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard matchedPairs[item.id] == nil else { return }
                if draggingItemID == nil {
                    draggingItemID = item.id
                }
                guard draggingItemID == item.id else { return }
                itemOffsets[item.id] = value.translation
                updateMagneticHover(for: item, translation: value.translation)
            }
            .onEnded { value in
                guard draggingItemID == item.id || draggingItemID == nil else { return }
                resolveDrop(item: item, translation: value.translation)
            }
    }

    private func fingerPoint(for item: DragItem, translation: CGSize) -> CGPoint? {
        guard let frame = itemFrames[item.id] else { return nil }
        // itemFrames are resting (pre-offset) frames; finger ≈ resting center + drag.
        return CGPoint(
            x: frame.midX + translation.width,
            y: frame.midY + translation.height
        )
    }

    private func updateMagneticHover(for item: DragItem, translation: CGSize) {
        guard let finger = fingerPoint(for: item, translation: translation) else {
            if hoveringZoneID != nil { hoveringZoneID = nil }
            return
        }

        let bestZone = nearestOpenZone(to: finger)
        if hoveringZoneID != bestZone {
            withAnimation(LearningTheme.focusFlash) {
                hoveringZoneID = bestZone
            }
        }
    }

    private func resolveDrop(item: DragItem, translation: CGSize) {
        defer {
            draggingItemID = nil
            hoveringZoneID = nil
        }

        let dragDistance = hypot(translation.width, translation.height)

        // Tiny movement / cancelled drag — quietly return home (not a "miss").
        guard dragDistance > 16 else {
            springHome(itemID: item.id)
            return
        }

        guard let finger = fingerPoint(for: item, translation: translation) else {
            // Frames not ready yet — don't punish the child.
            springHome(itemID: item.id)
            return
        }

        guard let zoneID = nearestOpenZone(to: finger),
              let zone = content.zones.first(where: { $0.id == zoneID })
        else {
            registerMiss(itemID: item.id)
            return
        }

        if zone.matchKey == item.matchKey {
            if let zoneFrame = zoneFrames[zoneID], let itemFrame = itemFrames[item.id] {
                withAnimation(LearningTheme.forgivingSpring) {
                    itemOffsets[item.id] = CGSize(
                        width: zoneFrame.midX - itemFrame.midX,
                        height: zoneFrame.midY - itemFrame.midY
                    )
                }
            }

            let token = generation
            SafeAsync.after(0.18) {
                guard token == generation else { return }
                guard matchedPairs[item.id] == nil else { return }
                withAnimation(LearningTheme.successBump) {
                    matchedPairs[item.id] = zoneID
                    occupiedZones.insert(zoneID)
                    itemOffsets[item.id] = .zero
                    successTrigger += 1
                }
                AudioHapticManager.shared.playSuccess()
                onCorrectAttempt?()
            }
        } else {
            registerMiss(itemID: item.id)
        }
    }

    private func registerMiss(itemID: UUID) {
        springHome(itemID: itemID)
        warningTrigger += 1
        AudioHapticManager.shared.playIncorrect()
        onIncorrectAttempt?()
    }

    private func nearestOpenZone(to point: CGPoint) -> UUID? {
        var best: UUID?
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for zone in content.zones where !occupiedZones.contains(zone.id) {
            guard let frame = zoneFrames[zone.id] else { continue }

            // Generous kid-friendly hit pad (zone itself + padding, or near center).
            let padded = frame.insetBy(dx: -24, dy: -24)
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let distance = hypot(point.x - center.x, point.y - center.y)
            let catchRadius = max(LearningTheme.magneticThreshold, max(frame.width, frame.height) * 0.65)

            if padded.contains(point) || distance < catchRadius {
                if distance < bestDistance {
                    bestDistance = distance
                    best = zone.id
                }
            }
        }
        return best
    }

    private func springHome(itemID: UUID) {
        withAnimation(LearningTheme.forgivingSpring) {
            itemOffsets[itemID] = .zero
        }
    }

    /// Avoid preference → state → layout thrash that freezes drag mid-gesture.
    private static func mergedFrames(
        _ current: [UUID: CGRect],
        with frames: [UUID: CGRect]
    ) -> [UUID: CGRect] {
        var next = current
        for (id, frame) in frames {
            if let existing = next[id],
               abs(existing.midX - frame.midX) < 0.5,
               abs(existing.midY - frame.midY) < 0.5,
               abs(existing.width - frame.width) < 0.5,
               abs(existing.height - frame.height) < 0.5 {
                continue
            }
            next[id] = frame
        }
        return next
    }
}

// MARK: - Preference Keys

private struct ZoneFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct ItemFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

#Preview {
    DragAndDropTaskView(content: .previewAnimals, showHint: true)
        .padding()
        .background(LearningTheme.canvas)
}
