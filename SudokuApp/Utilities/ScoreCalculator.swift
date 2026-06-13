import Foundation

/// Converts a finished game into a score. Faster solves with no hints and no
/// mistakes score highest; the result is floored so every win is worth something.
enum ScoreCalculator {

    static let hintPenalty = 150
    static let mistakePenalty = 100
    static let minimumScore = 50

    static func score(difficulty: Difficulty,
                      seconds: Int,
                      hintsUsed: Int,
                      mistakes: Int) -> Int {
        // Beating par time earns a one-point-per-second bonus; going over par costs
        // nothing beyond losing the bonus.
        let speedBonus = max(0, difficulty.parSeconds - seconds)
        let raw = difficulty.baseScore
            + speedBonus
            - hintsUsed * hintPenalty
            - mistakes * mistakePenalty
        return max(minimumScore, raw)
    }
}
