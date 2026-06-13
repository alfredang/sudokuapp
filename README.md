# Sudoku

A native **SwiftUI** Sudoku game for iPhone, built to ship on the App Store. Every puzzle is
generated on-device with a **guaranteed unique solution**, so you never run out and never see
the same grid twice. Rated **18+**.

> Inspired by the Android [sudoku-mobile](https://github.com/alfredang/sudoku-mobile) app,
> rebuilt natively in Swift and adapted for an 18+ audience.

## Features

- **Four difficulty levels** — Easy, Medium, Hard, Expert (45 / 36 / 30 / 25 starting clues).
- **Smart hints on request** — reveal the correct value for any cell; each hint lowers your score.
- **Pencil notes** with optional auto-cleanup of candidates.
- **Conflict & same-number highlighting** (toggleable).
- **Scoring** — base points by level, a speed bonus for beating par, minus hint/mistake penalties.
- **Local score history & stats** — best times and scores per difficulty, stored only on your
  iPhone (`UserDefaults`). Nothing leaves the device.
- **Resume** — quit any time and pick up where you left off.
- **Optional 3-strike challenge mode** for mistake-free runs.
- **18+ age gate** on first launch.

## Tech

- SwiftUI, iOS 16+, iPhone-only, portrait.
- Lightweight MVVM around a single `GameViewModel`.
- Pure-Swift Sudoku engine (randomised MRV backtracking + uniqueness check).
- No third-party dependencies, no network, no permissions.
- Project generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Getting started

```bash
brew install xcodegen          # if needed
xcodegen generate              # creates SudokuApp.xcodeproj from project.yml
open SudokuApp.xcodeproj
```

Or build/run from the CLI:

```bash
xcodebuild -project SudokuApp.xcodeproj -scheme SudokuApp \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Project layout

```
SudokuApp/
  App/         entry point
  Models/      Difficulty, GameSession, navigation
  Engine/      SudokuEngine (generate / solve / uniqueness)
  Utilities/   ScoreCalculator, ScoreStore (local persistence)
  ViewModels/  GameViewModel
  Views/       Root, AgeGate, Home, Game, Board, Completion, Stats, Settings
  Resources/   asset catalog (icon + accent colour)
  Support/     Info.plist, PrivacyInfo.xcprivacy
```

## App Store

Submission is driven by the bundled `app-store-submission` skill
(`.claude/skills/app-store-submission/`). Pre-flight (icon without alpha, encryption flag,
`arm64`, privacy manifest, export options) is already done in-repo. The **18+ age rating** is
set in App Store Connect (UI-only).

## Privacy

100% offline. Scores and game history are stored on-device in `UserDefaults` and are never
transmitted. See [`PrivacyInfo.xcprivacy`](SudokuApp/Support/PrivacyInfo.xcprivacy).
