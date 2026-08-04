//
//  CurriculumCatalog.swift
//  iSmail
//
//  Multi-step chapter lessons — warm-up → play → wrap-up per themed world.
//

import Foundation

/// Builds age-tailored multi-activity `ChapterLesson` content for each adventure day.
enum CurriculumCatalog: Sendable {

    // MARK: - Public resolve

    static func lesson(
        for chapter: ChapterNode,
        ageYears: Int = 6
    ) -> ChapterLesson {
        let band = AgeBand.from(ageYears: ageYears)
        let blueprint = blueprint(dayNumber: chapter.dayNumber)
        let steps = blueprint.steps.map { step in
            LessonStep(
                id: step.id,
                label: step.label,
                task: tailor(step.task, band: band)
            )
        }

        return ChapterLesson(
            id: chapter.id,
            dayNumber: chapter.dayNumber,
            title: chapter.title,
            subtitle: chapter.subtitle.isEmpty ? blueprint.subtitle : chapter.subtitle,
            world: chapter.world,
            skillTag: blueprint.skillTag,
            primaryType: chapter.type,
            steps: steps,
            rewardCoins: chapter.rewardCoins,
            isChestReward: chapter.isChestReward
        )
    }

    /// Legacy single-task resolve — returns the first step of the chapter.
    static func task(
        for chapter: ChapterNode,
        ageYears: Int = 6
    ) -> TaskNode {
        lesson(for: chapter, ageYears: ageYears).steps.first?.task
            ?? fallbackTask(for: chapter.type)
    }

    // MARK: - Blueprints (day 1…21)

    private struct Blueprint {
        var subtitle: String
        var skillTag: String
        var steps: [LessonStep]
    }

    private static func blueprint(dayNumber: Int) -> Blueprint {
        switch dayNumber {
        case 1: return animalSoundsChapter
        case 2: return fruitFriendsChapter
        case 3: return petHomesChapter
        case 4: return colorWorldChapter
        case 5: return morningStarChapter
        case 6: return bedtimeChapter
        case 7: return snackHeroChapter
        case 8: return readyGoChapter
        case 9: return bigFeelingsChapter
        case 10: return braveFoxChapter
        case 11: return weatherDayChapter
        case 12: return parkAdventureChapter
        case 13: return memoryGardenChapter
        case 14: return kindWishChapter
        case 15: return starWishFinale
        case 16: return letterAHuntChapter
        case 17: return letterFriendsChapter
        case 18: return wordWhispersChapter
        case 19: return countToThreeChapter
        case 20: return numberPartyChapter
        case 21: return mathStarsFinale
        default: return animalSoundsChapter
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
        case .interactiveStorybook:
            break
        case .memoryMatch(let content):
            copy.payload = .memoryMatch(content.limited(to: band.memoryPairs))
        case .letterHunt(let content):
            copy.payload = .letterHunt(content.limited(to: band.choiceCount))
        case .countTap(let content):
            copy.payload = .countTap(content.limited(to: band.choiceCount))
        case .speakAndSay, .traceWrite:
            break
        }
        return copy
    }

    private static func fallbackTask(for type: ActivityType) -> TaskNode {
        switch type {
        case .dragAndDrop: return makeAnimalMatch()
        case .tapAndSelect: return makePickApple()
        case .sequenceOrder: return makeMorningSteps()
        case .storyTime: return makeBraveFoxStory()
        case .interactiveStorybook: return makeMoonlightStorybook()
        case .memoryMatch: return makeMemoryGarden()
        case .letterHunt: return makeLetterHuntA()
        case .countTap: return makeCountStars()
        case .speakAndSay: return makeSpeakApple()
        case .traceWrite: return makeTraceLetterA()
        }
    }

    // MARK: - World 1: Animal Friends

    private static var animalSoundsChapter: Blueprint {
        Blueprint(
            subtitle: "Meet animal pals and match their sounds",
            skillTag: "Animals",
            steps: [
                LessonStep(label: "Warm-up", task: makeWhichAnimalBarks()),
                LessonStep(label: "Match", task: makeAnimalMatch()),
                LessonStep(label: "Memory", task: makeAnimalMemory())
            ]
        )
    }

    private static var fruitFriendsChapter: Blueprint {
        Blueprint(
            subtitle: "Find fruits and match sunny colors",
            skillTag: "Focus",
            steps: [
                LessonStep(label: "Warm-up", task: makePickApple()),
                LessonStep(label: "Match", task: makeColorMatch()),
                LessonStep(label: "Choose", task: makeSnackMilk())
            ]
        )
    }

    private static var petHomesChapter: Blueprint {
        Blueprint(
            subtitle: "Help every pet find a cozy home",
            skillTag: "Matching",
            steps: [
                LessonStep(label: "Warm-up", task: makePickPet()),
                LessonStep(label: "Match", task: makePetHomes()),
                LessonStep(label: "Memory", task: makePetMemory())
            ]
        )
    }

    // MARK: - World 2: Daily Life

    private static var colorWorldChapter: Blueprint {
        Blueprint(
            subtitle: "Colors, shapes, and morning routines",
            skillTag: "Colors",
            steps: [
                LessonStep(label: "Warm-up", task: makeFindStar()),
                LessonStep(label: "Trace", task: makeTraceCircle()),
                LessonStep(label: "Order", task: makeMorningSteps())
            ]
        )
    }

    private static var morningStarChapter: Blueprint {
        Blueprint(
            subtitle: "Start the day with stars and steps",
            skillTag: "Routines",
            steps: [
                LessonStep(label: "Warm-up", task: makeFindStar()),
                LessonStep(label: "Order", task: makeMorningSteps()),
                LessonStep(label: "Choose", task: makePickApple())
            ]
        )
    }

    private static var bedtimeChapter: Blueprint {
        Blueprint(
            subtitle: "A calm bedtime from bath to sleep",
            skillTag: "Routines",
            steps: [
                LessonStep(label: "Warm-up", task: makeSleepyChoice()),
                LessonStep(label: "Order", task: makeBedtimeOrder()),
                LessonStep(label: "Story", task: makeStarWishStory())
            ]
        )
    }

    // MARK: - World 3: Feelings

    private static var snackHeroChapter: Blueprint {
        Blueprint(
            subtitle: "Healthy snacks and happy choices",
            skillTag: "Choices",
            steps: [
                LessonStep(label: "Warm-up", task: makeSnackMilk()),
                LessonStep(label: "Match", task: makePetHomes()),
                LessonStep(label: "Order", task: makeGetReady())
            ]
        )
    }

    private static var readyGoChapter: Blueprint {
        Blueprint(
            subtitle: "Getting ready to go out into the world",
            skillTag: "Sequencing",
            steps: [
                LessonStep(label: "Warm-up", task: makeEmotionHappy()),
                LessonStep(label: "Order", task: makeGetReady()),
                LessonStep(label: "Match", task: makeWeatherMatch())
            ]
        )
    }

    private static var bigFeelingsChapter: Blueprint {
        Blueprint(
            subtitle: "Name feelings and cheer for friends",
            skillTag: "Feelings",
            steps: [
                LessonStep(label: "Warm-up", task: makeEmotionHappy()),
                LessonStep(label: "Choose", task: makeEmotionSurprise()),
                LessonStep(label: "Memory", task: makeFeelingsMemory())
            ]
        )
    }

    // MARK: - World 4: Nature

    private static var braveFoxChapter: Blueprint {
        Blueprint(
            subtitle: "A brave fox story and forest friends",
            skillTag: "Listening",
            steps: [
                LessonStep(label: "Warm-up", task: makeWhichAnimalBarks()),
                LessonStep(label: "Story", task: makeBraveFoxStory()),
                LessonStep(label: "Memory", task: makeAnimalMemory())
            ]
        )
    }

    private static var weatherDayChapter: Blueprint {
        Blueprint(
            subtitle: "Match weather to what you might need",
            skillTag: "Nature",
            steps: [
                LessonStep(label: "Warm-up", task: makeWeatherChoice()),
                LessonStep(label: "Match", task: makeWeatherMatch()),
                LessonStep(label: "Order", task: makeParkDaySteps())
            ]
        )
    }

    private static var parkAdventureChapter: Blueprint {
        Blueprint(
            subtitle: "Pack, play, snack — a perfect park day",
            skillTag: "Adventure",
            steps: [
                LessonStep(label: "Warm-up", task: makePickPet()),
                LessonStep(label: "Order", task: makeParkDaySteps()),
                LessonStep(label: "Match", task: makeWeatherMatch())
            ]
        )
    }

    // MARK: - World 5: Story Stars

    private static var memoryGardenChapter: Blueprint {
        Blueprint(
            subtitle: "Flip cards in a blooming memory garden",
            skillTag: "Memory",
            steps: [
                LessonStep(label: "Warm-up", task: makeFindStar()),
                LessonStep(label: "Memory", task: makeMemoryGarden()),
                LessonStep(label: "Match", task: makeColorMatch())
            ]
        )
    }

    private static var kindWishChapter: Blueprint {
        Blueprint(
            subtitle: "A cozy moonlight storybook before the finale",
            skillTag: "Kindness",
            steps: [
                LessonStep(label: "Warm-up", task: makeEmotionHappy()),
                LessonStep(label: "Order", task: makeBedtimeOrder()),
                LessonStep(label: "Storybook", task: makeMoonlightStorybook())
            ]
        )
    }

    private static var starWishFinale: Blueprint {
        Blueprint(
            subtitle: "The big star-wish story — you made it!",
            skillTag: "Finale",
            steps: [
                LessonStep(label: "Warm-up", task: makeFindStar()),
                LessonStep(label: "Memory", task: makeMemoryGarden()),
                LessonStep(label: "Story", task: makeStarWishStory())
            ]
        )
    }

    // MARK: - World 6: Letter Land

    private static var letterAHuntChapter: Blueprint {
        Blueprint(
            subtitle: "Find A, trace it, and say its friendly sound",
            skillTag: "Phonics",
            steps: [
                LessonStep(label: "Warm-up", task: makeLetterHuntA()),
                LessonStep(label: "Trace", task: makeTraceLetterA()),
                LessonStep(label: "Speak", task: makeSpeakApple())
            ]
        )
    }

    private static var letterFriendsChapter: Blueprint {
        Blueprint(
            subtitle: "Hunt letters and practice tracing",
            skillTag: "ABC",
            steps: [
                LessonStep(label: "Warm-up", task: makeLetterHuntB()),
                LessonStep(label: "Trace", task: makeTraceLetterO()),
                LessonStep(label: "Speak", task: makeSpeakDog())
            ]
        )
    }

    private static var wordWhispersChapter: Blueprint {
        Blueprint(
            subtitle: "Speak everyday words out loud",
            skillTag: "Speaking",
            steps: [
                LessonStep(label: "Warm-up", task: makeSpeakApple()),
                LessonStep(label: "Speak", task: makeSpeakDog()),
                LessonStep(label: "Hunt", task: makeLetterHuntA())
            ]
        )
    }

    // MARK: - World 7: Number Town

    private static var countToThreeChapter: Blueprint {
        Blueprint(
            subtitle: "Count stars and trace friendly numbers",
            skillTag: "Counting",
            steps: [
                LessonStep(label: "Warm-up", task: makeCountStars()),
                LessonStep(label: "Trace", task: makeTraceNumber1()),
                LessonStep(label: "Speak", task: makeSpeakSun())
            ]
        )
    }

    private static var numberPartyChapter: Blueprint {
        Blueprint(
            subtitle: "Bigger counts, tracing & number choices",
            skillTag: "Numbers",
            steps: [
                LessonStep(label: "Warm-up", task: makeCountApples()),
                LessonStep(label: "Trace", task: makeTraceNumber3()),
                LessonStep(label: "Choose", task: makePickApple())
            ]
        )
    }

    private static var mathStarsFinale: Blueprint {
        Blueprint(
            subtitle: "Count, speak & celebrate Number Town",
            skillTag: "Finale",
            steps: [
                LessonStep(label: "Warm-up", task: makeCountHearts()),
                LessonStep(label: "Speak", task: makeSpeakSun()),
                LessonStep(label: "Count", task: makeCountApples())
            ]
        )
    }

    // MARK: - Task factories (shared building blocks)

    private static func makeWhichAnimalBarks() -> TaskNode {
        let dog = SelectChoice(label: "Dog", symbolName: "dog.fill")
        let cat = SelectChoice(label: "Cat", symbolName: "cat.fill")
        let bird = SelectChoice(label: "Bird", symbolName: "bird.fill")
        let fish = SelectChoice(label: "Fish", symbolName: "fish.fill")
        return TaskNode(
            title: "Who Barks?",
            prompt: "Which animal says bark? Tap your answer.",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [cat, bird, dog, fish],
                    correctChoiceID: dog.id
                )
            ),
            rewardCoins: 2
        )
    }

    private static func makeAnimalMatch() -> TaskNode {
        TaskNode(
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
            rewardCoins: 3
        )
    }

    private static func makeAnimalMemory() -> TaskNode {
        TaskNode(
            title: "Animal Pairs",
            prompt: "Flip two cards. Find matching animal friends!",
            activityType: .memoryMatch,
            payload: .memoryMatch(
                MemoryMatchContent(
                    pairs: [
                        MemoryPair(label: "Dog", symbolName: "dog.fill"),
                        MemoryPair(label: "Cat", symbolName: "cat.fill"),
                        MemoryPair(label: "Bird", symbolName: "bird.fill"),
                        MemoryPair(label: "Fish", symbolName: "fish.fill"),
                        MemoryPair(label: "Bunny", symbolName: "hare.fill"),
                        MemoryPair(label: "Bee", symbolName: "ladybug.fill")
                    ]
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makePickApple() -> TaskNode {
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
            rewardCoins: 2
        )
    }

    private static func makeColorMatch() -> TaskNode {
        TaskNode(
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
            rewardCoins: 3
        )
    }

    private static func makeSnackMilk() -> TaskNode {
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
            rewardCoins: 2
        )
    }

    private static func makePickPet() -> TaskNode {
        let puppy = SelectChoice(label: "Puppy", symbolName: "dog.fill")
        let rock = SelectChoice(label: "Rock", symbolName: "circle.fill")
        let cloud = SelectChoice(label: "Cloud", symbolName: "cloud.fill")
        let key = SelectChoice(label: "Key", symbolName: "key.fill")
        return TaskNode(
            title: "Pet Pals",
            prompt: "Which one is a soft puppy friend?",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [rock, puppy, cloud, key],
                    correctChoiceID: puppy.id
                )
            ),
            rewardCoins: 2
        )
    }

    private static func makePetHomes() -> TaskNode {
        TaskNode(
            title: "Pet Homes",
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
            rewardCoins: 3
        )
    }

    private static func makePetMemory() -> TaskNode {
        TaskNode(
            title: "Pet Pairs",
            prompt: "Find matching pet pals!",
            activityType: .memoryMatch,
            payload: .memoryMatch(
                MemoryMatchContent(
                    pairs: [
                        MemoryPair(label: "Fish", symbolName: "fish.fill"),
                        MemoryPair(label: "Bunny", symbolName: "hare.fill"),
                        MemoryPair(label: "Bird", symbolName: "bird.fill"),
                        MemoryPair(label: "Puppy", symbolName: "dog.fill"),
                        MemoryPair(label: "Cat", symbolName: "cat.fill"),
                        MemoryPair(label: "Bee", symbolName: "ladybug.fill")
                    ]
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeFindStar() -> TaskNode {
        let star = SelectChoice(label: "Star", symbolName: "star.fill")
        let moon = SelectChoice(label: "Moon", symbolName: "moon.fill")
        let cloud = SelectChoice(label: "Cloud", symbolName: "cloud.fill")
        let rain = SelectChoice(label: "Rain", symbolName: "cloud.rain.fill")
        let bolt = SelectChoice(label: "Bolt", symbolName: "bolt.fill")
        return TaskNode(
            title: "Find the Star",
            prompt: "Tap the bright shining star!",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [moon, star, cloud, rain, bolt],
                    correctChoiceID: star.id
                )
            ),
            rewardCoins: 2
        )
    }

    private static func makeMorningSteps() -> TaskNode {
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
            rewardCoins: 3
        )
    }

    private static func makeSleepyChoice() -> TaskNode {
        let bed = SelectChoice(label: "Bed", symbolName: "bed.double.fill")
        let bike = SelectChoice(label: "Bike", symbolName: "bicycle")
        let ball = SelectChoice(label: "Ball", symbolName: "sportscourt.fill")
        let car = SelectChoice(label: "Car", symbolName: "car.fill")
        return TaskNode(
            title: "Sleepy Time",
            prompt: "Where do we sleep at night?",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [bike, bed, ball, car],
                    correctChoiceID: bed.id
                )
            ),
            rewardCoins: 2
        )
    }

    private static func makeBedtimeOrder() -> TaskNode {
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
            rewardCoins: 3
        )
    }

    private static func makeGetReady() -> TaskNode {
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
            rewardCoins: 3
        )
    }

    private static func makeEmotionHappy() -> TaskNode {
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
            rewardCoins: 2
        )
    }

    private static func makeEmotionSurprise() -> TaskNode {
        let wow = SelectChoice(label: "Surprised", symbolName: "sparkles")
        let sleepy = SelectChoice(label: "Sleepy", symbolName: "moon.zzz.fill")
        let mad = SelectChoice(label: "Mad", symbolName: "flame.fill")
        let sad = SelectChoice(label: "Sad", symbolName: "cloud.rain.fill")
        return TaskNode(
            title: "Big Surprise",
            prompt: "A birthday cake appears! How do you feel?",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [sleepy, mad, wow, sad],
                    correctChoiceID: wow.id
                )
            ),
            rewardCoins: 2
        )
    }

    private static func makeFeelingsMemory() -> TaskNode {
        TaskNode(
            title: "Feeling Faces",
            prompt: "Match the feeling friends!",
            activityType: .memoryMatch,
            payload: .memoryMatch(
                MemoryMatchContent(
                    pairs: [
                        MemoryPair(label: "Happy", symbolName: "face.smiling.inverse"),
                        MemoryPair(label: "Star", symbolName: "star.fill"),
                        MemoryPair(label: "Heart", symbolName: "heart.fill"),
                        MemoryPair(label: "Sun", symbolName: "sun.max.fill"),
                        MemoryPair(label: "Moon", symbolName: "moon.fill"),
                        MemoryPair(label: "Sparkle", symbolName: "sparkles")
                    ]
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeBraveFoxStory() -> TaskNode {
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
            rewardCoins: 4
        )
    }

    private static func makeWeatherChoice() -> TaskNode {
        let rain = SelectChoice(label: "Rain", symbolName: "cloud.rain.fill")
        let pizza = SelectChoice(label: "Pizza", symbolName: "fork.knife")
        let shoe = SelectChoice(label: "Shoe", symbolName: "figure.walk")
        let book = SelectChoice(label: "Book", symbolName: "book.fill")
        return TaskNode(
            title: "Weather Check",
            prompt: "Which one is rainy weather?",
            activityType: .tapAndSelect,
            payload: .tapAndSelect(
                TapAndSelectContent(
                    choices: [pizza, rain, shoe, book],
                    correctChoiceID: rain.id
                )
            ),
            rewardCoins: 2
        )
    }

    private static func makeWeatherMatch() -> TaskNode {
        TaskNode(
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
            rewardCoins: 3
        )
    }

    private static func makeParkDaySteps() -> TaskNode {
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
            rewardCoins: 3
        )
    }

    private static func makeMemoryGarden() -> TaskNode {
        TaskNode(
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
            rewardCoins: 3
        )
    }

    private static func makeStarWishStory() -> TaskNode {
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
            rewardCoins: 4
        )
    }

    private static func makeMoonlightStorybook() -> TaskNode {
        TaskNode(
            title: "Moonlight Goodnight",
            prompt: "Turn the pages and tap the nighttime friends!",
            activityType: .interactiveStorybook,
            payload: .interactiveStorybook(.moonlightGoodnight),
            rewardCoins: 6
        )
    }

    // MARK: - Letter / Number / Speak factories

    private static func makeLetterHuntA() -> TaskNode {
        TaskNode(
            title: "Find A",
            prompt: "Find the letter A!",
            activityType: .letterHunt,
            payload: .letterHunt(
                LetterHuntContent(
                    targetLetter: "A",
                    choices: ["A", "B", "C", "D"],
                    soundHint: "A says ah — like apple!"
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeLetterHuntB() -> TaskNode {
        TaskNode(
            title: "Find B",
            prompt: "Find the letter B!",
            activityType: .letterHunt,
            payload: .letterHunt(
                LetterHuntContent(
                    targetLetter: "B",
                    choices: ["B", "A", "D", "C"],
                    soundHint: "B says buh — like ball!"
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeLetterHuntC() -> TaskNode {
        TaskNode(
            title: "Find C",
            prompt: "Find the letter C!",
            activityType: .letterHunt,
            payload: .letterHunt(
                LetterHuntContent(
                    targetLetter: "C",
                    choices: ["C", "A", "B", "E"],
                    soundHint: "C says cuh — like cat!"
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeCountStars() -> TaskNode {
        TaskNode(
            title: "Count Stars",
            prompt: "How many stars do you see?",
            activityType: .countTap,
            payload: .countTap(
                CountTapContent(
                    itemCount: 3,
                    symbolName: "star.fill",
                    itemLabel: "stars",
                    numberChoices: [2, 3, 4, 5]
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeCountHearts() -> TaskNode {
        TaskNode(
            title: "Count Hearts",
            prompt: "How many hearts do you see?",
            activityType: .countTap,
            payload: .countTap(
                CountTapContent(
                    itemCount: 2,
                    symbolName: "heart.fill",
                    itemLabel: "hearts",
                    numberChoices: [1, 2, 3, 4]
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeCountApples() -> TaskNode {
        TaskNode(
            title: "Count Apples",
            prompt: "How many apples do you see?",
            activityType: .countTap,
            payload: .countTap(
                CountTapContent(
                    itemCount: 4,
                    symbolName: "apple.logo",
                    itemLabel: "apples",
                    numberChoices: [2, 3, 4, 5]
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeSpeakApple() -> TaskNode {
        TaskNode(
            title: "Say Apple",
            prompt: "Listen, then say apple!",
            activityType: .speakAndSay,
            payload: .speakAndSay(
                SpeakAndSayContent(
                    word: "Apple",
                    symbolName: "apple.logo",
                    coachLine: "Say apple — ap-ple!"
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeTraceLetterA() -> TaskNode {
        TaskNode(
            title: "Trace A",
            prompt: "Trace the letter A with your finger!",
            activityType: .traceWrite,
            payload: .traceWrite(
                TraceWriteContent(
                    glyphID: "A",
                    displayLabel: "A",
                    kind: .uppercaseLetter,
                    coachLine: "Trace A — two mountain sides, then the belt!"
                )
            ),
            rewardCoins: 4
        )
    }

    private static func makeTraceLetterO() -> TaskNode {
        TaskNode(
            title: "Trace O",
            prompt: "Trace the letter O with your finger!",
            activityType: .traceWrite,
            payload: .traceWrite(
                TraceWriteContent(
                    glyphID: "O",
                    displayLabel: "O",
                    kind: .uppercaseLetter,
                    coachLine: "Trace big O — round like a cookie!"
                )
            ),
            rewardCoins: 4
        )
    }

    private static func makeTraceNumber1() -> TaskNode {
        TaskNode(
            title: "Trace 1",
            prompt: "Trace the number 1 with your finger!",
            activityType: .traceWrite,
            payload: .traceWrite(
                TraceWriteContent(
                    glyphID: "1",
                    displayLabel: "1",
                    kind: .number,
                    coachLine: "Trace number 1 — nice and tall!"
                )
            ),
            rewardCoins: 4
        )
    }

    private static func makeTraceNumber3() -> TaskNode {
        TaskNode(
            title: "Trace 3",
            prompt: "Trace the number 3 with your finger!",
            activityType: .traceWrite,
            payload: .traceWrite(
                TraceWriteContent(
                    glyphID: "3",
                    displayLabel: "3",
                    kind: .number,
                    coachLine: "Trace number 3 — two bumpy curves!"
                )
            ),
            rewardCoins: 4
        )
    }

    private static func makeTraceCircle() -> TaskNode {
        TaskNode(
            title: "Trace Circle",
            prompt: "Trace a circle with your finger!",
            activityType: .traceWrite,
            payload: .traceWrite(
                TraceWriteContent(
                    glyphID: "circle",
                    displayLabel: "○",
                    kind: .shape,
                    coachLine: "Trace a circle — round and round!"
                )
            ),
            rewardCoins: 4
        )
    }

    private static func makeSpeakDog() -> TaskNode {
        TaskNode(
            title: "Say Dog",
            prompt: "Listen, then say dog!",
            activityType: .speakAndSay,
            payload: .speakAndSay(
                SpeakAndSayContent(
                    word: "Dog",
                    symbolName: "dog.fill",
                    coachLine: "Say dog — nice and clear!"
                )
            ),
            rewardCoins: 3
        )
    }

    private static func makeSpeakSun() -> TaskNode {
        TaskNode(
            title: "Say Sun",
            prompt: "Listen, then say sun!",
            activityType: .speakAndSay,
            payload: .speakAndSay(
                SpeakAndSayContent(
                    word: "Sun",
                    symbolName: "sun.max.fill",
                    coachLine: "Say sun — bright and warm!"
                )
            ),
            rewardCoins: 3
        )
    }
}

// MARK: - Preview samples

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

extension InteractiveStorybookContent {
    static let moonlightGoodnight: InteractiveStorybookContent = {
        let moon = StoryHotspot(
            emoji: "🌙",
            label: "Moon",
            speakText: "Hello, sleepy moon!",
            x: 0.78,
            y: 0.22
        )
        let teddy = StoryHotspot(
            emoji: "🧸",
            label: "Teddy",
            speakText: "Teddy is ready for a hug.",
            x: 0.28,
            y: 0.68
        )
        let star = StoryHotspot(
            emoji: "⭐️",
            label: "Star",
            speakText: "Twinkle, little star!",
            x: 0.22,
            y: 0.24
        )
        let owl = StoryHotspot(
            emoji: "🦉",
            label: "Owl",
            speakText: "Whoo — soft night hoot!",
            x: 0.72,
            y: 0.62
        )
        let sheep = StoryHotspot(
            emoji: "🐑",
            label: "Sheep",
            speakText: "One fluffy sheep floats by.",
            x: 0.34,
            y: 0.40
        )
        let cloud = StoryHotspot(
            emoji: "☁️",
            label: "Cloud",
            speakText: "A soft pillow cloud.",
            x: 0.70,
            y: 0.55
        )
        let lamp = StoryHotspot(
            emoji: "💡",
            label: "Night light",
            speakText: "Night light, glow gentle and low.",
            x: 0.50,
            y: 0.72
        )

        return InteractiveStorybookContent(
            bookTitle: "Moonlight Goodnight",
            pages: [
                StorybookPage(
                    sceneEmoji: "🛏️",
                    backgroundSymbol: "house.fill",
                    narration: "The bedroom grew quiet. Time for a cozy night story.",
                    seekHint: "Tap the moon and teddy!",
                    hotspots: [moon, teddy]
                ),
                StorybookPage(
                    sceneEmoji: "🪟",
                    backgroundSymbol: "cloud.moon.fill",
                    narration: "Outside the window, night friends blinked hello.",
                    seekHint: "Tap the star and the owl!",
                    hotspots: [star, owl]
                ),
                StorybookPage(
                    sceneEmoji: "💭",
                    backgroundSymbol: "cloud.fill",
                    narration: "Dreams floated like soft clouds across the sky.",
                    seekHint: "Tap the sheep and the cloud!",
                    hotspots: [sheep, cloud]
                ),
                StorybookPage(
                    sceneEmoji: "😴",
                    backgroundSymbol: "moon.zzz.fill",
                    narration: "Eyes grew heavy. One last glow, then sweet dreams.",
                    seekHint: "Tap the night light!",
                    hotspots: [lamp]
                )
            ]
        )
    }()

    static let twilightForest: InteractiveStorybookContent = {
        let firefly = StoryHotspot(
            emoji: "✨",
            label: "Firefly",
            speakText: "A tiny firefly winks!",
            x: 0.30,
            y: 0.30
        )
        let fox = StoryHotspot(
            emoji: "🦊",
            label: "Fox",
            speakText: "Fox tiptoes softly home.",
            x: 0.68,
            y: 0.62
        )
        let tree = StoryHotspot(
            emoji: "🌲",
            label: "Tree",
            speakText: "Tall trees whisper goodnight.",
            x: 0.22,
            y: 0.58
        )
        let moon = StoryHotspot(
            emoji: "🌕",
            label: "Full moon",
            speakText: "The full moon watches kindly.",
            x: 0.76,
            y: 0.24
        )

        return InteractiveStorybookContent(
            bookTitle: "Twilight Forest",
            pages: [
                StorybookPage(
                    sceneEmoji: "🌳",
                    backgroundSymbol: "leaf.fill",
                    narration: "The forest turned purple-blue as evening arrived.",
                    seekHint: "Tap the firefly and the tree!",
                    hotspots: [firefly, tree]
                ),
                StorybookPage(
                    sceneEmoji: "🦊",
                    backgroundSymbol: "moon.stars.fill",
                    narration: "Little Fox found a path lit by moonlight.",
                    seekHint: "Tap Fox and the full moon!",
                    hotspots: [fox, moon]
                ),
                StorybookPage(
                    sceneEmoji: "🏡",
                    backgroundSymbol: "house.fill",
                    narration: "Home at last — warm, quiet, and ready for sleep.",
                    seekHint: "Everything found — turn the page!",
                    hotspots: [],
                    requireAllHotspots: false
                )
            ]
        )
    }()

    static let previewMoonlight = moonlightGoodnight
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

    static let previewInteractiveStorybook = TaskNode(
        title: "Moonlight Goodnight",
        prompt: "Turn the pages and tap the nighttime friends!",
        activityType: .interactiveStorybook,
        payload: .interactiveStorybook(.previewMoonlight),
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

extension ChapterLesson {
    static let previewAnimalFriends = ChapterLesson(
        id: UUID(),
        dayNumber: 1,
        title: "Animal Sounds",
        subtitle: "Meet animal pals and match their sounds",
        world: .animalFriends,
        skillTag: "Animals",
        primaryType: .dragAndDrop,
        steps: [
            LessonStep(label: "Warm-up", task: .previewTapAndSelect),
            LessonStep(label: "Match", task: .previewDragAndDrop),
            LessonStep(label: "Memory", task: .previewMemoryMatch)
        ],
        rewardCoins: 12,
        isChestReward: false
    )
}
