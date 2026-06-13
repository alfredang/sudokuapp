import SwiftUI

@main
struct SudokuApp: App {

    @StateObject private var viewModel = GameViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .preferredColorScheme(nil)   // follow the system appearance
#if DEBUG
                .onAppear {
                    if let key = ProcessInfo.processInfo.environment["SUDOKU_SCREENSHOT"] {
                        viewModel.prepareScreenshot(key)
                    }
                }
#endif
        }
        .onChange(of: scenePhase) { phase in
            // Auto-pause when the app leaves the foreground so the timer stays honest.
            if phase != .active, viewModel.screen == .game, !viewModel.isPaused {
                viewModel.togglePause()
            }
        }
    }
}
