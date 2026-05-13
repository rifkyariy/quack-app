import SwiftUI

struct AppView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("quack.hasOnboarded") private var hasOnboarded = false
    @State private var showingSplash = true

    var body: some View {
        ZStack {
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

            if showingSplash {
                LaunchSplashView {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showingSplash = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.05)))
                .zIndex(1)
            }
        }
        .onAppear {
            #if DEBUG
            hasOnboarded = false
            #endif
        }
    }
}

#Preview {
    AppView()
        .environment(AppState())
}
