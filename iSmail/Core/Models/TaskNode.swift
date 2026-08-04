//
//  TaskNode.swift
//  iSmail
//
//  Unified learning-task model for the Core Learning Engine.
//

import Foundation

/// A single interactive learning unit the runner can present.
struct TaskNode: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var prompt: String
    var activityType: ActivityType
    var payload: ActivityPayload
    /// Coins awarded to the child's token balance on completion.
    var rewardCoins: Int

    init(
        id: UUID = UUID(),
        title: String,
        prompt: String,
        activityType: ActivityType,
        payload: ActivityPayload,
        rewardCoins: Int = 5
    ) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.activityType = activityType
        self.payload = payload
        self.rewardCoins = max(0, rewardCoins)
    }
}

// MARK: - Payload

/// Type-safe content for each activity kind.
enum ActivityPayload: Hashable, Sendable {
    case dragAndDrop(DragAndDropContent)
    case tapAndSelect(TapAndSelectContent)
    case sequenceOrder(SequenceOrderContent)
    case storyTime(StoryTimeContent)
    case interactiveStorybook(InteractiveStorybookContent)
    case memoryMatch(MemoryMatchContent)
    case letterHunt(LetterHuntContent)
    case countTap(CountTapContent)
    case speakAndSay(SpeakAndSayContent)
    case traceWrite(TraceWriteContent)
}

// MARK: - Drag & Drop

struct DragAndDropContent: Hashable, Sendable {
    var items: [DragItem]
    var zones: [DropZone]

    /// Trims to `count` pairs while keeping items/zones matched.
    func limited(to count: Int) -> DragAndDropContent {
        let n = max(1, min(count, items.count, zones.count))
        let keptKeys = Set(items.prefix(n).map(\.matchKey))
        return DragAndDropContent(
            items: Array(items.prefix(n)),
            zones: zones.filter { keptKeys.contains($0.matchKey) }.prefix(n).map { $0 }
        )
    }
}

struct DragItem: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var symbolName: String
    /// Must match a `DropZone.matchKey` for a correct drop.
    var matchKey: String

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String,
        matchKey: String
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
        self.matchKey = matchKey
    }
}

struct DropZone: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var symbolName: String
    var matchKey: String

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String,
        matchKey: String
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
        self.matchKey = matchKey
    }
}

// MARK: - Tap & Select

struct TapAndSelectContent: Hashable, Sendable {
    var choices: [SelectChoice]
    /// ID of the correct choice.
    var correctChoiceID: UUID

    /// Keeps the correct answer and fills with distractors up to `count`.
    func limited(to count: Int) -> TapAndSelectContent {
        let n = max(2, count)
        guard let correct = choices.first(where: { $0.id == correctChoiceID }) else { return self }
        var pool = choices.filter { $0.id != correctChoiceID }
        pool.shuffle()
        let picked = Array(([correct] + pool).prefix(n)).shuffled()
        return TapAndSelectContent(choices: picked, correctChoiceID: correct.id)
    }
}

struct SelectChoice: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var symbolName: String

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
    }
}

// MARK: - Sequence Order

struct SequenceOrderContent: Hashable, Sendable {
    /// Items shown in a shuffled starting order (3–5 recommended).
    var items: [SequenceItem]
    /// Correct order by item IDs from first → last.
    var correctOrder: [UUID]

    func limited(to count: Int) -> SequenceOrderContent {
        let n = max(2, min(count, items.count))
        let ordered = correctOrder.compactMap { id in items.first { $0.id == id } }
        let kept = Array(ordered.prefix(n))
        var shuffled = kept
        shuffled.shuffle()
        // Avoid accidentally starting already-correct for little kids.
        if shuffled.map(\.id) == kept.map(\.id), kept.count > 1 {
            shuffled.swapAt(0, kept.count - 1)
        }
        return SequenceOrderContent(
            items: shuffled,
            correctOrder: kept.map(\.id)
        )
    }
}

struct SequenceItem: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var symbolName: String
    var stepNumber: Int

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String,
        stepNumber: Int
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
        self.stepNumber = stepNumber
    }
}

// MARK: - Story Time

struct StoryTimeContent: Hashable, Sendable {
    var pages: [StoryPage]
}

struct StoryPage: Identifiable, Hashable, Sendable {
    let id: UUID
    var emoji: String
    var symbolName: String
    var text: String
    /// Optional comprehension question on the last interactive beat.
    var askLabel: String?
    var askChoices: [SelectChoice]?
    var correctChoiceID: UUID?

    init(
        id: UUID = UUID(),
        emoji: String,
        symbolName: String,
        text: String,
        askLabel: String? = nil,
        askChoices: [SelectChoice]? = nil,
        correctChoiceID: UUID? = nil
    ) {
        self.id = id
        self.emoji = emoji
        self.symbolName = symbolName
        self.text = text
        self.askLabel = askLabel
        self.askChoices = askChoices
        self.correctChoiceID = correctChoiceID
    }

    var hasQuestion: Bool {
        askChoices != nil && correctChoiceID != nil
    }
}

// MARK: - Interactive Storybook

/// Page-turn bedtime story with tap hotspots on each illustrated page.
struct InteractiveStorybookContent: Hashable, Sendable {
    var bookTitle: String
    var pages: [StorybookPage]
}

struct StorybookPage: Identifiable, Hashable, Sendable {
    let id: UUID
    /// Large scene emoji shown as the page illustration centerpiece.
    var sceneEmoji: String
    /// Soft SF Symbol atmosphere behind the scene.
    var backgroundSymbol: String
    /// Narration caption + TTS for the page.
    var narration: String
    /// Coach line while required hotspots remain (e.g. "Tap the sleepy moon!").
    var seekHint: String
    /// Interactive tap targets placed on the illustration (normalized 0…1).
    var hotspots: [StoryHotspot]
    /// When true, every required hotspot must be found before turning the page.
    var requireAllHotspots: Bool

    init(
        id: UUID = UUID(),
        sceneEmoji: String,
        backgroundSymbol: String,
        narration: String,
        seekHint: String = "Tap the glowing friends!",
        hotspots: [StoryHotspot] = [],
        requireAllHotspots: Bool = true
    ) {
        self.id = id
        self.sceneEmoji = sceneEmoji
        self.backgroundSymbol = backgroundSymbol
        self.narration = narration
        self.seekHint = seekHint
        self.hotspots = hotspots
        self.requireAllHotspots = requireAllHotspots
    }

    var requiredHotspotIDs: [UUID] {
        hotspots.filter(\.isRequired).map(\.id)
    }
}

struct StoryHotspot: Identifiable, Hashable, Sendable {
    let id: UUID
    var emoji: String
    var label: String
    /// Spoken when the child discovers this hotspot.
    var speakText: String
    /// Horizontal position on the illustration (0 = leading, 1 = trailing).
    var x: Double
    /// Vertical position on the illustration (0 = top, 1 = bottom).
    var y: Double
    /// Counts toward unlocking the next page when `requireAllHotspots` is on.
    var isRequired: Bool

    init(
        id: UUID = UUID(),
        emoji: String,
        label: String,
        speakText: String,
        x: Double,
        y: Double,
        isRequired: Bool = true
    ) {
        self.id = id
        self.emoji = emoji
        self.label = label
        self.speakText = speakText
        self.x = min(max(x, 0.08), 0.92)
        self.y = min(max(y, 0.08), 0.92)
        self.isRequired = isRequired
    }
}

// MARK: - Memory Match

struct MemoryMatchContent: Hashable, Sendable {
    var pairs: [MemoryPair]

    func limited(to pairCount: Int) -> MemoryMatchContent {
        MemoryMatchContent(pairs: Array(pairs.prefix(max(2, pairCount))))
    }
}

struct MemoryPair: Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var symbolName: String

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
    }
}

// MARK: - Letter Hunt (ABC)

struct LetterHuntContent: Hashable, Sendable {
    /// Uppercase target letter, e.g. "A".
    var targetLetter: String
    /// Letter cards shown to the child (includes the target).
    var choices: [String]
    /// Friendly phonics tip spoken by the buddy.
    var soundHint: String

    func limited(to count: Int) -> LetterHuntContent {
        let n = max(2, count)
        guard choices.contains(targetLetter) else { return self }
        var pool = choices.filter { $0 != targetLetter }
        pool.shuffle()
        let picked = Array(([targetLetter] + pool).prefix(n)).shuffled()
        return LetterHuntContent(
            targetLetter: targetLetter,
            choices: picked,
            soundHint: soundHint
        )
    }
}

// MARK: - Count & Tap (123)

struct CountTapContent: Hashable, Sendable {
    /// How many icons are on screen.
    var itemCount: Int
    var symbolName: String
    var itemLabel: String
    /// Number buttons offered (includes the correct count).
    var numberChoices: [Int]

    var correctAnswer: Int { itemCount }

    func limited(to choiceCount: Int) -> CountTapContent {
        let n = max(2, choiceCount)
        var pool = numberChoices.filter { $0 != itemCount }
        pool.shuffle()
        let picked = Array(([itemCount] + pool).prefix(n)).sorted()
        return CountTapContent(
            itemCount: itemCount,
            symbolName: symbolName,
            itemLabel: itemLabel,
            numberChoices: picked
        )
    }
}

// MARK: - Speak & Say

struct SpeakAndSayContent: Hashable, Sendable {
    var word: String
    var symbolName: String
    /// Short coaching line, e.g. "Say apple — ap-ple!"
    var coachLine: String
}

// MARK: - Trace & Write

enum TraceGlyphKind: String, Hashable, Sendable {
    case uppercaseLetter
    case lowercaseLetter
    case number
    case shape

    var displayName: String {
        switch self {
        case .uppercaseLetter: "Uppercase"
        case .lowercaseLetter: "Lowercase"
        case .number: "Number"
        case .shape: "Shape"
        }
    }
}

/// Content for finger-tracing letters, numbers, and shapes.
struct TraceWriteContent: Hashable, Sendable {
    /// Glyph key resolved by `TraceGlyphLibrary` (e.g. "A", "a", "3", "circle").
    var glyphID: String
    var displayLabel: String
    var kind: TraceGlyphKind
    /// Friendly spoken coaching line.
    var coachLine: String
    /// Fraction of guide samples that must be visited (0…1).
    var passCoverage: Double
    /// Average on-path accuracy that must be met (0…1).
    var passAccuracy: Double

    init(
        glyphID: String,
        displayLabel: String,
        kind: TraceGlyphKind,
        coachLine: String,
        passCoverage: Double = 0.72,
        passAccuracy: Double = 0.48
    ) {
        self.glyphID = glyphID
        self.displayLabel = displayLabel
        self.kind = kind
        self.coachLine = coachLine
        self.passCoverage = min(max(passCoverage, 0.55), 0.92)
        self.passAccuracy = min(max(passAccuracy, 0.35), 0.85)
    }
}
