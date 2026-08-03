# iSmail

A SwiftUI learning app for kids — a playful home hub with short interactive activities, gentle coaching, and coin rewards.

## Features

- **Play world home** — brand-first kids hub with today’s learning path
- **Activity types**
  - **Match** — drag and drop
  - **Choose** — tap and select
  - **Order** — sequence sorting
- **Buddy coach** — on-screen guidance and hints
- **Feedback** — audio, haptics, and reward bursts on success
- **Coins** — simple token balance for completed tasks

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
├── ContentView.swift          # Kids home hub
├── iSmailApp.swift            # App entry
└── Core/
    ├── Activities/            # Task runners (match, choose, order)
    ├── DesignSystem/          # Theme, buddy coach, hint aura
    ├── Feedback/              # Audio, haptics, hints, speech
    ├── Models/                # TaskNode, ActivityType, payloads
    └── Rewards/               # Completion celebrations
```

## License

Private / all rights reserved unless otherwise noted.
