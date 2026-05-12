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

// MARK: - AgeView
struct AgeView: View {
    let initial: Int
    let onBack: () -> Void
    let onNext: (Int) -> Void

    private let ages = [4, 5, 6, 7, 8, 9, 10, 11, 12]
    private let itemWidth: CGFloat = 110

    @State private var selectedIndex: Int
    @GestureState private var gesture: (offset: CGFloat, dragging: Bool) = (0, false)

    init(initial: Int, onBack: @escaping () -> Void, onNext: @escaping (Int) -> Void) {
        self.initial = initial
        self.onBack = onBack
        self.onNext = onNext
        _selectedIndex = State(initialValue: max(0, [4,5,6,7,8,9,10,11,12].firstIndex(of: initial) ?? 4))
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
                    Eyebrow(text: "Step 2 of 3", flank: false, size: 11)
                    Text("How old are you?")
                        .font(.display(28, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("Drag to spin · Q sets the level")
                        .font(.bodyText(13))
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 14)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.quackOrange)
                        .grain()
                        .popShadow()

                    Sparkles(count: 4, opacity: 0.5)

                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.45), lineWidth: 3)
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 110, height: 110)

                            GeometryReader { geo in
                                let offset = -CGFloat(selectedIndex) * itemWidth + gesture.offset
                                HStack(spacing: 0) {
                                    ForEach(ages.indices, id: \.self) { i in
                                        let dist = abs(CGFloat(i - selectedIndex) - gesture.offset / itemWidth)
                                        let scale = max(0.5, 1 - dist * 0.18)
                                        let opacity = max(0.35, 1 - dist * 0.25)
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(i == selectedIndex ? 1.0 : 0.92))
                                                .frame(width: 100, height: 100)
                                                .popShadow()
                                            Text("\(ages[i])")
                                                .font(.display(42, weight: .heavy))
                                                .foregroundStyle(Color.ink)
                                        }
                                        .frame(width: itemWidth)
                                        .scaleEffect(scale)
                                        .opacity(opacity)
                                    }
                                }
                                .offset(x: geo.size.width / 2 - itemWidth / 2 + offset)
                                .animation(gesture.dragging ? nil : .spring(response: 0.32, dampingFraction: 0.7), value: offset)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .updating($gesture) { val, state, _ in
                                            state = (val.translation.width, true)
                                        }
                                        .onEnded { val in
                                            let steps = Int((-val.translation.width / itemWidth).rounded())
                                            selectedIndex = max(0, min(ages.count - 1, selectedIndex + steps))
                                        }
                                )
                            }
                            .frame(height: 180)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [Color.quackOrange, .clear, .clear, Color.quackOrange],
                                    startPoint: .leading, endPoint: .trailing
                                )
                                .allowsHitTesting(false)
                            )
                        }
                        .frame(height: 180)
                        .padding(.top, 14)

                        VStack(spacing: 2) {
                            Text("I AM")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .tracking(12 * 0.14)
                                .foregroundStyle(.white.opacity(0.85))
                            Text("\(ages[selectedIndex]) years old")
                                .font(.display(22, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 4)

                        Spacer()
                        Mascot(state: .idle, size: 120)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 360)
                .padding(.horizontal, 24)
                .padding(.top, 14)

                Spacer()

                CTAButton(label: "Continue", variant: .ink, action: { onNext(ages[selectedIndex]) })
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }
}

#Preview("Age") {
    AgeView(initial: 8, onBack: {}, onNext: { _ in })
        .environment(AppState())
}

// MARK: - IntroView
struct IntroView: View {
    let name: String
    let onBack: () -> Void
    let onNext: () -> Void

    private let tips: [(icon: QuackIconName, title: String, body: String, color: Color)] = [
        (.camera, "Point at things",   "Show Q an apple. Q tells you what it is in Mandarin.", .quackOrange),
        (.mic,    "Say it back",       "Repeat the word. Q listens and tells you if it sounds right.", .cobalt),
        (.star,   "Collect stickers",  "Every word you learn becomes a sticker in your book.", .mintDeep),
    ]

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
                    Eyebrow(text: "Step 3 of 3", flank: false, size: 11)
                    Text("How it works, \(name)")
                        .font(.display(30, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("Three things to know before your first mission")
                        .font(.bodyText(14))
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                VStack(spacing: 12) {
                    ForEach(tips.indices, id: \.self) { i in
                        let tip = tips[i]
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(tip.color)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    QuackIcon(name: tip.icon, size: 28, color: .white, strokeWidth: 2.2)
                                )
                                .cardShadow()

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tip.title)
                                    .font(.display(18, weight: .heavy))
                                    .foregroundStyle(Color.ink)
                                Text(tip.body)
                                    .font(.bodyText(13))
                                    .foregroundStyle(Color.inkMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .quackCard()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                CTAButton(label: "Start my first mission", variant: .orange, action: onNext)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }
}

#Preview("Intro") {
    IntroView(name: "Nia", onBack: {}, onNext: {})
        .environment(AppState())
}
