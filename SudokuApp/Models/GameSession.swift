import Foundation

/// A completed game, persisted to local storage for the score history and stats.
struct GameSession: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var difficulty: Difficulty
    var date: Date
    var durationSeconds: Int
    var hintsUsed: Int
    var mistakes: Int
    var score: Int

    /// `mm:ss` (or `h:mm:ss`) formatting of the solve time.
    var formattedDuration: String {
        let h = durationSeconds / 3600
        let m = (durationSeconds % 3600) / 60
        let s = durationSeconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}

/// A snapshot of an in-progress game so the player can quit and resume later.
/// Stored separately from finished sessions and cleared once the puzzle is solved.
struct ActiveGame: Codable, Equatable {
    var difficulty: Difficulty
    var puzzle: [Int]          // starting givens (0 = blank)
    var solution: [Int]        // unique solution
    var values: [Int]          // current entries (0 = blank)
    var notes: [[Int]]         // pencil marks per cell
    var elapsedSeconds: Int
    var mistakes: Int
    var hintsUsed: Int
}
