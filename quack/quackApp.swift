import SwiftUI
import Sticker

@main
struct quackApp: App {
    @State private var appState = AppState()

    init() {
        Task { try? await ShaderLibrary.compileStickerShaders() }
        Task.detached(priority: .utility) { await GemmaSmokeTest.run() }
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
    }
}
