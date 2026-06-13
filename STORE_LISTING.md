# App Store listing — Sudoku

Everything needed to fill in the App Store Connect product page. Credentials/contact live in
the gitignored `.env`; this file holds the public-facing copy and asset locations.

## Identity

| Field | Value |
|---|---|
| App name | Sudoku |
| Bundle ID | `com.tertiaryinfotech.sudokuapp` |
| Team | Tertiary Infotech (`GU9WTSTX9M`) |
| Apple account | angchewhoe@gmail.com / Chew Hoe Ang |
| Platform | iOS 16+, iPhone only (portrait) |
| Primary category | Games → Puzzle (secondary: Board) |
| Price | Free |
| **Age rating** | **18+** — set in the ASC UI (Age Rating questionnaire); the app also shows a one-time in-app 18+ gate |

## Marketing copy

**Subtitle** (≤30): `Classic number puzzles`

**Keywords** (≤100, CSV): `sudoku,puzzle,number,logic,brain,board game,grid,classic,offline,hints`

**Promotional text** (≤170):
> Unlimited Sudoku puzzles with four difficulty levels, smart hints, mistake tracking, pencil notes, and local high scores — all offline.

**Description** (≤4000):
> Sudoku is a clean, offline number-puzzle game for grown-ups. Every puzzle is generated on your device with a guaranteed unique solution, so you never run out and never see the same grid twice. Choose from four difficulty levels — Easy, Medium, Hard, and Expert — and solve at your own pace.
>
> • Four difficulty levels, from gentle warm-ups to ruthless Expert grids
> • Smart hints whenever you ask — reveal the right number for any cell
> • Pencil notes (candidates) with optional auto-cleanup
> • Conflict and same-number highlighting you can toggle on or off
> • Optional 3-strike challenge mode for mistake-free runs
> • A timer, scoring, and full game history kept entirely on your iPhone
> • 100% offline and private — nothing ever leaves your device
>
> Track your best times and scores per difficulty, resume any game you leave, and train your brain one grid at a time.

## App Privacy

**Data Not Collected.** No tracking, no network, no permissions. Scores and history live in
`UserDefaults` on-device. (Set in the ASC UI: App Privacy → "No, we do not collect data" → Publish.)

## App Review notes

> Offline Sudoku puzzle game. No login required, no permissions requested. A one-time 18+ age
> gate appears on first launch — tap "I am 18 or older" to reach the game. All scores/history
> are stored locally on device.

## Assets

| Asset | Path | Size |
|---|---|---|
| App icon (1024, no alpha) | `SudokuApp/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` | 1024×1024 |
| Screenshot 1 — Home | `screenshots/appstore/1-home.png` | 1320×2868 (6.9") |
| Screenshot 2 — Game | `screenshots/appstore/2-game.png` | 1320×2868 (6.9") |
| Screenshot 3 — Completion | `screenshots/appstore/3-completion.png` | 1320×2868 (6.9") |
| Raw (unframed) captures | `screenshots/raw/*.png` | 1320×2868 |

Regenerate:
- Icon: `swift .claude/skills/app-store-submission/scripts/make_sudoku_icon.swift <out.png>` then flatten alpha.
- Screenshots: build for the 6.9" simulator and launch with `SIMCTL_CHILD_SUDOKU_SCREENSHOT=home|game|completion` (DEBUG-only hook), then frame with `scripts/frame_screenshot.swift <in> <out> "Caption"`.

## Submission

Driven by the `app-store-submission` skill. The 6.9" set (`APP_IPHONE_67`, 1290×2796 or
1320×2868) is the only required screenshot size. **Age rating (18+) and App Privacy are UI-only**
in App Store Connect — there is no API for them.
