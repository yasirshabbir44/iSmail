//
//  LearnPracticeCatalog.swift
//  iSmail
//
//  Anytime practice packs — Letters, Numbers, Words & Songs (LingoKids-style).
//

import Foundation

/// Categories kids can practice anytime outside the daily chapter path.
enum LearnPracticeCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case letters
    case numbers
    case words
    case songs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .letters: "Letters"
        case .numbers: "Numbers"
        case .words: "Words"
        case .songs: "Songs"
        }
    }

    var subtitle: String {
        switch self {
        case .letters: "ABC hunt & sounds"
        case .numbers: "Count & tap 1-2-3"
        case .words: "Say everyday words"
        case .songs: "Sing along gently"
        }
    }

    var symbolName: String {
        switch self {
        case .letters: "textformat"
        case .numbers: "number.circle.fill"
        case .words: "mouth.fill"
        case .songs: "music.note.list"
        }
    }

    var tintRed: Double {
        switch self {
        case .letters: 0.20
        case .numbers: 0.95
        case .words: 0.35
        case .songs: 0.55
        }
    }

    var tintGreen: Double {
        switch self {
        case .letters: 0.55
        case .numbers: 0.45
        case .words: 0.72
        case .songs: 0.40
        }
    }

    var tintBlue: Double {
        switch self {
        case .letters: 0.90
        case .numbers: 0.55
        case .words: 0.55
        case .songs: 0.78
        }
    }
}

/// Builds age-scaled practice rounds for the Learn Hub.
enum LearnPracticeCatalog: Sendable {

    static func tasks(for category: LearnPracticeCategory, ageYears: Int) -> [TaskNode] {
        let band = AgeBand.from(ageYears: ageYears)
        switch category {
        case .letters:
            return letterRound(band: band).map { tailor($0, band: band) }
        case .numbers:
            return numberRound(band: band).map { tailor($0, band: band) }
        case .words:
            return wordRound(band: band)
        case .songs:
            return [songTask(band: band)]
        }
    }

    // MARK: - Letters

    private static let alphabet: [(letter: String, hint: String)] = [
        ("A", "A says ah — like apple!"),
        ("B", "B says buh — like ball!"),
        ("C", "C says cuh — like cat!"),
        ("D", "D says duh — like dog!"),
        ("E", "E says eh — like egg!"),
        ("F", "F says fff — like fish!"),
        ("G", "G says guh — like grape!"),
        ("H", "H says huh — like hat!"),
        ("I", "I says ih — like igloo!"),
        ("J", "J says juh — like jam!"),
        ("K", "K says kuh — like kite!"),
        ("L", "L says lll — like leaf!")
    ]

    private static func letterRound(band: AgeBand) -> [TaskNode] {
        let count = band == .little ? 3 : (band == .explorer ? 4 : 5)
        let pool = alphabet.shuffled().prefix(count)
        return pool.map { entry in
            let distractors = alphabet.map(\.letter).filter { $0 != entry.letter }.shuffled().prefix(3)
            let choices = ([entry.letter] + distractors).shuffled()
            return TaskNode(
                title: "Find \(entry.letter)",
                prompt: "Find the letter \(entry.letter)!",
                activityType: .letterHunt,
                payload: .letterHunt(
                    LetterHuntContent(
                        targetLetter: entry.letter,
                        choices: Array(choices),
                        soundHint: entry.hint
                    )
                ),
                rewardCoins: 3
            )
        }
    }

    // MARK: - Numbers

    private static func numberRound(band: AgeBand) -> [TaskNode] {
        let maxCount = band == .little ? 4 : (band == .explorer ? 6 : 8)
        let rounds = band == .little ? 3 : 4
        let themes: [(String, String)] = [
            ("star.fill", "stars"),
            ("heart.fill", "hearts"),
            ("apple.logo", "apples"),
            ("fish.fill", "fish"),
            ("leaf.fill", "leaves"),
            ("hare.fill", "bunnies")
        ]

        return (0..<rounds).map { index in
            let count = Int.random(in: 1...maxCount)
            let theme = themes[index % themes.count]
            var choices = Array(Set([count, max(1, count - 1), min(maxCount, count + 1), Int.random(in: 1...maxCount)]))
            while choices.count < 3 {
                choices.append(Int.random(in: 1...maxCount))
                choices = Array(Set(choices))
            }
            return TaskNode(
                title: "Count the \(theme.1)",
                prompt: "How many \(theme.1) do you see?",
                activityType: .countTap,
                payload: .countTap(
                    CountTapContent(
                        itemCount: count,
                        symbolName: theme.0,
                        itemLabel: theme.1,
                        numberChoices: choices.sorted()
                    )
                ),
                rewardCoins: 3
            )
        }
    }

    // MARK: - Words

    private static let vocab: [(String, String, String)] = [
        ("Apple", "apple.logo", "Say apple — ap-ple!"),
        ("Dog", "dog.fill", "Say dog — nice and clear!"),
        ("Sun", "sun.max.fill", "Say sun — bright and warm!"),
        ("Ball", "circle.fill", "Say ball — buh-all!"),
        ("Cat", "cat.fill", "Say cat — soft and sweet!"),
        ("Fish", "fish.fill", "Say fish — fff-ish!"),
        ("Star", "star.fill", "Say star — twinkle time!"),
        ("Heart", "heart.fill", "Say heart — kind and soft!"),
        ("Tree", "leaf.fill", "Say tree — tall and green!"),
        ("Bird", "bird.fill", "Say bird — chirp chirp!")
    ]

    private static func wordRound(band: AgeBand) -> [TaskNode] {
        let count = band == .little ? 3 : 4
        return vocab.shuffled().prefix(count).map { entry in
            TaskNode(
                title: entry.0,
                prompt: "Listen, then say \(entry.0)!",
                activityType: .speakAndSay,
                payload: .speakAndSay(
                    SpeakAndSayContent(
                        word: entry.0,
                        symbolName: entry.1,
                        coachLine: entry.2
                    )
                ),
                rewardCoins: 3
            )
        }
    }

    // MARK: - Songs

    private static func songTask(band: AgeBand) -> TaskNode {
        let pages: [StoryPage]
        if band == .little {
            pages = [
                StoryPage(emoji: "☀️", symbolName: "sun.max.fill", text: "Twinkle, twinkle, little star…"),
                StoryPage(emoji: "✨", symbolName: "sparkles", text: "How I wonder what you are!"),
                StoryPage(emoji: "🌟", symbolName: "star.fill", text: "Up above the world so high…")
            ]
        } else {
            let askYes = SelectChoice(label: "A star!", symbolName: "star.fill")
            let askMoon = SelectChoice(label: "A moon", symbolName: "moon.fill")
            let askSun = SelectChoice(label: "A sun", symbolName: "sun.max.fill")
            pages = [
                StoryPage(emoji: "☀️", symbolName: "sun.max.fill", text: "Twinkle, twinkle, little star…"),
                StoryPage(emoji: "✨", symbolName: "sparkles", text: "How I wonder what you are!"),
                StoryPage(emoji: "🌟", symbolName: "star.fill", text: "Like a diamond in the sky."),
                StoryPage(
                    emoji: "🎤",
                    symbolName: "music.mic",
                    text: "What was twinkling in our song?",
                    askLabel: "What twinkled?",
                    askChoices: [askYes, askMoon, askSun],
                    correctChoiceID: askYes.id
                )
            ]
        }

        return TaskNode(
            title: "Twinkle Song",
            prompt: "Sing along with your buddy!",
            activityType: .storyTime,
            payload: .storyTime(StoryTimeContent(pages: pages)),
            rewardCoins: 5
        )
    }

    private static func tailor(_ task: TaskNode, band: AgeBand) -> TaskNode {
        var copy = task
        switch copy.payload {
        case .letterHunt(let content):
            copy.payload = .letterHunt(content.limited(to: band.choiceCount))
        case .countTap(let content):
            copy.payload = .countTap(content.limited(to: band.choiceCount))
        default:
            break
        }
        return copy
    }
}
