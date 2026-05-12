import SwiftUI

@main
struct quackApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
    }
}
