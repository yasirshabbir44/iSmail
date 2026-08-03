//
//  TaskNode+Previews.swift
//  iSmail
//
//  Sample TaskNode payloads for previews and the Chapter 2 demo shell.
//

import Foundation

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

    static let chapter2Samples: [TaskNode] = [
        .previewDragAndDrop,
        .previewTapAndSelect,
        .previewSequenceOrder
    ]
}
