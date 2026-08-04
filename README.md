# iSmail

A SwiftUI learning app for kids — short lessons on a winding adventure map, with ABC/123 practice, gentle coaching, and coin rewards. Designed to feel easy to learn, like LingoKids.

## Features

- **Child profiles** — create, switch, edit, and delete profiles with avatars and age-based difficulty
- **Adventure map** — 21-day winding path; one new chapter unlocks each calendar day
- **Themed worlds** — Animal Friends, Daily Life, Feelings, Nature, Story Stars, **Letter Land**, and **Number Town**
- **Multi-step chapters** — each chapter is warm-up → play → wrap-up (3 short activities)
- **Activity types**
  - **Match** — drag and drop
  - **Choose** — tap and select
  - **Order** — sequence sorting
  - **Story** — listen-and-respond story time
  - **Storybook** — nighttime page-turn stories with tap hotspots
  - **Memory** — flip-card working memory
  - **Letters** — ABC letter hunt with phonics tips
  - **Numbers** — count icons, then tap the right number
  - **Speak** — listen, say the word, confirm
  - **Trace** — real-time stroke tracking for letters, numbers & shapes with visual + audio accuracy feedback
- **Learn anytime** — Letters, Numbers, Words, Songs, Storybook & Trace practice outside the daily path
- **Daily mission** — finish today’s chapter + one practice round for bonus stars
- **Parent corner** — simple progress snapshot (chapters, streak, today’s practice)
- **Age-aware lessons** — little / explorer / adventurer bands tailor choice counts and complexity
- **Buddy coach** — on-screen guidance, hints, speech, and frustration-aware feedback
- **Feel-good zones** — Calm Corner, Pet Shop wardrobe, sticker book, once-a-day reward spin
- **Quick play** — Bubble Pop, Patterns, Focus Pilot, Rhythm Tap, and Memory bonus games
- **Rewards** — coins, chest milestones, stickers, and celebration bursts

## Requirements

- Xcode 26+ (or current Xcode that supports the project’s iOS deployment target)
- iOS 26.5+
- Swift 5

## Getting started

1. Clone the repo:
   ```bash
   git clone https://github.com/yasirshabbir44/iSmail.git
   cd iSmail
   ```
2. Open `iSmail.xcodeproj` in Xcode.
3. Select an iPhone simulator or device.
4. Build and run (`⌘R`).

## Project structure

```
iSmail/
├── ContentView.swift              # Adventure home hub
├── iSmailApp.swift                # App entry + SwiftData
└── Core/
    ├── Activities/                # Chapter runner, task views, Learn Hub, bonus games
    ├── Adventure/                 # Map, chapters, daily unlocks, missions, spin
    ├── DesignSystem/              # Theme, buddy coach, screen chrome
    ├── Feedback/                  # Audio, haptics, hints, speech, idle anchors
    ├── Models/                    # Profiles, curriculum, worlds, practice packs
    ├── Profiles/                  # Profile selection, create/edit, session
    └── Rewards/                   # Stickers, pet shop, parent corner, bursts
```

## License

Private / all rights reserved unless otherwise noted.
