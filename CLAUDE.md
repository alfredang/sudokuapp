# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

A native SwiftUI Sudoku game for iPhone, built to ship on the App Store. Puzzles are
generated on-device with a guaranteed unique solution. Four difficulty levels, smart hints,
pencil notes, scoring, and full game history kept locally. Rated **18+** with an in-app age
gate. Modelled on the structure and conventions of the RunTrack GPS app.

## Build & run

This project uses **XcodeGen** — the `.xcodeproj` is generated, not committed. Always edit
`project.yml` (never the generated project) and re-run `xcodegen generate` after adding,
removing, or moving source files.

```bash
xcodegen generate                       # regenerate SudokuApp.xcodeproj from project.yml
open SudokuApp.xcodeproj                 # or build from the CLI:
xcodebuild -project SudokuApp.xcodeproj -scheme SudokuApp \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Run in the simulator and screenshot (the home/game screens sit behind the one-time 18+ gate):

```bash
xcrun simctl boot "iPhone 17"
APP=$(find ~/Library/Developer/Xcode/DerivedData/SudokuApp-*/Build/Products/Debug-iphonesimulator -maxdepth 1 -name SudokuApp.app | head -1)
xcrun simctl install "iPhone 17" "$APP" && xcrun simctl launch "iPhone 17" com.tertiaryinfotech.sudokuapp
xcrun simctl io "iPhone 17" screenshot /tmp/shot.png
# To skip the age gate, seed the default in the app's data container before launch:
#   PlistBuddy -c "Add :SudokuApp.ageConfirmed bool true" <container>/Library/Preferences/com.tertiaryinfotech.sudokuapp.plist
```

**Tests:** there is no XCTest target. The Sudoku engine is pure and self-contained, so the
quickest sanity check is to copy its core into a standalone `swift file.swift` script and
assert each difficulty yields a unique solution (`solutionCount == 1`) — this was used to
validate generation. Add a real test target via `project.yml` if coverage is needed.

## Architecture

Lightweight MVVM. A single `GameViewModel` (`@MainActor ObservableObject`) is the source of
truth; `RootView` switches on an `AppScreen` enum instead of a NavigationStack.

```
SudokuApp/
  App/SudokuApp.swift            @main; auto-pauses the timer when backgrounded
  Models/
    AppScreen.swift              navigation enum + GameAlert
    Difficulty.swift             easy/medium/hard/expert → clues, par time, base score
    GameSession.swift            completed-game record + ActiveGame (resume snapshot)
  Engine/
    SudokuEngine.swift           pure logic: generate / solve / uniqueness (MRV backtracking)
  Utilities/
    ScoreCalculator.swift        score = base + speed bonus − hint/mistake penalties
    ScoreStore.swift             UserDefaults JSON persistence: sessions + active game + stats
  ViewModels/
    GameViewModel.swift          board state, timer, hints, undo, settings, 18+ gate
  Views/
    RootView, AgeGateView, HomeView, GameView, BoardView,
    CompletionView, StatsView, SettingsView
  Resources/Assets.xcassets      AppIcon (1024, no alpha) + AccentColor
  Support/Info.plist, PrivacyInfo.xcprivacy
```

## Key behaviours

- **Generation** (`SudokuEngine`): fill a random solved grid, then carve out cells while a
  2-solution uniqueness check still returns exactly 1. Clue targets per difficulty:
  Easy 45 · Medium 36 · Hard 30 · Expert 25.
- **Hints**: `useHint()` fills the selected (or first unsolved) cell with the solution value
  and increments the hint tally, which lowers the final score.
- **Persistence**: every move saves an `ActiveGame` so the player can quit and **Continue**;
  finished games append a `GameSession`. Nothing leaves the device.
- **18+ gate**: `AgeGateView` shows once on first launch; the choice is stored in UserDefaults
  (`SudokuApp.ageConfirmed`). The App Store age rating is also set to 18+ (UI-only in ASC).

## Conventions

- iOS 16 deployment target — avoid iOS 17-only APIs (e.g. `ContentUnavailableView`).
- iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), portrait only.
- No third-party dependencies; no network; no permissions.

## App Store submission

See the `app-store-submission` skill (`.claude/skills/app-store-submission/`). Pre-flight is
done in-repo (icon without alpha, `ITSAppUsesNonExemptEncryption=false`, `arm64`,
`PrivacyInfo.xcprivacy`, `ExportOptions.plist`). Remember the **18+ age rating** is set in the
App Store Connect UI. Regenerate the icon with
`swift .claude/skills/app-store-submission/scripts/make_sudoku_icon.swift <out.png>`.
