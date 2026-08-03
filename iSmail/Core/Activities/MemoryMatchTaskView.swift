//
//  MemoryMatchTaskView.swift
//  iSmail
//
//  Working-memory flip cards — soft miss feedback, ADHD-friendly pacing.
//

import SwiftUI

struct MemoryMatchTaskView: View {
    let content: MemoryMatchContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var cards: [MemoryCard] = []
    @State private var firstPick: UUID?
    @State private var isResolving = false
    @State private var matchedCount = 0
    @State private var hintPairID: UUID?

    var body: some View {
        GeometryReader { geo in
            let columns = gridColumns(for: cards.count, width: geo.size.width)
            let spacing: CGFloat = geo.size.width < 360 ? 8 : 12

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(cards) { card in
                    cardButton(card)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .onAppear {
            if cards.isEmpty {
                cards = Self.makeDeck(from: content)
            }
        }
        .onChange(of: showHint) { _, active in
            if active {
                hintPairID = cards.first(where: { !$0.isMatched })?.pairID
            } else {
                hintPairID = nil
            }
        }
    }

    // MARK: - Card

    private func cardButton(_ card: MemoryCard) -> some View {
        let faceUp = card.isFaceUp || card.isMatched
        let hintThis = showHint && hintPairID == card.pairID && !card.isMatched

        return Button {
            flip(card)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(faceUp ? LearningTheme.surface : LearningTheme.accent)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                card.isMatched
                                    ? LearningTheme.success
                                    : (hintThis ? LearningTheme.sunshine : Color.white.opacity(0.35)),
                                lineWidth: hintThis || card.isMatched ? 3 : 2
                            )
                    }
                    .shadow(color: LearningTheme.accent.opacity(0.12), radius: 6, y: 3)

                if faceUp {
                    VStack(spacing: 6) {
                        Image(systemName: card.symbolName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(card.isMatched ? LearningTheme.success : LearningTheme.accent)
                        Text(card.label)
                            .font(.system(.caption, design: .rounded).weight(.heavy))
                            .foregroundStyle(LearningTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(6)
                } else {
                    Image(systemName: "sparkle")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(minHeight: LearningTheme.minTouchTarget + 12)
            .rotation3DEffect(.degrees(faceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .hintAura(isActive: hintThis)
            .opacity(card.isMatched ? 0.78 : 1)
        }
        .buttonStyle(KidBounceButtonStyle())
        .disabled(card.isMatched || card.isFaceUp || isResolving)
        .accessibilityLabel(faceUp ? card.label : "Hidden card")
    }

    // MARK: - Logic

    private func flip(_ card: MemoryCard) {
        guard !isResolving, !card.isFaceUp, !card.isMatched else { return }
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }

        withAnimation(LearningTheme.forgivingSpring) {
            cards[index].isFaceUp = true
        }
        AudioHapticManager.shared.playPop()

        if let first = firstPick {
            isResolving = true
            let secondID = card.id
            SafeAsync.after(0.55) {
                resolvePair(firstID: first, secondID: secondID)
            }
        } else {
            firstPick = card.id
        }
    }

    private func resolvePair(firstID: UUID, secondID: UUID) {
        guard
            let i = cards.firstIndex(where: { $0.id == firstID }),
            let j = cards.firstIndex(where: { $0.id == secondID })
        else {
            isResolving = false
            firstPick = nil
            return
        }

        if cards[i].pairID == cards[j].pairID {
            withAnimation(LearningTheme.successBump) {
                cards[i].isMatched = true
                cards[j].isMatched = true
            }
            matchedCount += 1
            AudioHapticManager.shared.playSuccess()
            onCorrectAttempt?()
            hintPairID = nil

            if matchedCount >= content.pairs.count {
                SafeAsync.after(0.4) { onComplete?() }
            }
        } else {
            withAnimation(LearningTheme.forgivingSpring) {
                cards[i].isFaceUp = false
                cards[j].isFaceUp = false
            }
            AudioHapticManager.shared.playIncorrect()
            onIncorrectAttempt?()
        }

        firstPick = nil
        isResolving = false
    }

    private func gridColumns(for count: Int, width: CGFloat) -> [GridItem] {
        let cols = count <= 6 ? 3 : (width < 380 ? 3 : 4)
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: cols)
    }

    private static func makeDeck(from content: MemoryMatchContent) -> [MemoryCard] {
        var deck: [MemoryCard] = []
        for pair in content.pairs {
            deck.append(MemoryCard(pairID: pair.id, label: pair.label, symbolName: pair.symbolName))
            deck.append(MemoryCard(pairID: pair.id, label: pair.label, symbolName: pair.symbolName))
        }
        return deck.shuffled()
    }
}

private struct MemoryCard: Identifiable, Equatable {
    let id: UUID
    let pairID: UUID
    let label: String
    let symbolName: String
    var isFaceUp: Bool
    var isMatched: Bool

    init(pairID: UUID, label: String, symbolName: String) {
        self.id = UUID()
        self.pairID = pairID
        self.label = label
        self.symbolName = symbolName
        self.isFaceUp = false
        self.isMatched = false
    }
}

#Preview {
    MemoryMatchTaskView(content: .previewGarden)
        .padding()
        .background(PlayWorldBackground())
}
