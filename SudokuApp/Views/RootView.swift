import SwiftUI

/// Top-level router. Shows the 18+ age gate until confirmed, then switches between
/// the home, game, and completion screens.
struct RootView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        Group {
            if !viewModel.isAgeConfirmed {
                AgeGateView()
            } else {
                switch viewModel.screen {
                case .home:       HomeView()
                case .game:       GameView()
                case .completion: CompletionView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.screen)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isAgeConfirmed)
        .alert(item: $viewModel.activeAlert) { alert in
            Alert(title: Text(alert.title),
                  message: Text(alert.message),
                  dismissButton: .default(Text("OK")))
        }
    }
}
