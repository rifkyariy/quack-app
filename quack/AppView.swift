import SwiftUI

struct AppView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("quack.hasOnboarded") private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
                    .transition(.screenIn)
            } else {
                OnboardingFlow(onComplete: {
                    withAnimation(.easeOut(duration: 0.32)) {
                        hasOnboarded = true
                    }
                })
                .transition(.screenIn)
            }
        }
        .animation(.easeOut(duration: 0.32), value: hasOnboarded)
    }
}

#Preview {
    AppView()
        .environment(AppState())
}
