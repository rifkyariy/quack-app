import SwiftUI
import Combine

struct AppView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("quack.hasOnboarded") private var hasOnboarded = false
    @State private var showingSplash = true
    // ponytail: minute tick fires while app is active to catch limit mid-session
    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        @Bindable var state = appState
        ZStack {
            Group {
                if hasOnboarded {
                    MainTabView()
                        .transition(.screenIn)
                } else {
                    OnboardingFlow(onComplete: {
                        withAnimation(.easeOut(duration: 0.32)) { hasOnboarded = true }
                    })
                    .transition(.screenIn)
                }
            }
            .animation(.easeOut(duration: 0.32), value: hasOnboarded)

            if showingSplash {
                LaunchSplashView {
                    withAnimation(.easeOut(duration: 0.5)) { showingSplash = false }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.05)))
                .zIndex(1)
            }

            if state.screenTimeLimitReached {
                ScreenTimeLimitModal {
                    appState.screenTimeLimitReached = false
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                .zIndex(2)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: state.screenTimeLimitReached)
        .onReceive(ticker) { _ in appState.tickScreenTime() }
        .onAppear {
            #if DEBUG
            hasOnboarded = false
            #endif
            updateOrientationLock()
        }
        .onChange(of: hasOnboarded) { _, _ in updateOrientationLock() }
        .onChange(of: showingSplash) { _, _ in updateOrientationLock() }
    }

    // Splash + onboarding are portrait-only; the main app (post-onboarding) allows rotation.
    @MainActor private func updateOrientationLock() {
        OrientationLock.set(showingSplash || !hasOnboarded ? .portrait : .allButUpsideDown)
    }
}

// MARK: - Screen time limit modal
private struct ScreenTimeLimitModal: View {
    let onDismiss: () -> Void
    @State private var duckBounce = false

    var body: some View {
        ZStack {
            // Dim backdrop
            Color.ink.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { } // block taps through

            VStack(spacing: 0) {
                // Duck bouncing
                Image("duck-mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130)
                    .offset(y: duckBounce ? -8 : 0)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: duckBounce)
                    .padding(.top, -50)

                VStack(spacing: 12) {
                    // Title
                    Text("Time's up!")
                        .font(.display(24, weight: .black))
                        .foregroundStyle(Color.ink)

                    // Message
                    VStack(spacing: 6) {
                        Text("Ask your")
                            .font(.bodyText(15))
                            .foregroundStyle(Color.inkMuted)

                        HStack(spacing: 16) {
                            VStack(spacing: 2) {
                                Text("Amma")
                                    .font(.display(22, weight: .black))
                                    .foregroundStyle(Color.quackOrange)
                                Text("阿妈 · ā mā")
                                    .font(.bodyText(11))
                                    .foregroundStyle(Color.inkMuted)
                            }
                            Text("or")
                                .font(.bodyText(14))
                                .foregroundStyle(Color.inkMuted)
                            VStack(spacing: 2) {
                                Text("Appa")
                                    .font(.display(22, weight: .black))
                                    .foregroundStyle(Color.cobalt)
                                Text("阿爸 · ā bà")
                                    .font(.bodyText(11))
                                    .foregroundStyle(Color.inkMuted)
                            }
                        }

                        Text("to keep playing!")
                            .font(.bodyText(14))
                            .foregroundStyle(Color.inkMuted)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 16)

                    // Divider
                    Rectangle()
                        .fill(Color.inkFaint)
                        .frame(height: 1)
                        .padding(.top, 8)

                    Button(action: onDismiss) {
                        Text("OK, I'll ask!")
                            .font(.display(16, weight: .heavy))
                            .foregroundStyle(Color.quackOrange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(TapPress())
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .cardShadow()
            .padding(.horizontal, 36)
        }
        .onAppear { duckBounce = true }
    }
}

#Preview {
    AppView()
        .environment(AppState())
}

#Preview("Screen limit modal") {
    ZStack {
        Color.cream.ignoresSafeArea()
        ScreenTimeLimitModal {}
    }
}
