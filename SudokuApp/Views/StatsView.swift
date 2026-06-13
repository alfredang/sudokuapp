import SwiftUI

/// Score history and lifetime stats, read from the on-device `ScoreStore`.
struct StatsView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var sessions: [GameSession] = []
    @State private var stats: ScoreStore.Stats?
    @State private var showClearConfirm = false

    private let store = ScoreStore()

    var body: some View {
        NavigationStack {
            List {
                if let stats, stats.gamesPlayed > 0 {
                    Section("Overview") {
                        summaryRow("Games solved", "\(stats.gamesPlayed)", "checkmark.circle")
                        summaryRow("Best score", "\(stats.bestScore)", "star.fill")
                        summaryRow("Total score", "\(stats.totalScore)", "sum")
                    }

                    Section("Best time") {
                        ForEach(Difficulty.allCases) { level in
                            if let best = stats.bestTimeByDifficulty[level] {
                                HStack {
                                    Label(level.title, systemImage: level.symbol)
                                        .foregroundStyle(level.tint)
                                    Spacer()
                                    Text(format(best)).font(.body.monospacedDigit())
                                    Text("· \(stats.countByDifficulty[level] ?? 0)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section("History") {
                        ForEach(sessions) { session in
                            HistoryRow(session: session)
                        }
                        .onDelete(perform: deleteSessions)
                    }
                } else {
                    Section {
                        VStack(spacing: 10) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("No games yet").font(.headline)
                            Text("Solve a puzzle and your scores will appear here.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                if !sessions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) { showClearConfirm = true } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .confirmationDialog("Clear all history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    store.clearSessions(); reload()
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear(perform: reload)
        }
    }

    private func summaryRow(_ label: String, _ value: String, _ symbol: String) -> some View {
        HStack {
            Label(label, systemImage: symbol)
            Spacer()
            Text(value).font(.body.monospacedDigit().weight(.semibold))
        }
    }

    private func reload() {
        sessions = store.allSessions()
        stats = store.stats()
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets { store.delete(sessions[index].id) }
        reload()
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct HistoryRow: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.difficulty.symbol)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(session.difficulty.tint, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.difficulty.title).font(.headline)
                Text(session.date, format: .dateTime.day().month().hour().minute())
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.score)").font(.headline.monospacedDigit())
                Text(session.formattedDuration).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
