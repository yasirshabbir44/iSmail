//
//  TraceWriteTaskView.swift
//  iSmail
//
//  Real-time stroke tracking for letters, numbers, and shapes with visual + audio accuracy feedback.
//

import SwiftUI

struct TraceWriteTaskView: View {
    let content: TraceWriteContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var engine: TraceScoringEngine
    @State private var liveStroke: [CGPoint] = []
    @State private var committedStrokes: [[CGPoint]] = []
    @State private var liveAccuracy: Double = 1
    @State private var isDrawing = false
    @State private var isLocked = false
    @State private var showSuccess = false
    @State private var softMissPulse = false
    @State private var successTrigger = 0
    @State private var warningTrigger = 0
    @State private var progressMilestone = 0
    @State private var coachNudge = ""
    @State private var generation = 0

    init(
        content: TraceWriteContent,
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
        _engine = State(initialValue: TraceScoringEngine(content: content))
    }

    private var tint: Color {
        LearningTheme.activityTint(for: .traceWrite)
    }

    private var strokeInk: Color {
        if liveAccuracy >= 0.72 { return LearningTheme.success }
        if liveAccuracy >= 0.45 { return LearningTheme.sunshine }
        return LearningTheme.coral
    }

    var body: some View {
        VStack(spacing: 14) {
            headerChip
            accuracyMeter
            canvasCard
            controlsRow
            if !coachNudge.isEmpty {
                Text(coachNudge)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(softMissPulse ? LearningTheme.coral : LearningTheme.mutedInk)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.warning, trigger: warningTrigger)
        .onAppear {
            engine = TraceScoringEngine(content: content)
            SpeechManager.shared.speak(text: content.coachLine)
        }
        .onDisappear { generation += 1 }
        .onChange(of: showHint) { _, active in
            if active, !isLocked {
                coachNudge = "Start at the glowing dot and follow the dashes!"
            }
        }
    }

    // MARK: - Header

    private var headerChip: some View {
        HStack(spacing: 10) {
            Text(content.displayLabel)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(tint)
                .frame(minWidth: 56)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LearningTheme.activitySoft(for: .traceWrite))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(content.kind.displayName)
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .foregroundStyle(tint)
                Text("Stroke \(min(engine.activeStrokeIndex + 1, max(engine.strokeCount, 1))) of \(max(engine.strokeCount, 1))")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trace \(content.displayLabel), \(content.kind.displayName)")
    }

    private var accuracyMeter: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Path")
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.mutedInk)
                Spacer()
                Text("\(Int((engine.coverage * 100).rounded()))%")
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LearningTheme.slot)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(8, geo.size.width * engine.coverage))
                        .animation(.easeOut(duration: 0.12), value: engine.coverage)
                }
            }
            .frame(height: 10)

            HStack(spacing: 8) {
                accuracyDot(label: "On track", color: LearningTheme.success, active: liveAccuracy >= 0.72 || !isDrawing)
                accuracyDot(label: "Careful", color: LearningTheme.sunshine, active: isDrawing && liveAccuracy >= 0.45 && liveAccuracy < 0.72)
                accuracyDot(label: "Off path", color: LearningTheme.coral, active: isDrawing && liveAccuracy < 0.45)
            }
        }
    }

    private func accuracyDot(label: String, color: Color, active: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(active ? 1 : 0.35))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(active ? LearningTheme.ink : LearningTheme.mutedInk)
        }
    }

    // MARK: - Canvas

    private var canvasCard: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let origin = CGPoint(
                x: (geo.size.width - side) / 2,
                y: (geo.size.height - side) / 2
            )
            // Capture scoring state so Canvas redraws as the child traces.
            let activeIndex = engine.activeStrokeIndex
            let coverage = engine.coverage
            let visitedMap = engine.visited
            let strokeColor = strokeInk
            let livePoints = liveStroke
            let committed = committedStrokes

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                LearningTheme.activitySoft(for: .traceWrite).opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(tint.opacity(0.22), lineWidth: 2)
                    }

                Canvas { context, _ in
                    let box = CGRect(x: origin.x, y: origin.y, width: side, height: side)
                    drawGuide(
                        context: context,
                        in: box,
                        activeIndex: activeIndex,
                        visitedMap: visitedMap
                    )
                    drawCommitted(context: context, strokes: committed, in: box)
                    drawLive(context: context, points: livePoints, color: strokeColor, in: box)
                    if showSuccess {
                        drawSuccessHalo(context: context, in: box)
                    }
                }
                .allowsHitTesting(false)
                .id("\(activeIndex)-\(Int(coverage * 100))-\(livePoints.count)-\(committed.count)")

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(drawGesture(origin: origin, side: side))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 260, maxHeight: 340)
        .shadow(color: tint.opacity(0.12), radius: 12, y: 6)
        .scaleEffect(softMissPulse ? 0.985 : 1)
        .animation(.easeInOut(duration: 0.12), value: softMissPulse)
    }

    private func drawGesture(origin: CGPoint, side: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isLocked, side > 1 else { return }
                let unit = toUnit(value.location, origin: origin, side: side)
                guard unit.x >= -0.05, unit.x <= 1.05, unit.y >= -0.05, unit.y <= 1.05 else { return }

                if !isDrawing {
                    isDrawing = true
                    liveStroke = [unit]
                    coachNudge = ""
                } else {
                    // Skip near-duplicate samples to keep stroke smooth and cheap.
                    if let last = liveStroke.last, hypot(unit.x - last.x, unit.y - last.y) < 0.008 {
                        return
                    }
                    liveStroke.append(unit)
                }

                let sample = engine.score(point: unit)
                liveAccuracy = sample.instantAccuracy
                maybeAnnounceProgress()
                maybeSoftOffPathCoach(sample.instantAccuracy)
            }
            .onEnded { _ in
                guard !isLocked else { return }
                finishStroke()
            }
    }

    // MARK: - Drawing helpers

    private func drawGuide(
        context: GraphicsContext,
        in box: CGRect,
        activeIndex: Int,
        visitedMap: [[Bool]]
    ) {
        guard let glyph = TraceGlyphLibrary.glyph(for: content.glyphID) else { return }

        for (index, stroke) in glyph.strokes.enumerated() {
            let mapped = stroke.points.map { fromUnit($0, in: box) }
            guard mapped.count >= 2 else {
                if let only = mapped.first {
                    context.fill(
                        Path(ellipseIn: CGRect(x: only.x - 5, y: only.y - 5, width: 10, height: 10)),
                        with: .color(tint.opacity(index == activeIndex ? 0.85 : 0.35))
                    )
                }
                continue
            }

            var path = Path()
            path.addLines(mapped)
            context.stroke(
                path,
                with: .color(tint.opacity(index < activeIndex ? 0.22 : (index == activeIndex ? 0.45 : 0.28))),
                style: StrokeStyle(
                    lineWidth: index == activeIndex ? 14 : 10,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: index == activeIndex ? [10, 10] : [6, 10]
                )
            )

            if index == activeIndex || showHint {
                let samples = engine.checkpoints[safe: index] ?? []
                let visited = visitedMap[safe: index] ?? []
                for (sampleIndex, sample) in samples.enumerated() {
                    guard visited.indices.contains(sampleIndex), visited[sampleIndex] else { continue }
                    let pt = fromUnit(sample, in: box)
                    context.fill(
                        Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)),
                        with: .color(LearningTheme.success.opacity(0.55))
                    )
                }
            }
        }

        // Start cue for the active stroke.
        if !isLocked,
           let start = engine.checkpoints[safe: activeIndex]?.first {
            let pt = fromUnit(start, in: box)
            let glow = showHint || engine.coverage < 0.08
            context.fill(
                Path(ellipseIn: CGRect(x: pt.x - 10, y: pt.y - 10, width: 20, height: 20)),
                with: .color(LearningTheme.sunshine.opacity(glow ? 0.85 : 0.45))
            )
            context.stroke(
                Path(ellipseIn: CGRect(x: pt.x - 10, y: pt.y - 10, width: 20, height: 20)),
                with: .color(.white.opacity(0.9)),
                lineWidth: 3
            )
        }
    }

    private func drawCommitted(context: GraphicsContext, strokes: [[CGPoint]], in box: CGRect) {
        for stroke in strokes {
            let mapped = stroke.map { fromUnit($0, in: box) }
            guard mapped.count >= 2 else { continue }
            var path = Path()
            path.addLines(mapped)
            context.stroke(
                path,
                with: .color(LearningTheme.success.opacity(0.9)),
                style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawLive(
        context: GraphicsContext,
        points: [CGPoint],
        color: Color,
        in box: CGRect
    ) {
        let mapped = points.map { fromUnit($0, in: box) }
        guard mapped.count >= 2 else {
            if let only = mapped.first {
                context.fill(
                    Path(ellipseIn: CGRect(x: only.x - 6, y: only.y - 6, width: 12, height: 12)),
                    with: .color(color)
                )
            }
            return
        }
        var path = Path()
        path.addLines(mapped)
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawSuccessHalo(context: GraphicsContext, in box: CGRect) {
        let inset = box.insetBy(dx: 8, dy: 8)
        context.stroke(
            Path(roundedRect: inset, cornerRadius: 18),
            with: .color(LearningTheme.success.opacity(0.55)),
            style: StrokeStyle(lineWidth: 4, dash: [8, 6])
        )
    }

    // MARK: - Controls

    private var controlsRow: some View {
        HStack(spacing: 12) {
            Button {
                clearBoard(speak: true)
            } label: {
                Label("Clear", systemImage: "arrow.counterclockwise")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: LearningTheme.minTouchTarget - 4)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LearningTheme.slot)
                    }
            }
            .buttonStyle(KidBounceButtonStyle())
            .disabled(isLocked)
            .opacity(isLocked ? 0.45 : 1)

            Button {
                SpeechManager.shared.speak(text: content.coachLine)
            } label: {
                Label("Hear", systemImage: "speaker.wave.2.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: LearningTheme.minTouchTarget - 4)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(tint)
                    }
            }
            .buttonStyle(KidBounceButtonStyle())
        }
    }

    // MARK: - Scoring flow

    private func finishStroke() {
        isDrawing = false
        // Allow a tap for single-point strokes (dot on lowercase i).
        guard liveStroke.count >= 1 else {
            liveStroke = []
            return
        }

        committedStrokes.append(liveStroke)
        liveStroke = []

        switch engine.handleStrokeLift() {
        case .advancedToNextStroke:
            coachNudge = "Nice! Now the next stroke."
            AudioHapticManager.shared.playHint()
            SpeechManager.shared.speak(text: "Next stroke!")
        case .readyToEvaluate:
            evaluateCompletion()
        case .needsMoreTracing:
            coachNudge = "Keep going — follow more of the dashes!"
            // Not a hard miss; gentle nudge only.
        }
    }

    private func evaluateCompletion() {
        if engine.passes(content: content) {
            completeSuccess()
            return
        }

        // Soft miss — keep ink so kids can continue improving.
        softMissPulse = true
        warningTrigger += 1
        AudioHapticManager.shared.playIncorrect()
        onIncorrectAttempt?()

        if engine.coverage < content.passCoverage {
            coachNudge = "Almost! Trace more of the dashed line."
            SpeechManager.shared.speak(text: "Trace a little more of the line.")
        } else {
            coachNudge = "Stay closer to the guide path — try again!"
            SpeechManager.shared.speak(text: "Stay closer to the path.")
        }

        let gen = generation
        SafeAsync.after(0.35) {
            guard gen == generation else { return }
            softMissPulse = false
        }
    }

    private func completeSuccess() {
        guard !isLocked else { return }
        isLocked = true
        showSuccess = true
        successTrigger += 1
        liveAccuracy = 1
        coachNudge = "Beautiful writing!"
        AudioHapticManager.shared.playSuccess()
        SpeechManager.shared.speak(text: "\(content.displayLabel)! Beautiful writing!")
        onCorrectAttempt?()
        let gen = generation
        SafeAsync.after(0.65) {
            guard gen == generation else { return }
            onComplete?()
        }
    }

    private func clearBoard(speak: Bool) {
        guard !isLocked else { return }
        engine.reset()
        liveStroke = []
        committedStrokes = []
        liveAccuracy = 1
        isDrawing = false
        softMissPulse = false
        progressMilestone = 0
        coachNudge = speak ? "Fresh start — follow the dashes!" : ""
        if speak {
            SpeechManager.shared.speak(text: "Let's try again.")
        }
    }

    private func maybeAnnounceProgress() {
        let milestone = Int(engine.coverage * 4) // 0,1,2,3,4 → 0/25/50/75/100
        guard milestone > progressMilestone, milestone < 4 else { return }
        progressMilestone = milestone
        AudioHapticManager.shared.playHint()
    }

    private func maybeSoftOffPathCoach(_ accuracy: Double) {
        guard accuracy < 0.35, coachNudge.isEmpty || coachNudge.contains("closer") == false else { return }
        coachNudge = "Follow the dashed line a bit closer…"
    }

    // MARK: - Coordinate map

    private func toUnit(_ point: CGPoint, origin: CGPoint, side: CGFloat) -> CGPoint {
        CGPoint(
            x: (point.x - origin.x) / side,
            y: (point.y - origin.y) / side
        )
    }

    private func fromUnit(_ unit: CGPoint, in box: CGRect) -> CGPoint {
        CGPoint(
            x: box.minX + unit.x * box.width,
            y: box.minY + unit.y * box.height
        )
    }
}

// MARK: - Scoring engine

@Observable
@MainActor
final class TraceScoringEngine {
    private(set) var checkpoints: [[CGPoint]] = []
    private(set) var visited: [[Bool]] = []
    private(set) var activeStrokeIndex = 0
    private(set) var coverage: Double = 0
    private(set) var meanAccuracy: Double = 1

    private var accuracySamples: [Double] = []
    private let hitRadius: CGFloat = 0.11
    private let content: TraceWriteContent

    var strokeCount: Int { checkpoints.count }

    init(content: TraceWriteContent) {
        self.content = content
        rebuild()
    }

    func reset() {
        activeStrokeIndex = 0
        coverage = 0
        meanAccuracy = 1
        accuracySamples = []
        visited = checkpoints.map { Array(repeating: false, count: $0.count) }
    }

    struct SampleResult {
        var instantAccuracy: Double
        var coverage: Double
    }

    enum StrokeLiftResult {
        /// Active stroke covered enough; moved to the next guide stroke.
        case advancedToNextStroke
        /// Final stroke covered enough — ready for pass/fail check.
        case readyToEvaluate
        /// Not enough of the guide covered yet — keep tracing.
        case needsMoreTracing
    }

    func score(point: CGPoint) -> SampleResult {
        guard checkpoints.indices.contains(activeStrokeIndex) else {
            return SampleResult(instantAccuracy: 0, coverage: coverage)
        }

        let samples = checkpoints[activeStrokeIndex]
        // Single-point strokes (dot on "i") — treat a near tap as full coverage.
        if samples.count == 1 {
            let d = hypot(point.x - samples[0].x, point.y - samples[0].y)
            if d <= hitRadius * 1.35 {
                visited[activeStrokeIndex][0] = true
            }
            let instant = max(0, min(1, 1 - Double(d / (hitRadius * 2.2))))
            recordAccuracy(instant)
            recomputeCoverage()
            return SampleResult(instantAccuracy: instant, coverage: coverage)
        }

        var best = CGFloat.greatestFiniteMagnitude
        var bestIndex = 0
        for (index, sample) in samples.enumerated() {
            let d = hypot(point.x - sample.x, point.y - sample.y)
            if d < best {
                best = d
                bestIndex = index
            }
        }

        // Mark nearby samples as visited (a small window so thick fingers count).
        let window = 2
        let lower = max(0, bestIndex - window)
        let upper = min(samples.count - 1, bestIndex + window)
        if best <= hitRadius {
            for index in lower...upper {
                visited[activeStrokeIndex][index] = true
            }
        }

        let instant = max(0, min(1, 1 - Double(best / (hitRadius * 2.2))))
        recordAccuracy(instant)
        recomputeCoverage()

        return SampleResult(instantAccuracy: instant, coverage: coverage)
    }

    /// Call when the finger lifts to advance strokes or decide evaluation.
    func handleStrokeLift() -> StrokeLiftResult {
        guard checkpoints.indices.contains(activeStrokeIndex) else { return .readyToEvaluate }
        let covered = strokeCoverage(at: activeStrokeIndex)
        // Dots need less travel; multi-point strokes need a clearer pass over the guide.
        let threshold: Double = (checkpoints[activeStrokeIndex].count <= 2) ? 0.55 : 0.62
        guard covered >= threshold else { return .needsMoreTracing }

        if activeStrokeIndex < checkpoints.count - 1 {
            activeStrokeIndex += 1
            return .advancedToNextStroke
        }
        return .readyToEvaluate
    }

    func passes(content: TraceWriteContent) -> Bool {
        recomputeCoverage()
        // Require every stroke to have meaningful coverage.
        let strokesOK = checkpoints.indices.allSatisfy { strokeCoverage(at: $0) >= 0.55 }
        return strokesOK
            && coverage >= content.passCoverage
            && meanAccuracy >= content.passAccuracy
    }

    private func recordAccuracy(_ instant: Double) {
        accuracySamples.append(instant)
        if accuracySamples.count > 80 {
            accuracySamples.removeFirst(accuracySamples.count - 80)
        }
        meanAccuracy = accuracySamples.reduce(0, +) / Double(max(accuracySamples.count, 1))
    }

    private func rebuild() {
        guard let glyph = TraceGlyphLibrary.glyph(for: content.glyphID) else {
            checkpoints = []
            visited = []
            return
        }
        checkpoints = glyph.sampledCheckpoints()
        visited = checkpoints.map { Array(repeating: false, count: $0.count) }
        activeStrokeIndex = 0
        coverage = 0
        meanAccuracy = 1
        accuracySamples = []
    }

    private func recomputeCoverage() {
        let total = visited.reduce(0) { $0 + $1.count }
        guard total > 0 else {
            coverage = 0
            return
        }
        let hit = visited.reduce(0) { $0 + $1.filter(\.self).count }
        coverage = Double(hit) / Double(total)
    }

    private func strokeCoverage(at index: Int) -> Double {
        guard visited.indices.contains(index), !visited[index].isEmpty else { return 0 }
        let hit = visited[index].filter(\.self).count
        return Double(hit) / Double(visited[index].count)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview("Trace A") {
    TraceWriteTaskView(
        content: TraceWriteContent(
            glyphID: "A",
            displayLabel: "A",
            kind: .uppercaseLetter,
            coachLine: "Trace the letter A — start at the glowing dot!"
        )
    )
    .padding()
    .background(PlayWorldBackground())
}
