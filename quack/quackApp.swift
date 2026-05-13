import SwiftUI
import Sticker

@main
struct quackApp: App {
    @State private var appState = AppState()

    init() {
        Task { await ShaderLibrary.compileStickerShaders() }
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
    }
}
