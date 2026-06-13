import SwiftUI

/// The playing screen: status bar, the board, the number pad, and the action row
/// (undo, erase, notes, hint).
struct GameView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    @State private var showQuitConfirm = false

    var body: some View {
        VStack(spacing: 16) {
            statusBar
            boardArea
            Spacer(minLength: 0)
            actionRow
            NumberPad { viewModel.enter($0) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Leave this game?", isPresented: $showQuitConfirm, titleVisibility: .visible) {
            Button("Save & Quit") { viewModel.quitToHome() }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("Your progress is saved so you can continue later.")
        }
    }

    // MARK: Status bar

    private var statusBar: some View {
        HStack {
            Button { showQuitConfirm = true } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            .accessibilityLabel("Back")

            Spacer()

            Label(viewModel.difficulty.title, systemImage: viewModel.difficulty.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(viewModel.difficulty.tint)

            Spacer()

            HStack(spacing: 14) {
                if viewModel.mistakes > 0 || viewModel.limitMistakes {
                    Label(mistakeText, systemImage: "xmark.circle")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.red)
                        .labelStyle(.titleAndIcon)
                }
                Button { viewModel.togglePause() } label: {
                    Label(viewModel.formattedElapsed,
                          systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var mistakeText: String {
        viewModel.limitMistakes ? "\(viewModel.mistakes)/\(viewModel.mistakeLimit)" : "\(viewModel.mistakes)"
    }

    // MARK: Board

    private var boardArea: some View {
        ZStack {
            BoardView()
                .padding(4)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
                .blur(radius: viewModel.isPaused ? 14 : 0)

            if viewModel.isPaused {
                VStack(spacing: 12) {
                    Image(systemName: "pause.circle.fill").font(.system(size: 50))
                    Text("Paused").font(.title2.bold())
                    Button("Resume") { viewModel.togglePause() }
                        .buttonStyle(.borderedProminent)
                }
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: Actions

    private var actionRow: some View {
        HStack(spacing: 0) {
            ActionButton(title: "Undo", symbol: "arrow.uturn.backward") { viewModel.undo() }
            ActionButton(title: "Erase", symbol: "eraser") { viewModel.erase() }
            ActionButton(title: "Notes",
                         symbol: viewModel.isNotesMode ? "pencil.circle.fill" : "pencil.circle",
                         highlighted: viewModel.isNotesMode) { viewModel.toggleNotesMode() }
            ActionButton(title: "Hint", symbol: "lightbulb",
                         badge: viewModel.hintsUsed > 0 ? "\(viewModel.hintsUsed)" : nil) {
                viewModel.useHint()
            }
        }
    }
}

/// One labelled icon button in the action row.
private struct ActionButton: View {
    let title: String
    let symbol: String
    var highlighted: Bool = false
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: symbol)
                        .font(.system(size: 24))
                        .frame(width: 30, height: 30)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Circle().fill(.red))
                            .offset(x: 10, y: -8)
                    }
                }
                Text(title).font(.caption)
            }
            .foregroundStyle(highlighted ? Color.accentColor : Color.primary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

/// The 1–9 number pad. Each key shows how many of that digit remain to be placed
/// and disables itself once all nine are on the board.
private struct NumberPad: View {
    @EnvironmentObject private var viewModel: GameViewModel
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...9, id: \.self) { digit in
                let remaining = viewModel.remaining(for: digit)
                Button { onTap(digit) } label: {
                    VStack(spacing: 2) {
                        Text("\(digit)")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                        Text(remaining > 0 ? "\(remaining)" : " ")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(remaining == 0)
                .opacity(remaining == 0 ? 0.35 : 1)
            }
        }
    }
}
