import SwiftUI

/// Renders the 9×9 grid: cell values, pencil notes, selection + peer highlighting,
/// conflict colouring, and the thicker 3×3 box borders.
struct BoardView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 9
            let conflicts = viewModel.highlightConflicts ? viewModel.conflictingIndices : []
            let selected = viewModel.selectedIndex
            let selectedValue = selected.map { viewModel.values[$0] } ?? 0

            ZStack {
                // Cells
                ForEach(0..<81, id: \.self) { idx in
                    let r = idx / 9, c = idx % 9
                    CellView(
                        value: viewModel.values[idx],
                        notes: viewModel.notes[idx],
                        isGiven: viewModel.isGiven[idx],
                        isSelected: selected == idx,
                        isPeer: isPeer(idx, of: selected),
                        isSameValue: viewModel.highlightSameNumber
                            && selectedValue != 0
                            && viewModel.values[idx] == selectedValue,
                        isConflict: conflicts.contains(idx),
                        size: cell
                    )
                    .position(x: (CGFloat(c) + 0.5) * cell, y: (CGFloat(r) + 0.5) * cell)
                    .onTapGesture { viewModel.selectCell(idx) }
                }

                gridLines(cell: cell, side: side)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func isPeer(_ idx: Int, of selected: Int?) -> Bool {
        guard let s = selected, s != idx else { return false }
        let r1 = idx / 9, c1 = idx % 9, r2 = s / 9, c2 = s % 9
        let sameBox = (r1 / 3 == r2 / 3) && (c1 / 3 == c2 / 3)
        return r1 == r2 || c1 == c2 || sameBox
    }

    private func gridLines(cell: CGFloat, side: CGFloat) -> some View {
        Path { path in
            for i in 0...9 {
                let pos = CGFloat(i) * cell
                path.move(to: CGPoint(x: pos, y: 0)); path.addLine(to: CGPoint(x: pos, y: side))
                path.move(to: CGPoint(x: 0, y: pos)); path.addLine(to: CGPoint(x: side, y: pos))
            }
        }
        .stroke(Color(.separator), lineWidth: 1)
        .overlay(
            Path { path in
                for i in stride(from: 0, through: 9, by: 3) {
                    let pos = CGFloat(i) * cell
                    path.move(to: CGPoint(x: pos, y: 0)); path.addLine(to: CGPoint(x: pos, y: side))
                    path.move(to: CGPoint(x: 0, y: pos)); path.addLine(to: CGPoint(x: side, y: pos))
                }
            }
            .stroke(Color.primary, lineWidth: 2)
        )
        .allowsHitTesting(false)
    }
}

/// A single Sudoku cell.
private struct CellView: View {
    let value: Int
    let notes: Set<Int>
    let isGiven: Bool
    let isSelected: Bool
    let isPeer: Bool
    let isSameValue: Bool
    let isConflict: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            background
            if value != 0 {
                Text("\(value)")
                    .font(.system(size: size * 0.55, weight: isGiven ? .bold : .regular, design: .rounded))
                    .foregroundStyle(textColor)
            } else if !notes.isEmpty {
                notesGrid
            }
        }
        .frame(width: size, height: size)
    }

    private var background: some View {
        Group {
            if isSelected {
                Color.accentColor.opacity(0.28)
            } else if isConflict {
                Color.red.opacity(0.18)
            } else if isSameValue {
                Color.accentColor.opacity(0.14)
            } else if isPeer {
                Color.accentColor.opacity(0.07)
            } else {
                Color(.systemBackground)
            }
        }
    }

    private var textColor: Color {
        if isConflict { return .red }
        if isGiven { return .primary }
        return .accentColor
    }

    private var notesGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { col in
                        let n = row * 3 + col + 1
                        Text(notes.contains(n) ? "\(n)" : " ")
                            .font(.system(size: size * 0.2, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: size / 3, height: size / 3)
                    }
                }
            }
        }
    }
}
