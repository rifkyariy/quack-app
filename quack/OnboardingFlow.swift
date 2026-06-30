import SwiftUI
import UIKit

// MARK: - Haptic feedback helper
func triggerSwipeHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}

// MARK: - OnboardingFlow coordinator
struct OnboardingFlow: View {
    let onComplete: () -> Void
    @Environment(AppState.self) private var appState

    enum Step: Int { case splash = 0, name = 1, gender = 2, age = 3, setup = 4 }
    @State private var step: Step = .splash
    @State private var slideDirection: CGFloat = 1  // 1 = forward, -1 = back
    @State private var flowVisible: Bool = false    // For entry animation

    private func advance() {
        if step.rawValue < 4 {
            step = Step(rawValue: step.rawValue + 1) ?? .setup
        }
    }

    private func retreat() {
        if step.rawValue > 1 {
            step = Step(rawValue: step.rawValue - 1) ?? .name
        }
    }

    // ponytail: dots now live inside each step view
    private var progressBar: some View { EmptyView() }

    private var asymmetricTransition: AnyTransition { .opacity }

    var body: some View {
        Group {
            switch step {
            case .splash:
                SplashView(onNext: { withAnimation { step = .name } })
            default:
                VStack(spacing: 0) {
                    if step != .setup {
                        progressBar
                    }
                    ZStack {
                        switch step {
                        case .name:
                            NameView(
                                initialName: appState.name,
                                initialCodename: appState.codename,
                                onBack: { withAnimation { step = .splash } },
                                onNext: { name, codename in
                                    appState.name = name
                                    appState.codename = codename
                                    withAnimation { step = .gender }
                                }
                            )
                        case .gender:
                            GenderView(
                                initial: appState.gender,
                                onBack: { withAnimation { step = .name } },
                                onNext: { gender in
                                    appState.gender = gender
                                    withAnimation { step = .age }
                                }
                            )
                        case .age:
                            AgeView(
                                initial: appState.age,
                                onBack: { withAnimation { step = .gender } },
                                onNext: { age in
                                    appState.age = age
                                    withAnimation { step = .setup }
                                }
                            )
                        case .setup:
                            SetupView(onNext: onComplete)
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(step)
                    .transition(asymmetricTransition)
                }
                .background(Color.cream.ignoresSafeArea())
            }
        }
        .offset(y: flowVisible ? 0 : 48)
        .opacity(flowVisible ? 1 : 0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    flowVisible = true
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height

                    // Require 2× horizontal bias, minimum 50pt translation
                    guard abs(dx) > abs(dy) * 2, abs(dx) > 50 else { return }

                    // Dismiss keyboard
                    #if canImport(UIKit)
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    #endif

                    if dx < 0 {
                        // Left swipe — advance
                        // Validate name on step 1
                        if step == .name,
                           appState.name.trimmingCharacters(in: .whitespaces).isEmpty {
                            // Shake and error haptic
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            return
                        }
                        slideDirection = 1
                        withAnimation(.easeOut(duration: 0.2)) {
                            advance()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } else {
                        // Right swipe — back
                        slideDirection = -1
                        withAnimation(.easeOut(duration: 0.2)) {
                            retreat()
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
        )
    }
}

// MARK: - SplashView (onboarding intro)
struct SplashView: View {
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            FloatingShapes()

            VStack(spacing: 0) {
                Spacer()

                

                VStack(spacing: 10) {
                    Text("Let's learn\nMandarin!")
                        .font(.display(36, weight: .black))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)

                    Text("Quack makes learning Mandarin fun and easy!\nYour AI buddy for play, practice, and mastering Chinese.")
                        .font(.bodyText(14))
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .offset(y: appeared ? 0 : 14)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.38).delay(0.2), value: appeared)
                .padding(.top, 28)

                Spacer()

                VStack(spacing: 0) {
                    Image("mascot-aha")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 270)
                        .shadow(color: .ink.opacity(0.10), radius: 24, x: 0, y: 12)
                        .scaleEffect(appeared ? 1 : 0.75)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.58).delay(0.05), value: appeared)
                        .padding(.leading, 12)

                    CTAButton(label: "Let's go!", variant: .orange, action: onNext)
                        .padding(.horizontal, 24)
                        .offset(y: appeared ? 0 : 14)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.38).delay(0.3), value: appeared)
                }

                StepDots(current: 0, total: 4)
                    .padding(.top, 20)
                    .padding(.bottom, 36)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.35), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - NameView
struct NameView: View {
    let initialName: String
    let initialCodename: String
    let onBack: () -> Void
    let onNext: (String, String) -> Void

    @State private var name: String
    @State private var selectedAgent: String
    @State private var appeared = false
    @FocusState private var focused: Bool

    private let agents = ["icon-agent-q","icon-agent-b","icon-agent-c",
                          "icon-agent-d","icon-agent-p","icon-agent-t"]

    init(initialName: String, initialCodename: String,
         onBack: @escaping () -> Void, onNext: @escaping (String, String) -> Void) {
        self.initialName = initialName
        self.initialCodename = initialCodename
        self.onBack = onBack
        self.onNext = onNext
        _name = State(initialValue: initialName)
        _selectedAgent = State(initialValue: initialCodename.isEmpty ? "icon-agent-q" : initialCodename)
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            FloatingShapes()

            VStack(spacing: 0) {
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Title
                        VStack(spacing: 8) {
                            Text("Set up your profile")
                                .font(.display(28, weight: .black))
                                .foregroundStyle(Color.ink)
                                .multilineTextAlignment(.center)
                            Text("Tell us your name and pick your agent!")
                                .font(.bodyText(14))
                                .foregroundStyle(Color.inkMuted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 28).padding(.top, 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.35).delay(0.05), value: appeared)

                        // Selected agent preview
                        Image(selectedAgent)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding(.top, 20)
                            .scaleEffect(appeared ? 1 : 0.7)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.1), value: appeared)
                            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selectedAgent)

                        // Name field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your name")
                                .font(.bodyText(12, weight: .bold))
                                .foregroundStyle(Color.inkMuted)
                                .padding(.horizontal, 4)
                            HStack(spacing: 12) {
                                TextField("e.g. Alex", text: $name)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.ink)
                                    .focused($focused)
                                    .submitLabel(.done)
                                    .onSubmit { focused = false }
                                Image(systemName: "pencil")
                                    .foregroundStyle(Color.inkMuted)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(Color.paper)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .cardShadow()
                        }
                        .padding(.horizontal, 24).padding(.top, 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.35).delay(0.15), value: appeared)

                        // Codename / agent picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your codename")
                                .font(.bodyText(12, weight: .bold))
                                .foregroundStyle(Color.inkMuted)
                                .padding(.horizontal, 4)

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                                spacing: 12
                            ) {
                                ForEach(agents, id: \.self) { agent in
                                    let sel = agent == selectedAgent
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            selectedAgent = agent
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(sel ? Color.quackOrange.opacity(0.1) : Color.paper)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 18)
                                                        .stroke(sel ? Color.quackOrange : Color.inkFaint,
                                                                lineWidth: sel ? 2.5 : 1)
                                                )
                                            Image(agent)
                                                .resizable()
                                                .scaledToFit()
                                                .padding(10)
                                        }
                                        .frame(height: 84)
                                        .scaleEffect(sel ? 1.06 : 1)
                                    }
                                    .buttonStyle(TapPress())
                                }
                            }
                        }
                        .padding(.horizontal, 24).padding(.top, 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.35).delay(0.2), value: appeared)

                        Spacer(minLength: 24)
                    }
                }

                CTAButton(
                    label: "Next",
                    variant: .orange,
                    disabled: name.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    focused = false
                    let t = name.trimmingCharacters(in: .whitespaces)
                    onNext(t.isEmpty ? "Agent" : t, selectedAgent)
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.25), value: appeared)

                StepDots(current: 1, total: 4)
                    .padding(.top, 16).padding(.bottom, 32)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onTapGesture { focused = false }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { focused = true }
            }
        }
    }
}

#Preview("Splash") {
    SplashView(onNext: {})
        .environment(AppState())
}

#Preview("Name") {
    NameView(initialName: "Alex", initialCodename: "icon-agent-q", onBack: {}, onNext: { _, _ in })
        .environment(AppState())
}

// MARK: - AgeDrumPicker
private struct AgeDrumPicker: View {
    @Binding var age: Int
    private let ages = Array(3...14)
    private let itemH: CGFloat = 54

    @State private var scrollPos: CGFloat = 0   // center position in points
    @State private var savedPos: CGFloat = 0
    @State private var isDragging = false
    @State private var lastTick = -1

    var body: some View {
        ZStack {
            // Selection band
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.quackOrange.opacity(0.08))
                .frame(height: itemH)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.quackOrange.opacity(0.28), lineWidth: 1.5))

            // 3D wheel items — rotation applied before offset so it pivots at ZStack center
            ForEach(ages.indices, id: \.self) { i in
                let rawY = CGFloat(i) * itemH - scrollPos
                let slot  = rawY / itemH
                if abs(slot) < 3.0 {
                    let angle = slot * 30.0
                    let fade  = Double(max(0, 1 - abs(slot) / 2.6))
                    let sel   = abs(slot) < 0.45
                    Text("\(ages[i])")
                        .font(.system(
                            size: sel ? 44 : (abs(slot) < 1.45 ? 29 : 19),
                            weight: sel ? .black : .semibold,
                            design: .rounded
                        ))
                        .foregroundStyle(sel ? Color.quackOrange : Color.ink)
                        .opacity(fade)
                        .rotation3DEffect(
                            .degrees(-angle),
                            axis: (x: 1, y: 0, z: 0),
                            perspective: 0.45
                        )
                        .offset(y: rawY)
                }
            }

            // Top + bottom cream fade masks
            VStack {
                LinearGradient(colors: [Color.cream, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: itemH * 1.6)
                Spacer()
                LinearGradient(colors: [.clear, Color.cream], startPoint: .top, endPoint: .bottom)
                    .frame(height: itemH * 1.6)
            }
            .allowsHitTesting(false)
        }
        .frame(height: itemH * 5)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { v in
                    if !isDragging { savedPos = scrollPos; isDragging = true }
                    scrollPos = savedPos - v.translation.height

                    // Selection tick on each integer crossing
                    let liveIdx = min(max(Int((scrollPos / itemH).rounded()), 0), ages.count - 1)
                    if liveIdx != lastTick {
                        lastTick = liveIdx
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
                .onEnded { v in
                    isDragging = false; lastTick = -1
                    // Add a bit of momentum via velocity
                    let projected = scrollPos - v.velocity.height * 0.1
                    let idx = min(max(Int((projected / itemH).rounded()), 0), ages.count - 1)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.76)) {
                        scrollPos = CGFloat(idx) * itemH
                    }
                    let newAge = ages[idx]
                    if newAge != age {
                        age = newAge
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                }
        )
        .onAppear {
            scrollPos = CGFloat(ages.firstIndex(of: age) ?? 0) * itemH
        }
    }
}

// MARK: - AgeView
struct AgeView: View {
    let initial: Int
    let onBack: () -> Void
    let onNext: (Int) -> Void

    @State private var age: Int
    @State private var appeared = false

    init(initial: Int, onBack: @escaping () -> Void, onNext: @escaping (Int) -> Void) {
        self.initial = initial
        self.onBack = onBack
        self.onNext = onNext
        _age = State(initialValue: max(4, min(12, initial)))
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            FloatingShapes()

            VStack(spacing: 0) {
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)

                // Title centered
                VStack(spacing: 8) {
                    Text("How old are you?")
                        .font(.display(30, weight: .black))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                    Text("We'll personalise your learning just for you!")
                        .font(.bodyText(14))
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32).padding(.top, 20)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.05), value: appeared)

                // Birthday cake with age overlaid on the cake face (bottom ~25% of image)
                Image("birthday-bg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .overlay(alignment: .bottom) {
                        Text("\(age)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(Color.quackOrange)
                            .shadow(color: .white.opacity(0.8), radius: 5)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: age)
                            .padding(.bottom, 20)
                    }
                .padding(.top, 20)
                .scaleEffect(appeared ? 1 : 0.75)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

                // Drum picker
                AgeDrumPicker(age: $age)
                    .padding(.horizontal, 60)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.18), value: appeared)

                Spacer()

                CTAButton(label: "Next", variant: .orange, action: { onNext(age) })
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.25), value: appeared)

                StepDots(current: 3, total: 4)
                    .padding(.top, 16).padding(.bottom, 32)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear { appeared = true }
        .gesture(DragGesture().onEnded { v in
            if v.translation.width > 50 { triggerSwipeHaptic(); onBack() }
        })
    }
}

#Preview("Age") {
    AgeView(initial: 8, onBack: {}, onNext: { _ in })
        .environment(AppState())
}

// MARK: - GenderView
struct GenderView: View {
    let initial: Gender
    let onBack: () -> Void
    let onNext: (Gender) -> Void

    @State private var selected: Gender
    @State private var appeared = false

    init(initial: Gender, onBack: @escaping () -> Void, onNext: @escaping (Gender) -> Void) {
        self.initial = initial
        self.onBack = onBack
        self.onNext = onNext
        _selected = State(initialValue: initial)
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            FloatingShapes()

            VStack(spacing: 0) {
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)
                .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(spacing: 8) {
                    Text("Who are you?")
                        .font(.display(28, weight: .black))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                    Text("Our Agent will personalise your experience for you!")
                        .font(.bodyText(14))
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32).padding(.top, 20)
                .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: appeared)

                HStack(spacing: 14) {
                    GenderImageCard(
                        label: "Boy",
                        imageName: "onboarding-boy",
                        isSelected: selected == .boy
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selected = .boy
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }

                    GenderImageCard(
                        label: "Girl",
                        imageName: "onboarding-girl",
                        isSelected: selected == .girl
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selected = .girl
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .padding(.horizontal, 24).padding(.top, 24)
                .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                Spacer()

                CTAButton(label: "Next", variant: .orange, action: { onNext(selected) })
                    .padding(.horizontal, 24)
                    .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)

                StepDots(current: 2, total: 4)
                    .padding(.top, 16).padding(.bottom, 32)
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .gesture(DragGesture().onEnded { v in
            if v.translation.width > 50 { triggerSwipeHaptic(); onBack() }
        })
    }
}

// MARK: - GenderImageCard
private struct GenderImageCard: View {
    let label: String
    let imageName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? Color.quackOrange : Color.clear, lineWidth: 3)
                    )

                Text(label)
                    .font(.display(16, weight: .heavy))
                    .foregroundStyle(isSelected ? Color.ink : Color.inkMuted)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(TapPress())
        .accessibilityLabel(label)
        .accessibilityHint("Gender selection. Select \(label)")
    }
}

// MARK: - IntroView ("How Quack works")
struct IntroView: View {
    let name: String
    let onBack: () -> Void
    let onNext: () -> Void

    @State private var appeared = false

    private let steps: [(symbol: String, title: String, body: String, color: Color)] = [
        ("gamecontroller.fill", "Choose a Mission",      "Pick a fun topic to explore",                  .cobalt),
        ("camera.fill",         "Scan an Object",        "Use your camera to scan anything",              .quackOrange),
        ("plus.circle.fill",    "Get the Translation",   "See the Chinese word and meaning",              .quackOrange),
        ("mic.fill",            "Practice & Pronounce",  "Learn the tone and perfect your pronunciation", .cobalt),
        ("star.fill",           "Collect Stickers",      "Earn stickers and unlock new rewards!",         .quackYellow),
    ]

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text("How Quack works")
                                .font(.display(28, weight: .black))
                                .foregroundStyle(Color.ink)
                            Text("Learn, play, and grow with Quack in 5 fun steps!")
                                .font(.bodyText(14))
                                .foregroundStyle(Color.inkMuted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32).padding(.top, 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.35).delay(0.05), value: appeared)

                        // Connected steps
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(steps.indices, id: \.self) { i in
                                let s = steps[i]
                                HStack(alignment: .top, spacing: 16) {
                                    VStack(spacing: 0) {
                                        ZStack {
                                            Circle()
                                                .fill(s.color.opacity(0.12))
                                                .frame(width: 52, height: 52)
                                            Image(systemName: s.symbol)
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundStyle(s.color)
                                        }
                                        if i < steps.count - 1 {
                                            Rectangle()
                                                .fill(Color.inkFaint)
                                                .frame(width: 2, height: 24)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(s.title)
                                            .font(.display(16, weight: .heavy))
                                            .foregroundStyle(Color.ink)
                                        Text(s.body)
                                            .font(.bodyText(13))
                                            .foregroundStyle(Color.inkMuted)
                                    }
                                    .padding(.top, 14)
                                    Spacer()
                                }
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.35).delay(0.1 + Double(i) * 0.06), value: appeared)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 28)
                        .padding(.bottom, 16)
                    }
                }

                CTAButton(label: "Let's quack!", variant: .orange, action: onNext)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.4), value: appeared)

                StepDots(current: 3, total: 4)
                    .padding(.top, 16).padding(.bottom, 32)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear { appeared = true }
        .gesture(DragGesture().onEnded { v in
            if v.translation.width > 50 { triggerSwipeHaptic(); onBack() }
        })
    }
}

// MARK: - Shared: step dot indicator
struct StepDots: View {
    let current: Int
    let total: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.quackOrange : Color.quackOrange.opacity(0.2))
                    .frame(width: i == current ? 22 : 8, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
            }
        }
    }
}

#Preview("Splash onboarding") {
    SplashView(onNext: {})
        .environment(AppState())
}
#Preview("Name") {
    NameView(initialName: "Alex", initialCodename: "icon-agent-q", onBack: {}, onNext: { _, _ in })
        .environment(AppState())
}
#Preview("Age") {
    AgeView(initial: 5, onBack: {}, onNext: { _ in })
        .environment(AppState())
}
#Preview("Intro") {
    IntroView(name: "Nia", onBack: {}, onNext: {})
        .environment(AppState())
}
