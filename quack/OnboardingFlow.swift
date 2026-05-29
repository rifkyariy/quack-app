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

    enum Step: Int { case splash = 0, name = 1, gender = 2, age = 3, intro = 4, setup = 5 }
    @State private var step: Step = .splash
    @State private var slideDirection: CGFloat = 1  // 1 = forward, -1 = back
    @State private var flowVisible: Bool = false    // For entry animation

    private func advance() {
        if step.rawValue < 5 {
            step = Step(rawValue: step.rawValue + 1) ?? .setup
        }
    }

    private func retreat() {
        if step.rawValue > 1 {
            step = Step(rawValue: step.rawValue - 1) ?? .name
        }
    }

    private var progressBar: some View {
        let progressIdx = step.rawValue - 1  // name=0, gender=1, age=2, intro=3
        return HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { idx in
                Capsule()
                    .fill(idx <= progressIdx ? Color.quackOrange : Color.quackOrange.opacity(0.25))
                    .frame(width: idx == progressIdx ? 28 : 8, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var asymmetricTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: slideDirection > 0 ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: slideDirection > 0 ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    var body: some View {
        Group {
            switch step {
            case .splash:
                SplashView(onNext: { withAnimation { step = .name } })
            case .name:
                VStack(spacing: 0) {
                    progressBar
                    ZStack {
                        NameView(
                            initial: appState.name,
                            onBack: { withAnimation { step = .splash } },
                            onNext: { name in
                                appState.name = name
                                withAnimation { step = .gender }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(step)
                    .transition(asymmetricTransition)
                }
            case .gender:
                VStack(spacing: 0) {
                    progressBar
                    ZStack {
                        GenderView(
                            initial: appState.gender,
                            onBack: { withAnimation { step = .name } },
                            onNext: { gender in
                                appState.gender = gender
                                withAnimation { step = .age }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(step)
                    .transition(asymmetricTransition)
                }
            case .age:
                VStack(spacing: 0) {
                    progressBar
                    ZStack {
                        AgeView(
                            initial: appState.age,
                            onBack: { withAnimation { step = .gender } },
                            onNext: { age in
                                appState.age = age
                                withAnimation { step = .intro }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(step)
                    .transition(asymmetricTransition)
                }
            case .intro:
                VStack(spacing: 0) {
                    progressBar
                    ZStack {
                        IntroView(
                            name: appState.name,
                            onBack: { withAnimation { step = .age } },
                            onNext: { withAnimation { step = .setup } }
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(step)
                    .transition(asymmetricTransition)
                }
            case .setup:
                SetupView(onNext: onComplete)
                    .id(step)
                    .transition(asymmetricTransition)
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
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            advance()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } else {
                        // Right swipe — back
                        slideDirection = -1
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            retreat()
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
        )
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

                Spacer().frame(height: 32)
            }
            .scrollableWhenCompact()
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
    @State private var appeared = false
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
                .onTapGesture {
                    focused = false
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width > 50 {
                                triggerSwipeHaptic()
                                focused = false
                                onBack()
                            }
                        }
                )

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    BackBtn(action: onBack)

                    Spacer()

                    Text("Step 1 of 4")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkMuted)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(alignment: .leading, spacing: 14) {
                    Eyebrow(text: "Agent setup", flank: false, size: 11)
                    Text("What should Q call you?")
                        .font(.display(34, weight: .black))
                        .foregroundStyle(Color.ink)
                    Text("Enter your first name so your missions feel personal.")
                        .font(.bodyText(15))
                        .foregroundStyle(Color.inkMuted)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: appeared)

                Spacer(minLength: 16)

                VStack(spacing: 20) {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 36)
                            .fill(LinearGradient(
                                colors: [Color.quackOrange, Color.quackOrangeSoft],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .grain()
                            .popShadow()
                            .onTapGesture {
                                focused = false
                            }

                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.88))
                            .padding(22)
                            .onTapGesture {
                                focused = false
                            }

                        VStack(spacing: 24) {
                            Text("Your name")
                                .font(.bodyText(13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.top, 26)
                                .onTapGesture {
                                    focused = false
                                }

                            TextField("e.g. Nia", text: $name)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.vertical, 18)
                                .padding(.horizontal, 20)
                                .background(Color.white.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .padding(.horizontal, 22)
                                .focused($focused)
                                .submitLabel(.done)
                                .onSubmit {
                                    focused = false
                                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                                    if !trimmed.isEmpty { onNext(trimmed) }
                                }

                            Text("Q will use this name in mission prompts and celebration messages.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.88))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                                .padding(.bottom, 24)
                                .onTapGesture {
                                    focused = false
                                }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 260)
                }
                .padding(.horizontal, 24)
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                Spacer(minLength: 12)

                CTAButton(
                    label: "Continue",
                    variant: .ink,
                    disabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                    action: {
                        focused = false
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        onNext(trimmed.isEmpty ? "Agent" : trimmed)
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)
            }
            .scrollableWhenCompact()
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
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
    NameView(initial: "Alex", onBack: {}, onNext: { _ in })
        .environment(AppState())
}

// MARK: - AgeStepButton
private struct AgeStepButton: View {
    let symbol: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(enabled ? Color.ink : Color.ink.opacity(0.3))
                .frame(width: 48, height: 48)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .ink.opacity(0.12), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(TapPress())
        .disabled(!enabled)
    }
}

// MARK: - AgeSliderTrack
private struct AgeSliderTrack: View {
    @Binding var age: Int
    private let minAge = 4
    private let maxAge = 12
    private let totalSteps = 9

    @GestureState private var isDragging = false

    private var fraction: Double {
        Double(age - minAge) / Double(maxAge - minAge)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let thumbX = max(13, min(w - 13, fraction * w))
            let tickSpacing = w / Double(totalSteps - 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 6)
                Capsule()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: thumbX, height: 6)
                ForEach(0..<totalSteps, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(i % 3 == 0 ? 0.7 : 0.35))
                        .frame(width: 2, height: i % 3 == 0 ? 12 : 7)
                        .position(x: Double(i) * tickSpacing, y: geo.size.height / 2)
                }
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 30 : 26, height: isDragging ? 30 : 26)
                    .shadow(color: .ink.opacity(0.18), radius: isDragging ? 8 : 4, x: 0, y: 2)
                    .position(x: thumbX, y: geo.size.height / 2)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isDragging)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, s, _ in s = true }
                    .onChanged { v in
                        let frac = max(0, min(1, v.location.x / w))
                        let newAge = Int((frac * 8).rounded()) + minAge
                        if newAge != age {
                            age = newAge
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
            )
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

    private func stepAge(by delta: Int) {
        let newAge = max(4, min(12, age + delta))
        if newAge != age {
            age = newAge
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)
                .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Step 3 of 4", flank: false, size: 11)
                    Text("How old are you?")
                        .font(.display(28, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("Q adjusts the level to match")
                        .font(.bodyText(13))
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).padding(.top, 14)
                .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: appeared)

                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.quackOrange)
                        .grain()
                        .popShadow()

                    Sparkles(count: 4, opacity: 0.5)

                    VStack(spacing: 20) {
                        // Big animated number
                        VStack(spacing: 4) {
                            Text("\(age)")
                                .font(.display(80, weight: .black))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText(countsDown: false))
                                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: age)
                                .frame(minWidth: 120)
                            Text("years old")
                                .font(.bodyText(14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        // − | slider | +
                        HStack(spacing: 12) {
                            AgeStepButton(symbol: "minus", enabled: age > 4) {
                                stepAge(by: -1)
                            }
                            AgeSliderTrack(age: $age)
                                .frame(height: 44)
                            AgeStepButton(symbol: "plus", enabled: age < 12) {
                                stepAge(by: 1)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 28)
                }
                .frame(maxWidth: .infinity, minHeight: 280)
                .padding(.horizontal, 24).padding(.top, 14)
                .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                Spacer()

                CTAButton(label: "Continue", variant: .ink, action: { onNext(age) })
                    .padding(.horizontal, 24).padding(.bottom, 28)
                    .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)
            }
            .scrollableWhenCompact()
        }
        .onAppear { withAnimation { appeared = true } }
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

            VStack(spacing: 0) {
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)
                .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Step 2 of 4", flank: false, size: 11)
                    Text("Who are you?")
                        .font(.display(28, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("Q will use this to personalise your experience")
                        .font(.bodyText(13))
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).padding(.top, 14)
                .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: appeared)

                HStack(spacing: 14) {
                    GenderTile(
                        label: "Boy",
                        icon: "figure.stand",
                        color: Color.cobalt,
                        isSelected: selected == .boy
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selected = .boy
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }

                    GenderTile(
                        label: "Girl",
                        icon: "figure.stand.dress",
                        color: Color.rose,
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

                CTAButton(label: "Continue", variant: .ink, action: { onNext(selected) })
                    .padding(.horizontal, 24).padding(.bottom, 28)
                    .offset(y: appeared ? 0 : 16).opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .gesture(DragGesture().onEnded { v in
            if v.translation.width > 50 { triggerSwipeHaptic(); onBack() }
        })
    }
}

// MARK: - GenderTile
private struct GenderTile: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : color.opacity(0.8))
                }
                Text(label)
                    .font(.display(17, weight: .heavy))
                    .foregroundStyle(isSelected ? Color.ink : Color.inkMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(isSelected ? color : Color.inkFaint, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(TapPress())
        .accessibilityLabel(label)
        .accessibilityHint("Gender selection. Select \(label)")
    }
}

// MARK: - IntroView
struct IntroView: View {
    let name: String
    let onBack: () -> Void
    let onNext: () -> Void

    @State private var appeared = false

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
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Step 4 of 4", flank: false, size: 11)
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
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: appeared)

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
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                Spacer()

                CTAButton(label: "Start my first mission", variant: .orange, action: onNext)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .offset(y: appeared ? 0 : 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)
            }
            .scrollableWhenCompact()
        }
        .onAppear {
            withAnimation { appeared = true }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        triggerSwipeHaptic()
                        onBack()
                    }
                }
        )
    }
}

#Preview("Intro") {
    IntroView(name: "Nia", onBack: {}, onNext: {})
        .environment(AppState())
}
