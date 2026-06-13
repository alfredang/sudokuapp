import SwiftUI

/// Shown after a puzzle is solved: the score, the breakdown, and the next actions.
struct CompletionView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        let session = viewModel.lastSession
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)
                Text("Solved!")
                    .font(.largeTitle.bold())
                if let session {
                    Text("\(session.difficulty.title) puzzle")
                        .font(.headline)
                        .foregroundStyle(session.difficulty.tint)
                }
            }

            if let session {
                VStack(spacing: 0) {
                    ScoreBig(score: session.score)
                    Divider().padding(.vertical, 4)
                    StatRow(label: "Time", value: session.formattedDuration, symbol: "clock")
                    StatRow(label: "Hints used", value: "\(session.hintsUsed)", symbol: "lightbulb")
                    StatRow(label: "Mistakes", value: "\(session.mistakes)", symbol: "xmark.circle")
                }
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                if let session {
                    Button {
                        viewModel.startNewGame(session.difficulty)
                    } label: {
                        Text("Play again (\(session.difficulty.title))")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button {
                    viewModel.screen = .home
                } label: {
                    Text("Home")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct ScoreBig: View {
    let score: Int
    var body: some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.tint)
            Text("POINTS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let symbol: String
    var body: some View {
        HStack {
            Label(label, systemImage: symbol)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.body.monospacedDigit().weight(.semibold))
        }
        .padding(.vertical, 8)
    }
}
