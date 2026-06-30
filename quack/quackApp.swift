import SwiftUI
import Sticker

@main
struct quackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Task { try? await ShaderLibrary.compileStickerShaders() }
        QuackGemma.shared.preload()
        Task.detached(priority: .utility) { await GemmaSmokeTest.run() }
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:   appState.appDidBecomeActive()
            default:        appState.appDidBackground()
            }
        }
    }
}
