import SwiftUI
import Combine

/// The single source of truth for the running game and all navigation. Holds the
/// board, the timer, hint/mistake bookkeeping, settings, and persists both the
/// in-progress game and finished sessions through `ScoreStore`.
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: Navigation
    @Published var screen: AppScreen = .home
    @Published var activeAlert: GameAlert?

    // MARK: 18+ gate
    /// The app is rated 18+. The user must confirm their age once; the choice is
    /// remembered on-device.
    @Published var isAgeConfirmed: Bool {
        didSet { defaults.set(isAgeConfirmed, forKey: Keys.ageConfirmed) }
    }

    // MARK: Board state
    @Published private(set) var difficulty: Difficulty = .easy
    @Published private(set) var puzzle: [Int] = Array(repeating: 0, count: 81)   // givens
    @Published private(set) var solution: [Int] = Array(repeating: 0, count: 81)
    @Published private(set) var values: [Int] = Array(repeating: 0, count: 81)   // current entries
    @Published private(set) var notes: [Set<Int>] = Array(repeating: [], count: 81)

    @Published var selectedIndex: Int?
    @Published var isNotesMode = false
    @Published private(set) var mistakes = 0
    @Published private(set) var hintsUsed = 0
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var isPaused = false

    // MARK: Settings (persisted)
    @Published var highlightConflicts: Bool { didSet { defaults.set(highlightConflicts, forKey: Keys.highlightConflicts) } }
    @Published var highlightSameNumber: Bool { didSet { defaults.set(highlightSameNumber, forKey: Keys.highlightSameNumber) } }
    @Published var autoRemoveNotes: Bool { didSet { defaults.set(autoRemoveNotes, forKey: Keys.autoRemoveNotes) } }
    @Published var limitMistakes: Bool { didSet { defaults.set(limitMistakes, forKey: Keys.limitMistakes) } }

    let mistakeLimit = 3

    // MARK: Stored result of the last finished game (for CompletionView)
    @Published private(set) var lastSession: GameSession?

    private let store = ScoreStore()
    private let defaults = UserDefaults.standard
    private var timerCancellable: AnyCancellable?
    private var undoStack: [(index: Int, value: Int, notes: Set<Int>)] = []

    private enum Keys {
        static let ageConfirmed = "SudokuApp.ageConfirmed"
        static let highlightConflicts = "SudokuApp.highlightConflicts"
        static let highlightSameNumber = "SudokuApp.highlightSameNumber"
        static let autoRemoveNotes = "SudokuApp.autoRemoveNotes"
        static let limitMistakes = "SudokuApp.limitMistakes"
    }

    init() {
        isAgeConfirmed = defaults.bool(forKey: Keys.ageConfirmed)
        // Settings default to ON (except the optional mistake limit).
        highlightConflicts = defaults.object(forKey: Keys.highlightConflicts) as? Bool ?? true
        highlightSameNumber = defaults.object(forKey: Keys.highlightSameNumber) as? Bool ?? true
        autoRemoveNotes = defaults.object(forKey: Keys.autoRemoveNotes) as? Bool ?? true
        limitMistakes = defaults.object(forKey: Keys.limitMistakes) as? Bool ?? false
    }

    // MARK: - Derived state

    var hasResumableGame: Bool { store.loadActiveGame() != nil }

    var isGiven: [Bool] { puzzle.map { $0 != 0 } }

    var isSolved: Bool { values == solution }

    /// Remaining count for each digit 1...9 (how many still to place on the board).
    func remaining(for digit: Int) -> Int {
        9 - values.filter { $0 == digit }.count
    }

    /// Indices that currently violate a Sudoku rule (duplicate in row/col/box).
    var conflictingIndices: Set<Int> {
        var conflicts = Set<Int>()
        for i in 0..<81 where values[i] != 0 {
            for p in SudokuEngine.peers(of: i) where values[p] == values[i] {
                conflicts.insert(i); conflicts.insert(p)
            }
        }
        return conflicts
    }

    // MARK: - Game lifecycle

    func startNewGame(_ difficulty: Difficulty) {
        let generated = SudokuEngine.generatePuzzle(targetClues: difficulty.targetClues)
        self.difficulty = difficulty
        puzzle = generated.puzzle
        solution = generated.solution
        values = generated.puzzle
        notes = Array(repeating: [], count: 81)
        selectedIndex = nil
        isNotesMode = false
        mistakes = 0
        hintsUsed = 0
        elapsedSeconds = 0
        isPaused = false
        undoStack.removeAll()
        screen = .game
        persistActiveGame()
        startTimer()
    }

    func resumeSavedGame() {
        guard let game = store.loadActiveGame() else { return }
        difficulty = game.difficulty
        puzzle = game.puzzle
        solution = game.solution
        values = game.values
        notes = game.notes.map { Set($0) }
        selectedIndex = nil
        isNotesMode = false
        mistakes = game.mistakes
        hintsUsed = game.hintsUsed
        elapsedSeconds = game.elapsedSeconds
        isPaused = false
        undoStack.removeAll()
        screen = .game
        startTimer()
    }

    func quitToHome() {
        stopTimer()
        persistActiveGame()
        selectedIndex = nil
        screen = .home
    }

    // MARK: - Player input

    func selectCell(_ index: Int) {
        selectedIndex = (selectedIndex == index) ? nil : index
    }

    func enter(_ digit: Int) {
        guard let idx = selectedIndex, !isGiven[idx], !isPaused else { return }
        recordUndo(idx)

        if isNotesMode {
            if notes[idx].contains(digit) { notes[idx].remove(digit) } else { notes[idx].insert(digit) }
            values[idx] = 0
        } else {
            // Tapping the same digit again clears the cell.
            if values[idx] == digit {
                values[idx] = 0
            } else {
                values[idx] = digit
                notes[idx].removeAll()
                registerMistakeIfNeeded(at: idx, digit: digit)
                if autoRemoveNotes { pruneNotes(around: idx, digit: digit) }
            }
        }
        persistActiveGame()
        checkForWin()
    }

    func erase() {
        guard let idx = selectedIndex, !isGiven[idx], !isPaused else { return }
        recordUndo(idx)
        values[idx] = 0
        notes[idx].removeAll()
        persistActiveGame()
    }

    func toggleNotesMode() { isNotesMode.toggle() }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        values[last.index] = last.value
        notes[last.index] = last.notes
        persistActiveGame()
    }

    /// Reveals the correct value for the selected empty cell (or, if none is selected,
    /// the first empty cell). Counts toward the hint tally and lowers the final score.
    func useHint() {
        guard !isPaused else { return }
        let target = selectedIndex.flatMap { isGiven[$0] || values[$0] == solution[$0] ? nil : $0 }
            ?? firstUnsolvedIndex()
        guard let idx = target else { return }
        recordUndo(idx)
        values[idx] = solution[idx]
        notes[idx].removeAll()
        if autoRemoveNotes { pruneNotes(around: idx, digit: solution[idx]) }
        hintsUsed += 1
        selectedIndex = idx
        persistActiveGame()
        checkForWin()
    }

    func togglePause() {
        guard screen == .game, !isSolved else { return }
        isPaused.toggle()
        isPaused ? stopTimer() : startTimer()
    }

    // MARK: - Win / loss handling

    private func checkForWin() {
        guard isSolved else { return }
        stopTimer()
        let score = ScoreCalculator.score(difficulty: difficulty,
                                          seconds: elapsedSeconds,
                                          hintsUsed: hintsUsed,
                                          mistakes: mistakes)
        let session = GameSession(difficulty: difficulty,
                                  date: Date(),
                                  durationSeconds: elapsedSeconds,
                                  hintsUsed: hintsUsed,
                                  mistakes: mistakes,
                                  score: score)
        store.save(session)
        store.clearActiveGame()
        lastSession = session
        screen = .completion
    }

    private func registerMistakeIfNeeded(at idx: Int, digit: Int) {
        guard digit != solution[idx] else { return }
        mistakes += 1
        if limitMistakes && mistakes >= mistakeLimit {
            stopTimer()
            activeAlert = GameAlert(
                title: "Out of moves",
                message: "You reached \(mistakeLimit) mistakes. Start a new game to try again."
            )
        }
    }

    private func firstUnsolvedIndex() -> Int? {
        (0..<81).first { !isGiven[$0] && values[$0] != solution[$0] }
    }

    // MARK: - Helpers

    private func recordUndo(_ idx: Int) {
        undoStack.append((idx, values[idx], notes[idx]))
        if undoStack.count > 100 { undoStack.removeFirst() }
    }

    /// Removes `digit` from the pencil marks of the cell's peers.
    private func pruneNotes(around idx: Int, digit: Int) {
        for p in SudokuEngine.peers(of: idx) { notes[p].remove(digit) }
    }

    private func persistActiveGame() {
        guard screen == .game, !isSolved else { return }
        let game = ActiveGame(
            difficulty: difficulty,
            puzzle: puzzle,
            solution: solution,
            values: values,
            notes: notes.map { Array($0).sorted() },
            elapsedSeconds: elapsedSeconds,
            mistakes: mistakes,
            hintsUsed: hintsUsed
        )
        store.saveActiveGame(game)
    }

    // MARK: - Timer

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.screen == .game, !self.isPaused, !self.isSolved else { return }
                self.elapsedSeconds += 1
                if self.elapsedSeconds % 10 == 0 { self.persistActiveGame() }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    var formattedElapsed: String {
        let m = elapsedSeconds / 60, s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

#if DEBUG
    /// Seeds a representative state for App Store screenshots. DEBUG-only; triggered
    /// by the `SUDOKU_SCREENSHOT` launch environment variable. Never ships.
    func prepareScreenshot(_ key: String) {
        isAgeConfirmed = true
        switch key {
        case "game", "completion":
            startNewGame(.medium)
            stopTimerForScreenshot()
            // Fill a deterministic ~65% of the non-given cells with correct values for a
            // lived-in board, leaving the rest blank.
            for i in 0..<81 where !isGiven[i] && i % 3 != 0 {
                values[i] = solution[i]
            }
            // A couple of pencil-marked cells.
            if let blank = (0..<81).first(where: { values[$0] == 0 && !isGiven[$0] }) {
                notes[blank] = [2, 4, 9]
                selectedIndex = blank
            }
            elapsedSeconds = 222            // 03:42
            hintsUsed = 1
            mistakes = 1
            if key == "completion" {
                let s = GameSession(difficulty: .medium, date: Date(),
                                    durationSeconds: 222, hintsUsed: 1, mistakes: 1,
                                    score: ScoreCalculator.score(difficulty: .medium, seconds: 222, hintsUsed: 1, mistakes: 1))
                lastSession = s
                screen = .completion
            }
        default:
            screen = .home
        }
    }

    private func stopTimerForScreenshot() { stopTimer() }
#endif
}
