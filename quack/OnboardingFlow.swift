import SwiftUI

// MARK: - OnboardingFlow coordinator
struct OnboardingFlow: View {
    let onComplete: () -> Void
    @Environment(AppState.self) private var appState

    enum Step { case splash, name, age, intro }
    @State private var step: Step = .splash

    var body: some View {
        Group {
            switch step {
            case .splash:
                SplashView(onNext: { withAnimation { step = .name } })
            case .name:
                NameView(
                    initial: appState.name,
                    onBack: { withAnimation { step = .splash } },
                    onNext: { name in
                        appState.name = name
                        withAnimation { step = .age }
                    }
                )
            case .age:
                AgeView(
                    initial: appState.age,
                    onBack: { withAnimation { step = .name } },
                    onNext: { age in
                        appState.age = age
                        withAnimation { step = .intro }
                    }
                )
            case .intro:
                IntroView(
                    name: appState.name,
                    onBack: { withAnimation { step = .age } },
                    onNext: onComplete
                )
            }
        }
        .transition(.screenIn)
        .animation(.easeOut(duration: 0.32), value: step)
    }
}

// MARK: - SplashView
struct SplashView: View {
    let onNext: () -> Void
    @State private var visible = false

    var body: some View {
        ZStack {
            Color.quackOrange.ignoresSafeArea()
            Sparkles(count: 8, animate: true)

            VStack(spacing: 0) {
                Spacer()

                Mascot(state: .speaking, size: 170)

                Eyebrow(text: "Mission begins", color: .quackYellow)
                    .padding(.top, 16)

                Text("Hi, I'm Q")
                    .font(.display(38, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                Text("Your secret-agent buddy for learning\nMandarin. Ready to start today's mission?")
                    .font(.bodyText(14))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .padding(.horizontal, 32)

                Spacer()

                CTAButton(label: "Let's go", variant: .ink, action: onNext)
                    .padding(.horizontal, 24)
                    .opacity(visible ? 1 : 0)
                    .offset(y: visible ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: visible)

                (Text("Already have an agent? ")
                    .font(.bodyText(13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                + Text("Sign in")
                    .font(.bodyText(13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .underline())

                Spacer().frame(height: 32)
            }
        }
        .onAppear { visible = true }
    }
}

// MARK: - NameView
struct NameView: View {
    let initial: String
    let onBack: () -> Void
    let onNext: (String) -> Void

    @State private var name: String
    @FocusState private var focused: Bool

    init(initial: String, onBack: @escaping () -> Void, onNext: @escaping (String) -> Void) {
        self.initial = initial
        self.onBack = onBack
        self.onNext = onNext
        _name = State(initialValue: initial)
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Step 1 of 3", flank: false, size: 11)
                    Text("Tell us your name")
                        .font(.display(30, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("So Q knows what to call you")
                        .font(.bodyText(14))
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.quackOrange)
                        .grain()
                        .popShadow()

                    Sparkles(count: 4, opacity: 0.55)

                    VStack(spacing: 0) {
                        Text("First name")
                            .font(.bodyText(13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.top, 24)

                        TextField("e.g. Nia", text: $name)
                            .font(.bodyText(18, weight: .heavy))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .tint(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(Color.quackOrangeSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 22)
                            .padding(.top, 8)
                            .focused($focused)
                            .submitLabel(.continue)
                            .onSubmit {
                                let trimmed = name.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty { onNext(trimmed) }
                            }

                        Spacer()
                        Mascot(state: .idle, size: 170)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .frame(minHeight: 320)

                Spacer()

                CTAButton(
                    label: "Continue",
                    variant: .ink,
                    disabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                    action: {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        onNext(trimmed.isEmpty ? "Agent" : trimmed)
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear { focused = true }
    }
}

#Preview("Splash") {
    SplashView(onNext: {})
        .environment(AppState())
}

#Preview("Name") {
    NameView(initial: "Alex", onBack: {}, onNext: { _ in })
        .environment(AppState())
}
