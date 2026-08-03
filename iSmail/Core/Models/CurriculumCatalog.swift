//
//  CurriculumCatalog.swift
//  iSmail
//
//  Unique lesson payloads for the adventure path — animals, routines, stories & memory.
//

import Foundation

/// Builds age-tailored `TaskNode` content for each adventure day.
enum CurriculumCatalog: Sendable {

    // MARK: - Public resolve

    static func task(
        for chapter: ChapterNode,
        ageYears: Int = 6
    ) -> TaskNode {
        let band = AgeBand.from(ageYears: ageYears)
        let raw = lesson(dayNumber: chapter.dayNumber) ?? fallback(for: chapter.type)
        let tailored = tailor(raw, band: band)

        return TaskNode(
            id: chapter.id,
            title: chapter.title,
            prompt: tailored.prompt,
            activityType: tailored.activityType,
            payload: tailored.payload,
            rewardCoins: chapter.rewardCoins
        )
    }

    // MARK: - Day lessons (1…15 unique)

    private static func lesson(dayNumber: Int) -> TaskNode? {
        switch dayNumber {
        case 1: return animalSounds
        case 2: return pickTheApple
        case 3: return morningSteps
        case 4: return colorMatch
        case 5: return findTheStar // chest
        case 6: return bedtimeOrder
        case 7: return petPals
        case 8: return snackTime
        case 9: return getReady
        case 10: return braveLittleFox // chest story
        case 11: return weatherMatch
        case 12: return emotionFaces
        case 13: return parkDaySteps
        case 14: return memoryGarden
        case 15: return starWishStory // chest story
        default: return nil
        }
    }

    private static func fallback(for type: ActivityType) -> TaskNode {
        switch type {
        case .dragAndDrop: return animalSounds
        case .tapAndSelect: return pickTheApple
        case .sequenceOrder: return morningSteps
        case .storyTime: return braveLittleFox
        case .memoryMatch: return memoryGarden
        }
    }

    private static func tailor(_ task: TaskNode, band: AgeBand) -> TaskNode {
        var copy = task
        switch copy.payload {
        case .dragAndDrop(let content):
            let limit = band == .little ? 3 : (band == .explorer ? 3 : 4)
            copy.payload = .dragAndDrop(content.limited(to: min(limit, content.items.count)))
        case .tapAndSelect(let content):
            copy.payload = .tapAndSelect(content.limited(to: band.choiceCount))
        case .sequenceOrder(let content):
            copy.payload = .sequenceOrder(content.limited(to: band.sequenceLength))
        case .storyTime:
            break
        case .memoryMatch(let content):
            copy.payload = .memoryMatch(content.limited(to: band.memoryPairs))
        }
        return copy
    }

    // MARK: - Drag & Drop lessons

    private static let animalSounds = TaskNode(
        title: "Animal Sounds",
        prompt: "Drag each animal to the sound it makes.",
        activityType: .dragAndDrop,
        payload: .dragAndDrop(
            DragAndDropContent(
                items: [
                    DragItem(label: "Dog", symbolName: "dog.fill", matchKey: "dog"),
                    DragItem(label: "Cat", symbolName: "cat.fill", matchKey: "cat"),
                    DragItem(label: "Bird", symbolName: "bird.fill", matchKey: "bird"),
                    DragItem(label: "Cow", symbolName: "hare.fill", matchKey: "cow")
                ],
                zones: [
                    DropZone(label: "Bark", symbolName: "waveform", matchKey: "dog"),
                    DropZone(label: "Meow", symbolName: "music.note", matchKey: "cat"),
                    DropZone(label: "Chirp", symbolName: "microphone.fill", matchKey: "bird"),
                    DropZone(label: "Moo", symbolName: "speaker.wave.2.fill", matchKey: "cow")
                ]
            )
        ),
        rewardCoins: 5
    )

    private static let colorMatch = TaskNode(
        title: "Color Match",
        prompt: "Match each color to its sunny friend.",
        activityType: .dragAndDrop,
        payload: .dragAndDrop(
            DragAndDropContent(
                items: [
                    DragItem(label: "Red", symbolName: "circle.fill", matchKey: "red"),
                    DragItem(label: "Yellow", symbolName: "sun.max.fill", matchKey: "yellow"),
                    DragItem(label: "Green", symbolName: "leaf.fill", matchKey: "green"),
                    DragItem(label: "Blue", symbolName: "drop.fill", matchKey: "blue")
                ],
                zones: [
                    DropZone(label: "Apple", symbolName: "apple.logo", matchKey: "red"),
                    DropZone(label: "Sun", symbolName: "sun.max.fill", matchKey: "yellow"),
                    DropZone(label: "Tree", symbolName: "leaf.circle.fill", matchKey: "green"),
                    DropZone(label: "Sky", symbolName: "cloud.fill", matchKey: "blue")
                ]
            )
        ),
        rewardCoins: 5
    )

    private static let petPals = TaskNode(
        title: "Pet Pals",
        prompt: "Help each pet find its favorite home.",
        activityType: .dragAndDrop,
        payload: .dragAndDrop(
            DragAndDropContent(
                items: [
                    DragItem(label: "Fish", symbolName: "fish.fill", matchKey: "fish"),
                    DragItem(label: "Bunny", symbolName: "hare.fill", matchKey: "bunny"),
                    DragItem(label: "Bird", symbolName: "bird.fill", matchKey: "bird"),
                    DragItem(label: "Puppy", symbolName: "dog.fill", matchKey: "puppy")
                ],
                zones: [
                    DropZone(label: "Tank", symbolName: "drop.fill", matchKey: "fish"),
                    DropZone(label: "Garden", symbolName: "leaf.fill", matchKey: "bunny"),
                    DropZone(label: "Nest", symbolName: "house.fill", matchKey: "bird"),
                    DropZone(label: "Bed", symbolName: "bed.double.fill", matchKey: "puppy")
                ]
            )
        ),
        rewardCoins: 5
    )

    private static let weatherMatch = TaskNode(
        title: "Weather Match",
        prompt: "Match the weather to what you might wear or use.",
        activityType: .dragAndDrop,
        payload: .dragAndDrop(
            DragAndDropContent(
                items: [
                    DragItem(label: "Rain", symbolName: "cloud.rain.fill", matchKey: "rain"),
                    DragItem(label: "Sun", symbolName: "sun.max.fill", matchKey: "sun"),
                    DragItem(label: "Snow", symbolName: "snowflake", matchKey: "snow"),
                    DragItem(label: "Wind", symbolName: "wind", matchKey: "wind")
                ],
                zones: [
                    DropZone(label: "Umbrella", symbolName: "umbrella.fill", matchKey: "rain"),
                    DropZone(label: "Hat", symbolName: "sunglasses", matchKey: "sun"),
                    DropZone(label: "Coat", symbolName: "cloud.snow.fill", matchKey: "snow"),
                    DropZone(label: "Kite", symbolName: "flag.fill", matchKey: "wind")
                ]
            )
        ),
        rewardCoins: 6
    )

    // MARK: - Tap & Select lessons

    private static let pickTheApple: TaskNode = {
        let apple = SelectChoice(label: "Apple", symbolName: "apple.logo")
        let banana = SelectChoice(label: "Banana", symbolName: "leaf.fill")
        let grape = SelectChoice(label: "Grape", symbolName: "circle.grid.2x2.fill")
        let orange = SelectChoice(label: "Orange", symbolName: "sun.max.fill")
        let carrot = SelectChoice(label: "Carrot", symbolName: "leaf.fill")
        return TaskNode(
            title: "Pick the Fruit",
            prompt: "Which one is an apple? Tap your answer.",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [apple, banana, grape, orange, carrot],
                    correctChoiceID: apple.id
                )
            ),
            rewardCoins: 6
        )
    }()

    private static let findTheStar: TaskNode = {
        let star = SelectChoice(label: "Star", symbolName: "star.fill")
        let moon = SelectChoice(label: "Moon", symbolName: "moon.fill")
        let cloud = SelectChoice(label: "Cloud", symbolName: "cloud.fill")
        let rain = SelectChoice(label: "Rain", symbolName: "cloud.rain.fill")
        let bolt = SelectChoice(label: "Bolt", symbolName: "bolt.fill")
        return TaskNode(
            title: "Find the Shape",
            prompt: "Tap the bright shining star!",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [moon, star, cloud, rain, bolt],
                    correctChoiceID: star.id
                )
            ),
            rewardCoins: 6
        )
    }()

    private static let snackTime: TaskNode = {
        let milk = SelectChoice(label: "Milk", symbolName: "cup.and.saucer.fill")
        let soda = SelectChoice(label: "Soda", symbolName: "takeoutbag.and.cup.and.straw.fill")
        let juice = SelectChoice(label: "Juice", symbolName: "wineglass.fill")
        let candy = SelectChoice(label: "Candy", symbolName: "birthday.cake.fill")
        let water = SelectChoice(label: "Water", symbolName: "drop.fill")
        return TaskNode(
            title: "Snack Time",
            prompt: "What helps bones grow strong? Tap milk!",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [soda, candy, milk, juice, water],
                    correctChoiceID: milk.id
                )
            ),
            rewardCoins: 6
        )
    }()

    private static let emotionFaces: TaskNode = {
        let happy = SelectChoice(label: "Happy", symbolName: "face.smiling.inverse")
        let sad = SelectChoice(label: "Sad", symbolName: "cloud.rain.fill")
        let mad = SelectChoice(label: "Mad", symbolName: "flame.fill")
        let sleepy = SelectChoice(label: "Sleepy", symbolName: "moon.zzz.fill")
        let wow = SelectChoice(label: "Surprised", symbolName: "sparkles")
        return TaskNode(
            title: "Feelings",
            prompt: "Someone just got a hug. Which feeling fits?",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [sad, mad, happy, sleepy, wow],
                    correctChoiceID: happy.id
                )
            ),
            rewardCoins: 6
        )
    }()

    // MARK: - Sequence lessons

    private static let morningSteps: TaskNode = {
        let wake = SequenceItem(label: "Wake", symbolName: "sun.horizon.fill", stepNumber: 1)
        let brush = SequenceItem(label: "Brush", symbolName: "face.smiling", stepNumber: 2)
        let dress = SequenceItem(label: "Dress", symbolName: "tshirt.fill", stepNumber: 3)
        let eat = SequenceItem(label: "Eat", symbolName: "fork.knife", stepNumber: 4)
        let bag = SequenceItem(label: "Bag", symbolName: "bag.fill", stepNumber: 5)
        let shuffled = [dress, wake, eat, brush, bag]
        return TaskNode(
            title: "Morning Steps",
            prompt: "Put the morning routine in the right order.",
            activityType: .sequenceOrder,
            payload: .sequenceOrder(
                SequenceOrderContent(
                    items: shuffled,
                    correctOrder: [wake.id, brush.id, dress.id, eat.id, bag.id]
                )
            ),
            rewardCoins: 7
        )
    }()

    private static let bedtimeOrder: TaskNode = {
        let bath = SequenceItem(label: "Bath", symbolName: "drop.fill", stepNumber: 1)
        let pajamas = SequenceItem(label: "PJs", symbolName: "tshirt.fill", stepNumber: 2)
        let brush = SequenceItem(label: "Brush", symbolName: "face.smiling", stepNumber: 3)
        let story = SequenceItem(label: "Story", symbolName: "book.fill", stepNumber: 4)
        let sleep = SequenceItem(label: "Sleep", symbolName: "moon.zzz.fill", stepNumber: 5)
        let shuffled = [story, bath, sleep, pajamas, brush]
        return TaskNode(
            title: "Bedtime Order",
            prompt: "Line up a cozy bedtime — first to last.",
            activityType: .sequenceOrder,
            payload: .sequenceOrder(
                SequenceOrderContent(
                    items: shuffled,
                    correctOrder: [bath.id, pajamas.id, brush.id, story.id, sleep.id]
                )
            ),
            rewardCoins: 7
        )
    }()

    private static let getReady: TaskNode = {
        let shoes = SequenceItem(label: "Shoes", symbolName: "figure.walk", stepNumber: 1)
        let coat = SequenceItem(label: "Coat", symbolName: "cloud.snow.fill", stepNumber: 2)
        let keys = SequenceItem(label: "Keys", symbolName: "key.fill", stepNumber: 3)
        let door = SequenceItem(label: "Door", symbolName: "door.left.hand.open", stepNumber: 4)
        let wave = SequenceItem(label: "Wave", symbolName: "hand.wave.fill", stepNumber: 5)
        let shuffled = [door, shoes, wave, coat, keys]
        return TaskNode(
            title: "Get Ready",
            prompt: "Getting ready to go out — put the steps in order.",
            activityType: .sequenceOrder,
            payload: .sequenceOrder(
                SequenceOrderContent(
                    items: shuffled,
                    correctOrder: [shoes.id, coat.id, keys.id, door.id, wave.id]
                )
            ),
            rewardCoins: 7
        )
    }()

    private static let parkDaySteps: TaskNode = {
        let pack = SequenceItem(label: "Pack", symbolName: "basket.fill", stepNumber: 1)
        let walk = SequenceItem(label: "Walk", symbolName: "figure.walk", stepNumber: 2)
        let play = SequenceItem(label: "Play", symbolName: "sportscourt.fill", stepNumber: 3)
        let snack = SequenceItem(label: "Snack", symbolName: "fork.knife", stepNumber: 4)
        let home = SequenceItem(label: "Home", symbolName: "house.fill", stepNumber: 5)
        let shuffled = [play, home, pack, snack, walk]
        return TaskNode(
            title: "Park Day Steps",
            prompt: "A fun park day — arrange the adventure!",
            activityType: .sequenceOrder,
            payload: .sequenceOrder(
                SequenceOrderContent(
                    items: shuffled,
                    correctOrder: [pack.id, walk.id, play.id, snack.id, home.id]
                )
            ),
            rewardCoins: 7
        )
    }()

    // MARK: - Story lessons

    private static let braveLittleFox: TaskNode = {
        let den = SelectChoice(label: "In a den", symbolName: "house.fill")
        let sea = SelectChoice(label: "In the sea", symbolName: "water.waves")
        let cloud = SelectChoice(label: "On a cloud", symbolName: "cloud.fill")
        return TaskNode(
            title: "Brave Little Fox",
            prompt: "Listen to the story, then answer a tiny question.",
            activityType: .storyTime,
            payload: .storyTime(
                StoryTimeContent(
                    pages: [
                        StoryPage(
                            emoji: "🦊",
                            symbolName: "hare.fill",
                            text: "Little Fox peeked out of a cozy den. Today felt like an adventure day!"
                        ),
                        StoryPage(
                            emoji: "🌲",
                            symbolName: "leaf.fill",
                            text: "The path through the trees looked long. Fox took one brave step… then another."
                        ),
                        StoryPage(
                            emoji: "⭐️",
                            symbolName: "star.fill",
                            text: "A glowing star winked from the sky. Fox whispered, \"I can do hard things.\""
                        ),
                        StoryPage(
                            emoji: "🏡",
                            symbolName: "house.fill",
                            text: "Where did Little Fox begin the adventure?",
                            askLabel: "Where did Fox start?",
                            askChoices: [den, sea, cloud],
                            correctChoiceID: den.id
                        )
                    ]
                )
            ),
            rewardCoins: 8
        )
    }()

    private static let starWishStory: TaskNode = {
        let wish = SelectChoice(label: "A kind wish", symbolName: "heart.fill")
        let shout = SelectChoice(label: "A loud shout", symbolName: "speaker.wave.3.fill")
        let race = SelectChoice(label: "A race car", symbolName: "car.fill")
        return TaskNode(
            title: "Star Wish",
            prompt: "A bedtime story about kindness — tap Next to continue.",
            activityType: .storyTime,
            payload: .storyTime(
                StoryTimeContent(
                    pages: [
                        StoryPage(
                            emoji: "🌙",
                            symbolName: "moon.stars.fill",
                            text: "The moon hung like a silver cookie. Stars began to blink hello."
                        ),
                        StoryPage(
                            emoji: "✨",
                            symbolName: "sparkles",
                            text: "One tiny star floated closer and asked, \"What kind wish do you hold?\""
                        ),
                        StoryPage(
                            emoji: "💛",
                            symbolName: "heart.fill",
                            text: "\"I wish everyone feels calm and brave,\" said the child. The star sparkled brighter."
                        ),
                        StoryPage(
                            emoji: "🌟",
                            symbolName: "star.circle.fill",
                            text: "What did the child wish for?",
                            askLabel: "What was the wish?",
                            askChoices: [shout, wish, race],
                            correctChoiceID: wish.id
                        )
                    ]
                )
            ),
            rewardCoins: 8
        )
    }()

    // MARK: - Memory lessons

    private static let memoryGarden = TaskNode(
        title: "Memory Garden",
        prompt: "Flip two cards. Find matching flower friends!",
        activityType: .memoryMatch,
        payload: .memoryMatch(
            MemoryMatchContent(
                pairs: [
                    MemoryPair(label: "Rose", symbolName: "heart.fill"),
                    MemoryPair(label: "Sun", symbolName: "sun.max.fill"),
                    MemoryPair(label: "Leaf", symbolName: "leaf.fill"),
                    MemoryPair(label: "Bee", symbolName: "ladybug.fill"),
                    MemoryPair(label: "Moon", symbolName: "moon.fill"),
                    MemoryPair(label: "Drop", symbolName: "drop.fill")
                ]
            )
        ),
        rewardCoins: 8
    )
}

// MARK: - Preview samples (kept for Xcode previews)

extension DragAndDropContent {
    static let previewAnimals = DragAndDropContent(
        items: [
            DragItem(label: "Dog", symbolName: "dog.fill", matchKey: "dog"),
            DragItem(label: "Cat", symbolName: "cat.fill", matchKey: "cat"),
            DragItem(label: "Bird", symbolName: "bird.fill", matchKey: "bird")
        ],
        zones: [
            DropZone(label: "Bark", symbolName: "waveform", matchKey: "dog"),
            DropZone(label: "Meow", symbolName: "music.note", matchKey: "cat"),
            DropZone(label: "Chirp", symbolName: "microphone.fill", matchKey: "bird")
        ]
    )
}

extension TapAndSelectContent {
    static let previewFruit: TapAndSelectContent = {
        let apple = SelectChoice(label: "Apple", symbolName: "apple.logo")
        let banana = SelectChoice(label: "Banana", symbolName: "leaf.fill")
        let grape = SelectChoice(label: "Grape", symbolName: "circle.grid.2x2.fill")
        let orange = SelectChoice(label: "Orange", symbolName: "sun.max.fill")
        return TapAndSelectContent(
            choices: [apple, banana, grape, orange],
            correctChoiceID: apple.id
        )
    }()
}

extension SequenceOrderContent {
    static let previewMorning: SequenceOrderContent = {
        let wake = SequenceItem(label: "Wake", symbolName: "sun.horizon.fill", stepNumber: 1)
        let brush = SequenceItem(label: "Brush", symbolName: "face.smiling", stepNumber: 2)
        let dress = SequenceItem(label: "Dress", symbolName: "tshirt.fill", stepNumber: 3)
        let eat = SequenceItem(label: "Eat", symbolName: "fork.knife", stepNumber: 4)
        let shuffled = [dress, wake, eat, brush]
        return SequenceOrderContent(
            items: shuffled,
            correctOrder: [wake.id, brush.id, dress.id, eat.id]
        )
    }()
}

extension StoryTimeContent {
    static let previewFox: StoryTimeContent = {
        let den = SelectChoice(label: "Den", symbolName: "house.fill")
        let sea = SelectChoice(label: "Sea", symbolName: "water.waves")
        return StoryTimeContent(
            pages: [
                StoryPage(emoji: "🦊", symbolName: "hare.fill", text: "Little Fox woke up ready to explore."),
                StoryPage(emoji: "⭐️", symbolName: "star.fill", text: "A star winked and said hello."),
                StoryPage(
                    emoji: "🏡",
                    symbolName: "house.fill",
                    text: "Where did Fox live?",
                    askLabel: "Where?",
                    askChoices: [den, sea],
                    correctChoiceID: den.id
                )
            ]
        )
    }()
}

extension MemoryMatchContent {
    static let previewGarden = MemoryMatchContent(
        pairs: [
            MemoryPair(label: "Sun", symbolName: "sun.max.fill"),
            MemoryPair(label: "Leaf", symbolName: "leaf.fill"),
            MemoryPair(label: "Bee", symbolName: "ladybug.fill")
        ]
    )
}

extension TaskNode {
    static let previewDragAndDrop = TaskNode(
        title: "Animal Sounds",
        prompt: "Drag each animal to the sound it makes.",
        activityType: .dragAndDrop,
        payload: .dragAndDrop(.previewAnimals),
        rewardCoins: 5
    )

    static let previewTapAndSelect = TaskNode(
        title: "Pick the Fruit",
        prompt: "Which one is an apple? Tap your answer.",
        activityType: .tapAndSelect,
        payload: .tapAndSelect(.previewFruit),
        rewardCoins: 6
    )

    static let previewSequenceOrder = TaskNode(
        title: "Morning Steps",
        prompt: "Put the morning routine in the right order.",
        activityType: .sequenceOrder,
        payload: .sequenceOrder(.previewMorning),
        rewardCoins: 7
    )

    static let previewStoryTime = TaskNode(
        title: "Brave Little Fox",
        prompt: "Listen to the story, then answer a tiny question.",
        activityType: .storyTime,
        payload: .storyTime(.previewFox),
        rewardCoins: 8
    )

    static let previewMemoryMatch = TaskNode(
        title: "Memory Garden",
        prompt: "Flip two cards. Find matching friends!",
        activityType: .memoryMatch,
        payload: .memoryMatch(.previewGarden),
        rewardCoins: 8
    )

    static let chapter2Samples: [TaskNode] = [
        .previewDragAndDrop,
        .previewTapAndSelect,
        .previewSequenceOrder,
        .previewStoryTime,
        .previewMemoryMatch
    ]
}
