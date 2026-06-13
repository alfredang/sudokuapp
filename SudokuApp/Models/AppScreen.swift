import Foundation

/// Drives top-level navigation. Like the rest of the app this stays lightweight, so
/// `RootView` switches on this enum instead of using a NavigationStack.
enum AppScreen {
    case home
    case game
    case completion
}

/// A simple alert payload routed through the view model.
struct GameAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
