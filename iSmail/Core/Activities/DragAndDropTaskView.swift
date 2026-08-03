//
//  DragAndDropTaskView.swift
//  iSmail
//
//  Matching engine with magnetic drop zones, forgiving spring reset, hints & audio.
//

import SwiftUI

struct DragAndDropTaskView: View {
    let content: DragAndDropContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var itemOrigins: [UUID: CGPoint] = [:]
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
        let side = LearningTheme.adaptiveTileSide(
            count: count,
            availableWidth: availableWidth,
            spacing: spacing,
            ideal: LearningTheme.dropZoneSize
        )

        return Group {
            if count > 3, availableWidth < 400 {
                let gridSide = LearningTheme.adaptiveTileSide(
                    count: 2,
                    availableWidth: availableWidth,
                    spacing: spacing,
                    ideal: LearningTheme.dropZoneSize
                )
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: spacing),
                        GridItem(.flexible(), spacing: spacing)
                    ],
                    spacing: spacing
                ) {
                    ForEach(content.zones) { zone in
                        dropZoneView(zone, side: gridSide)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                HStack(spacing: spacing) {
                    ForEach(content.zones) { zone in
                        dropZoneView(zone, side: side)
                    }
                }
                .frame(maxWidth: .infinity)
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
        .onPreferenceChange(ZoneFramePreferenceKey.self) { frames in
            zoneFrames.merge(frames, uniquingKeysWith: { $1 })
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
        .onPreferenceChange(ItemFramePreferenceKey.self) { frames in
            itemFrames.merge(frames, uniquingKeysWith: { $1 })
            if itemOrigins[item.id] == nil, let frame = frames[item.id] {
                itemOrigins[item.id] = CGPoint(x: frame.midX, y: frame.midY)
            }
        }
        .accessibilityLabel(item.label)
        .accessibilityHint("Drag to matching zone")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Gesture

    private func dragGesture(for item: DragItem) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("dndCanvas"))
            .onChanged { value in
                guard matchedPairs[item.id] == nil else { return }
                if draggingItemID == nil {
                    draggingItemID = item.id
                }
                guard draggingItemID == item.id else { return }
                itemOffsets[item.id] = value.translation
                updateMagneticHover(finger: value.location)
            }
            .onEnded { value in
                guard draggingItemID == item.id || draggingItemID == nil else { return }
                resolveDrop(item: item, at: value.location, translation: value.translation)
            }
    }

    private func updateMagneticHover(finger: CGPoint) {
        var bestZone: UUID?
        var bestDistance = LearningTheme.magneticThreshold

        for zone in content.zones where !occupiedZones.contains(zone.id) {
            guard let frame = zoneFrames[zone.id] else { continue }
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let distance = hypot(finger.x - center.x, finger.y - center.y)
            if distance < bestDistance {
                bestDistance = distance
                bestZone = zone.id
            }
        }

        if hoveringZoneID != bestZone {
            withAnimation(LearningTheme.focusFlash) {
                hoveringZoneID = bestZone
            }
        }
    }

    private func currentChipOrigin(for item: DragItem) -> CGPoint? {
        if let origin = itemOrigins[item.id] {
            return origin
        }
        guard let frame = itemFrames[item.id] else { return nil }
        let offset = itemOffsets[item.id] ?? .zero
        return CGPoint(x: frame.midX - offset.width, y: frame.midY - offset.height)
    }

    private func resolveDrop(item: DragItem, at location: CGPoint, translation: CGSize) {
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

        guard let zoneID = nearestOpenZone(to: location),
              let zone = content.zones.first(where: { $0.id == zoneID })
        else {
            registerMiss(itemID: item.id)
            return
        }

        if zone.matchKey == item.matchKey {
            if let frame = zoneFrames[zoneID], let origin = currentChipOrigin(for: item) {
                withAnimation(LearningTheme.forgivingSpring) {
                    itemOffsets[item.id] = CGSize(
                        width: frame.midX - origin.x,
                        height: frame.midY - origin.y
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
        var bestDistance = LearningTheme.magneticThreshold

        for zone in content.zones where !occupiedZones.contains(zone.id) {
            guard let frame = zoneFrames[zone.id] else { continue }
            if frame.insetBy(dx: -12, dy: -12).contains(point) {
                return zone.id
            }
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let distance = hypot(point.x - center.x, point.y - center.y)
            if distance < bestDistance {
                bestDistance = distance
                best = zone.id
            }
        }
        return best
    }

    private func springHome(itemID: UUID) {
        withAnimation(LearningTheme.forgivingSpring) {
            itemOffsets[itemID] = .zero
        }
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
