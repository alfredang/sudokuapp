import SwiftUI

/// Gameplay preferences plus the app's about/legal info. All toggles persist through
/// the view model (UserDefaults-backed).
struct SettingsView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Assistance") {
                    Toggle("Highlight conflicts", isOn: $viewModel.highlightConflicts)
                    Toggle("Highlight same number", isOn: $viewModel.highlightSameNumber)
                    Toggle("Auto-remove pencil marks", isOn: $viewModel.autoRemoveNotes)
                }

                Section {
                    Toggle("Limit mistakes (3 strikes)", isOn: $viewModel.limitMistakes)
                } header: {
                    Text("Challenge")
                } footer: {
                    Text("When on, a game ends after three incorrect entries.")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Age rating", value: "18+")
                    Text("Sudoku puzzles are generated on your device with a guaranteed unique solution. Scores and history are stored only on this iPhone and never leave it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }
}
