import Foundation

/// Lightweight on-device persistence of completed games and the in-progress game,
/// stored as JSON in `UserDefaults`. Kept deliberately simple — no Core Data — and
/// nothing ever leaves the device. Mirrors the storage style of the rest of the app.
final class ScoreStore {

    private let defaults: UserDefaults
    private let sessionsKey = "SudokuApp.sessions"
    private let activeKey = "SudokuApp.activeGame"
    private let maxStored = 200

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Completed sessions

    /// All saved games, most recent first.
    func allSessions() -> [GameSession] {
        guard let data = defaults.data(forKey: sessionsKey) else { return [] }
        let sessions = (try? JSONDecoder().decode([GameSession].self, from: data)) ?? []
        return sessions.sorted { $0.date > $1.date }
    }

    /// Appends a finished game and trims history to `maxStored`.
    func save(_ session: GameSession) {
        var sessions = allSessions()
        sessions.removeAll { $0.id == session.id }
        sessions.insert(session, at: 0)
        persistSessions(Array(sessions.prefix(maxStored)))
    }

    func delete(_ id: UUID) {
        persistSessions(allSessions().filter { $0.id != id })
    }

    func clearSessions() {
        defaults.removeObject(forKey: sessionsKey)
    }

    private func persistSessions(_ sessions: [GameSession]) {
        if let data = try? JSONEncoder().encode(sessions) {
            defaults.set(data, forKey: sessionsKey)
        }
    }

    // MARK: - Active (resumable) game

    func loadActiveGame() -> ActiveGame? {
        guard let data = defaults.data(forKey: activeKey) else { return nil }
        return try? JSONDecoder().decode(ActiveGame.self, from: data)
    }

    func saveActiveGame(_ game: ActiveGame) {
        if let data = try? JSONEncoder().encode(game) {
            defaults.set(data, forKey: activeKey)
        }
    }

    func clearActiveGame() {
        defaults.removeObject(forKey: activeKey)
    }

    // MARK: - Derived stats

    struct Stats {
        var gamesPlayed: Int
        var totalScore: Int
        var bestScore: Int
        var bestTimeByDifficulty: [Difficulty: Int]
        var countByDifficulty: [Difficulty: Int]
    }

    func stats() -> Stats {
        let sessions = allSessions()
        var bestTime: [Difficulty: Int] = [:]
        var counts: [Difficulty: Int] = [:]
        for s in sessions {
            counts[s.difficulty, default: 0] += 1
            if let existing = bestTime[s.difficulty] {
                bestTime[s.difficulty] = min(existing, s.durationSeconds)
            } else {
                bestTime[s.difficulty] = s.durationSeconds
            }
        }
        return Stats(
            gamesPlayed: sessions.count,
            totalScore: sessions.reduce(0) { $0 + $1.score },
            bestScore: sessions.map(\.score).max() ?? 0,
            bestTimeByDifficulty: bestTime,
            countByDifficulty: counts
        )
    }
}
