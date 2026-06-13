import Foundation

/// Pure Sudoku logic: full-grid generation, constraint solving, and uniqueness
/// checking. There is no UI or persistence here so the engine can be unit-tested
/// in isolation. Grids are flat `[Int]` of length 81 where `0` marks an empty cell.
enum SudokuEngine {

    static let size = 9
    static let box = 3
    static let cellCount = 81

    // MARK: - Coordinates

    @inline(__always) static func row(_ idx: Int) -> Int { idx / size }
    @inline(__always) static func col(_ idx: Int) -> Int { idx % size }
    @inline(__always) static func boxIndex(_ idx: Int) -> Int { (row(idx) / box) * box + (col(idx) / box) }

    /// Whether `value` can be placed at `idx` without breaking row/column/box rules.
    static func isSafe(_ grid: [Int], _ idx: Int, _ value: Int) -> Bool {
        let r = idx / size, c = idx % size
        for i in 0..<size {
            if grid[r * size + i] == value { return false }   // row
            if grid[i * size + c] == value { return false }   // column
        }
        let br = (r / box) * box, bc = (c / box) * box
        for dr in 0..<box {
            for dc in 0..<box where grid[(br + dr) * size + (bc + dc)] == value {
                return false
            }
        }
        return true
    }

    /// Indices that share a row, column, or box with `idx` (its "peers").
    static func peers(of idx: Int) -> [Int] {
        let r = idx / size, c = idx % size
        var set = Set<Int>()
        for i in 0..<size {
            set.insert(r * size + i)
            set.insert(i * size + c)
        }
        let br = (r / box) * box, bc = (c / box) * box
        for dr in 0..<box {
            for dc in 0..<box { set.insert((br + dr) * size + (bc + dc)) }
        }
        set.remove(idx)
        return Array(set)
    }

    // MARK: - Solving

    /// Finds the empty cell with the fewest legal candidates (minimum-remaining-values
    /// heuristic). Returns `nil` when the grid is full. An empty candidate list means a
    /// dead end and lets the caller backtrack immediately.
    private static func bestEmpty(_ grid: [Int]) -> (idx: Int, candidates: [Int])? {
        var best: (Int, [Int])?
        for i in 0..<cellCount where grid[i] == 0 {
            var candidates: [Int] = []
            for n in 1...size where isSafe(grid, i, n) { candidates.append(n) }
            if candidates.count == 1 { return (i, candidates) }
            if candidates.isEmpty { return (i, []) }
            if best == nil || candidates.count < best!.1.count { best = (i, candidates) }
        }
        return best
    }

    /// Returns a solved copy of `grid`, or `nil` if it has no solution.
    static func solve(_ grid: [Int]) -> [Int]? {
        var g = grid
        return solveInPlace(&g) ? g : nil
    }

    private static func solveInPlace(_ g: inout [Int]) -> Bool {
        guard let (idx, candidates) = bestEmpty(g) else { return true }
        for n in candidates {
            g[idx] = n
            if solveInPlace(&g) { return true }
            g[idx] = 0
        }
        return false
    }

    /// Counts solutions up to `limit`. Uniqueness only needs `limit == 2`.
    static func solutionCount(_ grid: [Int], limit: Int = 2) -> Int {
        var g = grid
        var found = 0
        countSolutions(&g, &found, limit)
        return found
    }

    private static func countSolutions(_ g: inout [Int], _ found: inout Int, _ limit: Int) {
        if found >= limit { return }
        guard let (idx, candidates) = bestEmpty(g) else { found += 1; return }
        for n in candidates {
            g[idx] = n
            countSolutions(&g, &found, limit)
            g[idx] = 0
            if found >= limit { return }
        }
    }

    // MARK: - Generation

    /// A random, fully-solved, valid grid.
    static func generateSolved() -> [Int] {
        var g = [Int](repeating: 0, count: cellCount)
        _ = fill(&g)
        return g
    }

    private static func fill(_ g: inout [Int]) -> Bool {
        guard let (idx, candidates) = bestEmpty(g) else { return true }
        if candidates.isEmpty { return false }
        for n in candidates.shuffled() {
            g[idx] = n
            if fill(&g) { return true }
            g[idx] = 0
        }
        return false
    }

    /// Builds a puzzle whose solution is unique by carving cells out of a solved grid.
    /// Removal stops once `targetClues` givens remain (or no further cell can be removed
    /// while keeping uniqueness). Returns the puzzle, its solution, and the actual clue count.
    static func generatePuzzle(targetClues: Int) -> (puzzle: [Int], solution: [Int], clues: Int) {
        let solution = generateSolved()
        var puzzle = solution
        var givens = cellCount
        for idx in Array(0..<cellCount).shuffled() {
            if givens <= targetClues { break }
            let backup = puzzle[idx]
            puzzle[idx] = 0
            if solutionCount(puzzle, limit: 2) == 1 {
                givens -= 1
            } else {
                puzzle[idx] = backup   // removal broke uniqueness — keep the clue
            }
        }
        return (puzzle, solution, givens)
    }
}
