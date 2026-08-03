//
//  DailySpinSheet.swift
//  iSmail
//
//  Once-a-day reward wheel modal — spring spin + coin award.
//

import SwiftUI

struct DailySpinSheet: View {
    var onClaim: (Int) -> Void
    var onDismiss: () -> Void

    @State private var rotation: Double = 0
    @State private var isSpinning = false
    @State private var hasSpun = false
    @State private var awardedCoins = 0
    @State private var resultLabel = ""
    @State private var successTrigger = 0

    private let slices: [SpinSlice] = SpinSlice.defaultSlices
    private let wheelSize: CGFloat = 260

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer(minLength: 0)
                ScreenCloseButton(accessibilityLabel: "Close daily spin") {
                    skipOrFinish()
                }
            }

            Text("Daily Spin!")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .accessibilityAddTraits(.isHeader)

            Text(hasSpun ? resultCopy : "Tap SPIN for today's surprise!")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .multilineTextAlignment(.center)
                .animation(LearningTheme.forgivingSpring, value: hasSpun)

            ZStack {
                // Pointer
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(LearningTheme.coral)
                    .offset(y: -wheelSize * 0.52)
                    .zIndex(2)
                    .shadow(color: LearningTheme.coral.opacity(0.35), radius: 4, y: 2)

                RewardWheel(slices: slices)
                    .frame(width: wheelSize, height: wheelSize)
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: LearningTheme.accent.opacity(0.22), radius: 16, y: 8)

                Circle()
                    .fill(LearningTheme.surface)
                    .frame(width: 54, height: 54)
                    .overlay {
                        Circle()
                            .strokeBorder(LearningTheme.sunshine, lineWidth: 4)
                    }
                    .overlay {
                        Image(systemName: "star.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(LearningTheme.sunshine)
                    }
                    .zIndex(1)
            }
            .frame(height: wheelSize + 36)
            .padding(.vertical, 4)

            if hasSpun {
                Button(action: finish) {
                    Text("Yay! +\(awardedCoins)")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            LearningTheme.success,
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                        )
                        .shadow(color: LearningTheme.success.opacity(0.35), radius: 12, y: 6)
                }
                .buttonStyle(KidBounceButtonStyle())
                .accessibilityLabel("Collect \(awardedCoins) coins")
            } else {
                Button(action: spin) {
                    Text("SPIN")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            isSpinning ? LearningTheme.mutedInk : LearningTheme.coral,
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                        )
                        .shadow(color: LearningTheme.coral.opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(KidBounceButtonStyle())
                .disabled(isSpinning)
                .accessibilityLabel("Spin the daily reward wheel")
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LearningTheme.surface.opacity(0.97))
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.18), radius: 28, y: 14)
        }
        .padding(.horizontal, 20)
        .sensoryFeedback(.success, trigger: successTrigger)
    }

    private var resultCopy: String {
        if resultLabel.isEmpty { return "You won!" }
        return "You landed on \(resultLabel)!"
    }

    private func spin() {
        guard !isSpinning, !hasSpun else { return }
        isSpinning = true

        let index = Int.random(in: 0..<slices.count)
        let slice = slices[index]
        let sliceAngle = 360.0 / Double(slices.count)
        // Pointer is at the top; rotate so the chosen slice center lands under it.
        let targetCenter = sliceAngle * (Double(index) + 0.5)
        let spins = Double.random(in: 4...6)
        let finalRotation = spins * 360 + (360 - targetCenter)

        withAnimation(.easeOut(duration: 2.5)) {
            rotation += finalRotation
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_550_000_000)
            let coins = slice.resolvedCoins()
            awardedCoins = coins
            resultLabel = slice.displayName
            hasSpun = true
            isSpinning = false
            AudioHapticManager.shared.playSuccess()
            successTrigger &+= 1
        }
    }

    private func finish() {
        onClaim(awardedCoins)
        onDismiss()
    }

    private func skipOrFinish() {
        guard !isSpinning else { return }
        if hasSpun {
            finish()
        } else {
            onDismiss()
        }
    }
}

// MARK: - Slice model

private struct SpinSlice: Identifiable {
    let id = UUID()
    let displayName: String
    let color: Color
    let kind: Kind

    enum Kind {
        case coins(Int)
        case star
        case mysteryGift
    }

    func resolvedCoins() -> Int {
        switch kind {
        case .coins(let value): return value
        case .star: return 15
        case .mysteryGift: return [10, 20, 30, 40].randomElement() ?? 20
        }
    }

    static let defaultSlices: [SpinSlice] = [
        SpinSlice(displayName: "10 Coins", color: LearningTheme.accent, kind: .coins(10)),
        SpinSlice(displayName: "20 Coins", color: LearningTheme.coral, kind: .coins(20)),
        SpinSlice(displayName: "50 Coins", color: LearningTheme.sunshine, kind: .coins(50)),
        SpinSlice(displayName: "Star", color: Color(red: 0.55, green: 0.40, blue: 0.78), kind: .star),
        SpinSlice(displayName: "Mystery Gift", color: LearningTheme.success, kind: .mysteryGift),
        SpinSlice(displayName: "5 Coins", color: Color(red: 0.42, green: 0.58, blue: 0.95), kind: .coins(5))
    ]
}

// MARK: - Wheel drawing

private struct RewardWheel: View {
    let slices: [SpinSlice]

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = side / 2
            let sliceAngle = Angle.degrees(360 / Double(max(slices.count, 1)))

            ZStack {
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    let start = sliceAngle * Double(index) - .degrees(90)
                    PieSlice(startAngle: start, endAngle: start + sliceAngle)
                        .fill(slice.color)
                        .overlay {
                            PieSlice(startAngle: start, endAngle: start + sliceAngle)
                                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                        }

                    let mid = start + sliceAngle / 2
                    Text(shortLabel(for: slice))
                        .font(.system(size: side * 0.055, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                        .rotationEffect(mid + .degrees(90))
                        .offset(
                            x: cos(mid.radians) * radius * 0.58,
                            y: sin(mid.radians) * radius * 0.58
                        )
                }

                Circle()
                    .strokeBorder(Color.white, lineWidth: 5)
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func shortLabel(for slice: SpinSlice) -> String {
        switch slice.kind {
        case .coins(let value): return "\(value)"
        case .star: return "★"
        case .mysteryGift: return "?"
        }
    }
}

private struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        PlayWorldBackground()
        Color.black.opacity(0.35).ignoresSafeArea()
        DailySpinSheet(onClaim: { _ in }, onDismiss: {})
    }
}
