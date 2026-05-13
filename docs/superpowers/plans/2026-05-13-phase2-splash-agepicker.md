# Quack Phase 2 + Launch Splash + AgeView Arc Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a cold-start launch splash, redesign AgeView with an arc/fan picker, implement all Phase 2 mission screens, and wire everything into MainTabView.

**Architecture:** `LaunchSplashView` sits as a ZStack overlay in `AppView`, auto-dismissing after 1.8s then revealing whatever is behind (onboarding or home). All mission views are presented as `.fullScreenCover` from `MainTabView`. `CompleteView` is a separate `.fullScreenCover` triggered after any mission finishes. A `#if DEBUG` block in `AppView.onAppear` always resets `hasOnboarded` to `false`.

**Tech Stack:** SwiftUI, `@Observable`, `@GestureState`, `Canvas`, `TimelineView`, `Task.sleep`, `DispatchQueue.main.asyncAfter`

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Create | `quack/LaunchSplashView.swift` | Cold-start splash, auto-dismiss |
| Modify | `quack/AppView.swift` | Add LaunchSplashView overlay + DEBUG reset |
| Modify | `quack/OnboardingFlow.swift` | Replace AgeView with arc/fan picker |
| Create | `quack/ObjectArt.swift` | Emoji+toned-circle vocab illustration |
| Modify | `quack/Components.swift` | Add `WaveBar` component |
| Create | `quack/MissionHeader.swift` | Top bar for mission views + `MissionType` enum |
| Create | `quack/CompleteView.swift` | Mission complete full-screen |
| Create | `quack/MissionsHubView.swift` | Tab 2 — 4 mission cards |
| Create | `quack/CameraMissionView.swift` | Camera/scan mission (3 phases) |
| Create | `quack/SpeakMissionView.swift` | Speak/repeat mission (3 words) |
| Create | `quack/MatchMissionView.swift` | Match character to image (3 rounds) |
| Create | `quack/StoryMissionView.swift` | Story + quiz mission |
| Modify | `quack/MainTabView.swift` | Wire all missions, replace placeholders |
| Modify | `quack/HomeView.swift` | Update `onMission` callback signature |

---

## Task 1: LaunchSplashView + AppView

**Files:**
- Create: `quack/LaunchSplashView.swift`
- Modify: `quack/AppView.swift`

- [ ] **Step 1.1: Create `LaunchSplashView.swift`**

```swift
import SwiftUI

struct LaunchSplashView: View {
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.quackOrange.ignoresSafeArea()
            Sparkles(count: 8, animate: true)

            VStack(spacing: 0) {
                Spacer()
                Mascot(state: .speaking, size: 100)
                    .padding(.bottom, 24)

                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("Q")
                        .font(.display(72, weight: .black))
                        .foregroundStyle(.white)
                    Text("uack")
                        .font(.display(48, weight: .black))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
            Task {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                onDismiss()
            }
        }
    }
}

#Preview {
    LaunchSplashView(onDismiss: {})
        .environment(AppState())
}
```

- [ ] **Step 1.2: Update `AppView.swift`**

Replace the entire file:

```swift
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
```

- [ ] **Step 1.3: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED` with no errors.

- [ ] **Step 1.4: Commit**

```bash
git add quack/LaunchSplashView.swift quack/AppView.swift
git commit -m "feat: add LaunchSplashView with auto-dismiss + DEBUG onboarding reset in AppView"
```

---

## Task 2: AgeView Arc/Fan Picker

**Files:**
- Modify: `quack/OnboardingFlow.swift` (replace `AgeView` struct only — keep all other structs unchanged)

- [ ] **Step 2.1: Replace the AgeView struct**

In `quack/OnboardingFlow.swift`, replace everything between `// MARK: - AgeView` and `#Preview("Age")` (exclusive) with:

```swift
// MARK: - AgeView
struct AgeView: View {
    let initial: Int
    let onBack: () -> Void
    let onNext: (Int) -> Void

    private let ages = Array(4...12)          // 9 items, indices 0–8
    private let radius: CGFloat = 140
    private let stepAngleDeg: Double = 22.5   // 180° / 8 intervals

    @State private var selectedIndex: Int
    @GestureState private var dragOffset: CGFloat = 0

    init(initial: Int, onBack: @escaping () -> Void, onNext: @escaping (Int) -> Void) {
        self.initial = initial
        self.onBack = onBack
        self.onNext = onNext
        _selectedIndex = State(initialValue: max(0, min(8, initial - 4)))
    }

    // stepPoints: how many screen-pts equal one age step on the arc
    private var stepPoints: Double { Double(radius) * stepAngleDeg * .pi / 180 }

    // floating selected position including live drag
    private var floatSelected: Double {
        Double(selectedIndex) - Double(dragOffset) / stepPoints
    }

    // angle in degrees for item i relative to floatSelected
    // 90° = 6 o'clock (bottom) = selected position
    private func angleDeg(for i: Int) -> Double {
        90.0 + (Double(i) - floatSelected) * stepAngleDeg
    }

    private func itemDist(for i: Int) -> Double {
        abs(floatSelected - Double(i))
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
                        // Arc picker
                        GeometryReader { geo in
                            let cx = geo.size.width / 2
                            let cy: CGFloat = 30   // circle center near top of area

                            ZStack {
                                ForEach(ages.indices, id: \.self) { i in
                                    let θ = angleDeg(for: i) * .pi / 180
                                    let x = cx + radius * CGFloat(cos(θ))
                                    let y = cy + radius * CGFloat(sin(θ))
                                    let dist = itemDist(for: i)
                                    let scale = max(0.45, 1.0 - dist * 0.275)
                                    let opacity = max(0.3, 1.0 - dist * 0.35)
                                    let isCenter = dist < 0.25

                                    ZStack {
                                        if isCenter {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 64, height: 64)
                                                .popShadow()
                                        }
                                        Text("\(ages[i])")
                                            .font(.display(isCenter ? 42 : 30, weight: .heavy))
                                            .foregroundStyle(isCenter ? Color.ink : Color.white)
                                    }
                                    .scaleEffect(scale)
                                    .opacity(opacity)
                                    .position(x: x, y: y)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { val, state, _ in
                                        state = val.translation.width
                                    }
                                    .onEnded { val in
                                        let steps = Int(
                                            (-val.predictedEndTranslation.width / CGFloat(stepPoints))
                                                .rounded()
                                        )
                                        selectedIndex = max(0, min(ages.count - 1, selectedIndex + steps))
                                    }
                            )
                        }
                        .frame(height: 220)
                        .padding(.top, 16)

                        VStack(spacing: 2) {
                            Text("I AM")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .tracking(12 * 0.14)
                                .foregroundStyle(.white.opacity(0.85))
                            Text("\(ages[max(0, min(ages.count - 1, Int(floatSelected.rounded())))]) years old")
                                .font(.display(22, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 4)

                        Spacer()
                        Mascot(state: .idle, size: 110)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 380)
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
```

- [ ] **Step 2.2: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 2.3: Commit**

```bash
git add quack/OnboardingFlow.swift
git commit -m "feat: replace AgeView drag wheel with arc/fan picker (U-shaped, 6 o'clock snap)"
```

---

## Task 3: ObjectArt + WaveBar

**Files:**
- Create: `quack/ObjectArt.swift`
- Modify: `quack/Components.swift` (append WaveBar before last `#Preview`)

- [ ] **Step 3.1: Create `ObjectArt.swift`**

```swift
import SwiftUI

struct ObjectArt: View {
    let vocab: VocabItem
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle()
                .fill(vocab.tone.bg.opacity(0.22))
                .frame(width: size, height: size)
            Circle()
                .fill(vocab.tone.bg.opacity(0.14))
                .frame(width: size * 0.72, height: size * 0.72)
            Text(vocab.emoji)
                .font(.system(size: size * 0.48))
        }
        .frame(width: size, height: size)
    }
}

#Preview("ObjectArt") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
        ForEach(VOCAB.prefix(8)) { v in
            ObjectArt(vocab: v, size: 72)
        }
    }
    .padding()
    .background(Color.cream)
}
```

- [ ] **Step 3.2: Add `WaveBar` to `Components.swift`**

Append before the final `#Preview("Confetti")` block in `Components.swift`:

```swift
// MARK: - WaveBar
struct WaveBar: View {
    let index: Int
    var animating: Bool = false
    var color: Color = .quackOrange

    private let heights: [CGFloat] = [22, 38, 54, 38, 22]

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: 6, height: animating ? heights[index % heights.count] : 10)
            .animation(
                .easeInOut(duration: 0.36 + Double(index) * 0.08)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.12),
                value: animating
            )
    }
}
```

- [ ] **Step 3.3: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3.4: Commit**

```bash
git add quack/ObjectArt.swift quack/Components.swift
git commit -m "feat: add ObjectArt emoji fallback component and WaveBar to Components"
```

---

## Task 4: MissionHeader + MissionType

**Files:**
- Create: `quack/MissionHeader.swift`

- [ ] **Step 4.1: Create `MissionHeader.swift`**

```swift
import SwiftUI

// MARK: - MissionType
enum MissionType: String, CaseIterable, Identifiable {
    case camera, speak, match, story
    var id: String { rawValue }

    var title: String {
        switch self {
        case .camera: "Scan it"
        case .speak:  "Say it"
        case .match:  "Match it"
        case .story:  "Story time"
        }
    }

    var subtitle: String {
        switch self {
        case .camera: "Find the word in the world"
        case .speak:  "Repeat what Q says"
        case .match:  "Pick the right character"
        case .story:  "Read and listen"
        }
    }

    var icon: QuackIconName {
        switch self {
        case .camera: .camera
        case .speak:  .mic
        case .match:  .mission
        case .story:  .book
        }
    }

    var tone: Tone {
        switch self {
        case .camera: .orange
        case .speak:  .cobalt
        case .match:  .rose
        case .story:  .mint
        }
    }
}

// MARK: - MissionHeader
struct MissionHeader: View {
    let title: String
    var accent: Color = .quackOrange
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            BackBtn(action: onBack)
            Spacer()
            Text(title)
                .font(.display(17, weight: .heavy))
                .foregroundStyle(Color.ink)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

#Preview("MissionHeader") {
    VStack {
        MissionHeader(title: "Scan it", onBack: {})
        MissionHeader(title: "Say it", accent: .cobalt, onBack: {})
        Spacer()
    }
    .background(Color.cream)
}
```

- [ ] **Step 4.2: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4.3: Commit**

```bash
git add quack/MissionHeader.swift
git commit -m "feat: add MissionType enum and MissionHeader component"
```

---

## Task 5: CompleteView

**Files:**
- Create: `quack/CompleteView.swift`

- [ ] **Step 5.1: Create `CompleteView.swift`**

```swift
import SwiftUI

struct CompleteView: View {
    let earned: VocabItem
    let onDone: () -> Void

    @Environment(AppState.self) private var appState
    @State private var starAppeared = [false, false, false]

    var body: some View {
        ZStack {
            Color.mint.ignoresSafeArea()
            Confetti(count: 30)
            Sparkles(count: 8, animate: true)

            VStack(spacing: 0) {
                Spacer()

                Mascot(state: .celebrating, size: 170)

                Eyebrow(text: "Mission complete", color: .mintDeep)
                    .padding(.top, 16)

                Text("Nice one, \(appState.name)!")
                    .font(.display(28, weight: .heavy))
                    .foregroundStyle(Color.ink)
                    .padding(.top, 8)

                // Stars
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.quackYellow)
                            .frame(width: 52, height: 52)
                            .overlay(
                                QuackIcon(name: .star, size: 28, color: .white)
                            )
                            .cardShadow()
                            .scaleEffect(starAppeared[i] ? 1 : 0.05)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.45)
                                    .delay(0.3 + Double(i) * 0.15),
                                value: starAppeared[i]
                            )
                    }
                }
                .padding(.top, 24)

                // Sticker reveal
                StickerTile(item: earned, size: .lg, justEarned: true)
                    .frame(width: 140)
                    .padding(.top, 28)

                Spacer()

                CTAButton(label: "Back home", variant: .ink, action: onDone)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.15) {
                    starAppeared[i] = true
                }
            }
        }
    }
}

#Preview {
    CompleteView(earned: VOCAB[0], onDone: {})
        .environment(AppState())
}
```

- [ ] **Step 5.2: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5.3: Commit**

```bash
git add quack/CompleteView.swift
git commit -m "feat: add CompleteView with confetti, staggered stars, and sticker pop-in"
```

---

## Task 6: MissionsHubView

**Files:**
- Create: `quack/MissionsHubView.swift`

- [ ] **Step 6.1: Create `MissionsHubView.swift`**

```swift
import SwiftUI

struct MissionsHubView: View {
    var onStartMission: (MissionType, VocabItem) -> Void
    @Binding var activeTab: TabItem
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    private var todayWord: VocabItem {
        VOCAB.first { $0.id == appState.todayMission.target } ?? VOCAB[0]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "Daily Briefing", flank: false, size: 11)
                        Text("Choose your mission")
                            .font(.display(28, weight: .heavy))
                            .foregroundStyle(Color.ink)
                        Text("Train across all 4 styles")
                            .font(.bodyText(14))
                            .foregroundStyle(Color.inkMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        ForEach(MissionType.allCases.indices, id: \.self) { i in
                            let type = MissionType.allCases[i]
                            HubMissionCard(type: type, word: todayWord) {
                                onStartMission(type, todayWord)
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)
                            .animation(
                                .easeOut(duration: 0.32).delay(Double(i) * 0.08),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer().frame(height: 120)
                }
            }
            .background(Color.cream)

            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear { appeared = true }
    }
}

private struct HubMissionCard: View {
    let type: MissionType
    let word: VocabItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(type.tone.bg)
                    .grain()

                Sparkles(count: 4, opacity: 0.35)

                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 56, height: 56)
                        .overlay(
                            QuackIcon(name: type.icon, size: 28, color: type.tone.fg, strokeWidth: 2)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.title)
                            .font(.display(18, weight: .heavy))
                            .foregroundStyle(type.tone.fg)
                        Text(type.subtitle)
                            .font(.bodyText(13))
                            .foregroundStyle(type.tone.fg.opacity(0.85))

                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { _ in
                                QuackIcon(name: .star, size: 14, color: type.tone.fg.opacity(0.55))
                            }
                        }
                        .padding(.top, 2)
                    }

                    Spacer()

                    QuackIcon(name: .chevron, size: 20, color: type.tone.fg.opacity(0.65), strokeWidth: 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
            .popShadow()
        }
        .buttonStyle(TapPress())
    }
}

#Preview {
    @Previewable @State var tab = TabItem.missions
    MissionsHubView(onStartMission: { _, _ in }, activeTab: $tab)
        .environment(AppState())
}
```

- [ ] **Step 6.2: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 6.3: Commit**

```bash
git add quack/MissionsHubView.swift
git commit -m "feat: add MissionsHubView with staggered 4 mission cards"
```

---

## Task 7: CameraMissionView

**Files:**
- Create: `quack/CameraMissionView.swift`

- [ ] **Step 7.1: Create `CameraMissionView.swift`**

Three phases: `scan` → `word` → `listen`.

```swift
import SwiftUI

struct CameraMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase: CameraPhase = .scan
    @State private var scanProgress: CGFloat = 0
    @State private var showDetection = false
    @State private var waveAnimating = false

    enum CameraPhase { case scan, word, listen }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Scan it", onBack: { dismiss() })

                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Camera mission", flank: false, size: 11)
                    Text("Find the \(vocab.en.lowercased())")
                        .font(.display(24, weight: .heavy))
                        .foregroundStyle(Color.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                switch phase {
                case .scan:  scanPhaseView
                case .word:  wordPhaseView
                case .listen: listenPhaseView
                }

                Spacer()

                if phase != .listen {
                    CTAButton(
                        label: phase == .scan ? "I found it!" : "Got it",
                        variant: .ink,
                        disabled: phase == .scan && !showDetection,
                        action: advancePhase
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private func advancePhase() {
        withAnimation(.easeOut(duration: 0.3)) {
            switch phase {
            case .scan:   phase = .word
            case .word:   phase = .listen
            case .listen: break
            }
        }
    }

    // MARK: Scan phase
    private var scanPhaseView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.ink)
                .grain(opacity: 0.12)

            // Sweeping scan line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.quackOrange.opacity(0), .quackOrange, .quackOrange.opacity(0)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: scanProgress * 100 - 50)

            // Corner brackets
            CameraCornerBrackets()

            if showDetection {
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Text(vocab.hanzi)
                                .font(.display(14, weight: .heavy))
                                .foregroundStyle(Color.ink)
                            Text(vocab.pinyin)
                                .font(.bodyText(11))
                                .foregroundStyle(Color.inkMuted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .cardShadow()
                        Spacer()
                    }
                    .padding(14)
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .topLeading)))

                ObjectArt(vocab: vocab, size: 90)
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: true)) {
                scanProgress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) { showDetection = true }
            }
        }
    }

    // MARK: Word phase
    private var wordPhaseView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.paper)
                .cardShadow()

            VStack(spacing: 12) {
                Mascot(state: .speaking, size: 80)

                Text(vocab.hanzi)
                    .font(.display(48, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text(vocab.pinyin)
                    .font(.bodyText(16, weight: .bold))
                    .foregroundStyle(Color.inkMuted)

                Button {} label: {
                    HStack(spacing: 8) {
                        QuackIcon(name: .speaker, size: 20, color: .white)
                        Text("Hear it")
                            .font(.bodyText(13, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.ink)
                    .clipShape(Capsule())
                }
                .buttonStyle(TapPress())
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: Listen phase
    private var listenPhaseView: some View {
        VStack(spacing: 28) {
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    WaveBar(index: i, animating: waveAnimating)
                }
            }
            .frame(height: 60)

            Button { onComplete(vocab.id) } label: {
                Circle()
                    .fill(Color.quackOrange)
                    .frame(width: 80, height: 80)
                    .overlay(QuackIcon(name: .mic, size: 36, color: .white, strokeWidth: 2.2))
                    .popShadow()
            }
            .buttonStyle(TapPress())

            Text("Tap mic when done")
                .font(.bodyText(13, weight: .bold))
                .foregroundStyle(Color.inkMuted)
        }
        .padding(.top, 48)
        .onAppear { waveAnimating = true }
    }
}

// MARK: - Camera corner brackets
private struct CameraCornerBrackets: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let br: CGFloat = 24
                let lw: CGFloat = 3
                let pad: CGFloat = 16
                let corners: [(CGPoint, CGFloat, CGFloat)] = [
                    (CGPoint(x: pad, y: pad),                         1,  1),
                    (CGPoint(x: size.width - pad, y: pad),           -1,  1),
                    (CGPoint(x: pad, y: size.height - pad),           1, -1),
                    (CGPoint(x: size.width - pad, y: size.height - pad), -1, -1),
                ]
                for (origin, dx, dy) in corners {
                    var p = Path()
                    p.move(to: CGPoint(x: origin.x + dx * br, y: origin.y))
                    p.addLine(to: origin)
                    p.addLine(to: CGPoint(x: origin.x, y: origin.y + dy * br))
                    ctx.stroke(p, with: .color(.quackOrange),
                               style: StrokeStyle(lineWidth: lw, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    CameraMissionView(vocab: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
```

- [ ] **Step 7.2: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 7.3: Commit**

```bash
git add quack/CameraMissionView.swift
git commit -m "feat: add CameraMissionView with scan/word/listen phases"
```

---

## Task 8: SpeakMissionView

**Files:**
- Create: `quack/SpeakMissionView.swift`

- [ ] **Step 8.1: Create `SpeakMissionView.swift`**

Three-word series. Picks the primary vocab + 2 more from same category (or from VOCAB if fewer than 2 in category).

```swift
import SwiftUI

struct SpeakMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var wordIndex = 0
    @State private var phase: SpeakPhase = .idle
    @State private var score = 0
    @State private var waveAnimating = false

    enum SpeakPhase { case idle, recording, scoring, result }

    private var words: [VocabItem] {
        var result = [vocab]
        let rest = VOCAB.filter { $0.cat == vocab.cat && $0.id != vocab.id }
        result += rest.prefix(2)
        if result.count < 3 {
            result += VOCAB.filter { $0.id != vocab.id && !result.contains($0) }.prefix(3 - result.count)
        }
        return Array(result.prefix(3))
    }

    private var current: VocabItem { words[min(wordIndex, words.count - 1)] }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Say it", accent: .cobalt, onBack: { dismiss() })

                // Word hero card
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(current.tone.bg)
                        .grain()
                        .popShadow()

                    VStack(spacing: 8) {
                        ObjectArt(vocab: current, size: 80)
                        Text(current.hanzi)
                            .font(.display(48, weight: .heavy))
                            .foregroundStyle(current.tone.fg)
                        Text(current.pinyin)
                            .font(.bodyText(16, weight: .bold))
                            .foregroundStyle(current.tone.fg.opacity(0.85))
                        Text(current.en)
                            .font(.bodyText(13))
                            .foregroundStyle(current.tone.fg.opacity(0.7))
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Mic card
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.paper)
                        .cardShadow()

                    micCardContent
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

                if phase == .result {
                    HStack(spacing: 12) {
                        if score < 70 {
                            CTAButton(label: "Retry", variant: .ghost, action: retryWord)
                        }
                        CTAButton(
                            label: wordIndex < words.count - 1 ? "Next" : "Finish",
                            variant: .ink,
                            action: nextWord
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .transition(.opacity.combined(with: .offset(y: 12)))
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: phase)
        .onAppear { waveAnimating = true }
    }

    @ViewBuilder
    private var micCardContent: some View {
        switch phase {
        case .idle:
            VStack(spacing: 12) {
                Text("Say it aloud")
                    .font(.bodyText(14, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
                Button { startRecording() } label: {
                    Circle()
                        .fill(Color.cobalt)
                        .frame(width: 64, height: 64)
                        .overlay(QuackIcon(name: .mic, size: 28, color: .white, strokeWidth: 2.2))
                        .popShadow()
                }
                .buttonStyle(TapPress())
            }
            .padding(20)

        case .recording:
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { i in
                        WaveBar(index: i, animating: waveAnimating, color: .cobalt)
                    }
                }
                .frame(height: 50)
                Pill(text: "Q is listening", color: .cobalt, pulseDot: true)
            }
            .padding(20)

        case .scoring:
            VStack(spacing: 8) {
                ProgressView().tint(Color.cobalt)
                Text("Checking...")
                    .font(.bodyText(13))
                    .foregroundStyle(Color.inkMuted)
            }
            .padding(20)

        case .result:
            VStack(spacing: 6) {
                Text("\(score)%")
                    .font(.display(36, weight: .heavy))
                    .foregroundStyle(score >= 70 ? Color.mintDeep : Color.quackOrange)
                Text(score >= 70 ? "Great job!" : "Nice try!")
                    .font(.bodyText(14, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
            }
            .padding(20)
        }
    }

    private func startRecording() {
        phase = .recording
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            phase = .scoring
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                score = Int.random(in: 72...97)
                withAnimation { phase = .result }
            }
        }
    }

    private func retryWord() {
        phase = .idle
        score = 0
    }

    private func nextWord() {
        if wordIndex < words.count - 1 {
            wordIndex += 1
            phase = .idle
            score = 0
        } else {
            onComplete(current.id)
        }
    }
}

#Preview {
    SpeakMissionView(vocab: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
```

- [ ] **Step 8.2: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 8.3: Commit**

```bash
git add quack/SpeakMissionView.swift
git commit -m "feat: add SpeakMissionView with 3-word series and simulated scoring"
```

---

## Task 9: MatchMissionView

**Files:**
- Create: `quack/MatchMissionView.swift`

- [ ] **Step 9.1: Create `MatchMissionView.swift`**

Three rounds. Each round: show hanzi prompt → 2×2 ObjectArt grid → tap to reveal.

```swift
import SwiftUI

private struct MatchRound {
    let target: VocabItem
    let choices: [VocabItem]   // always 4, target is one of them
}

struct MatchMissionView: View {
    let target: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var roundIndex = 0
    @State private var selected: String? = nil
    @State private var revealed = false

    private let rounds: [MatchRound]

    init(target: VocabItem, onComplete: @escaping (String) -> Void) {
        self.target = target
        self.onComplete = onComplete

        var pool = VOCAB.filter { $0.id != target.id }.shuffled()
        func nextThree() -> [VocabItem] {
            if pool.count < 3 { pool = VOCAB.filter { $0.id != target.id }.shuffled() }
            let r = Array(pool.prefix(3))
            pool = Array(pool.dropFirst(3))
            return r
        }

        // 3 round targets: primary + 2 others
        let others = Array(pool.prefix(2))
        pool = Array(pool.dropFirst(2))

        var built: [MatchRound] = []
        for t in ([target] + others) {
            let distractors = nextThree()
            built.append(MatchRound(target: t, choices: ([t] + distractors).shuffled()))
        }
        self.rounds = built
    }

    private var round: MatchRound { rounds[min(roundIndex, rounds.count - 1)] }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Match it", accent: .rose, onBack: { dismiss() })

                // Prompt card
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.ink)
                        .grain(opacity: 0.1)

                    VStack(spacing: 4) {
                        Text(round.target.hanzi)
                            .font(.display(56, weight: .heavy))
                            .foregroundStyle(.white)
                        Text(revealed ? round.target.pinyin : "Match the character")
                            .font(.bodyText(15, weight: .bold))
                            .foregroundStyle(.white.opacity(0.65))
                            .animation(.easeOut, value: revealed)
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, minHeight: 130)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // 2×2 grid
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(round.choices) { choice in
                        MatchChoiceCell(
                            vocab: choice,
                            isTarget: choice.id == round.target.id,
                            isSelected: selected == choice.id,
                            revealed: revealed
                        ) {
                            guard !revealed else { return }
                            selected = choice.id
                            withAnimation(.easeOut(duration: 0.3)) { revealed = true }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)

                Spacer()

                if revealed {
                    CTAButton(
                        label: roundIndex < rounds.count - 1 ? "Next" : "Finish",
                        variant: .ink,
                        action: {
                            if roundIndex < rounds.count - 1 {
                                roundIndex += 1
                                selected = nil
                                withAnimation { revealed = false }
                            } else {
                                onComplete(target.id)
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .transition(.opacity.combined(with: .offset(y: 12)))
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: revealed)
    }
}

private struct MatchChoiceCell: View {
    let vocab: VocabItem
    let isTarget: Bool
    let isSelected: Bool
    let revealed: Bool
    let onTap: () -> Void

    private var borderColor: Color {
        guard revealed && isSelected else { return .clear }
        return isTarget ? .mintDeep : .quackOrange
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(vocab.tone.bg.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 3)
                    )

                VStack(spacing: 8) {
                    ObjectArt(vocab: vocab, size: 72)
                    Text(vocab.en)
                        .font(.bodyText(12, weight: .bold))
                        .foregroundStyle(Color.ink)
                }
                .padding(14)
                .frame(maxWidth: .infinity)

                if revealed && isSelected {
                    Circle()
                        .fill(isTarget ? Color.mintDeep : Color.quackOrange)
                        .frame(width: 26, height: 26)
                        .overlay(
                            QuackIcon(
                                name: isTarget ? .check : .close,
                                size: 14, color: .white, strokeWidth: 2
                            )
                        )
                        .padding(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(TapPress())
        .disabled(revealed)
    }
}

#Preview {
    MatchMissionView(target: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
```

- [ ] **Step 9.2: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 9.3: Commit**

```bash
git add quack/MatchMissionView.swift
git commit -m "feat: add MatchMissionView with 3-round character matching"
```

---

## Task 10: StoryMissionView

**Files:**
- Create: `quack/StoryMissionView.swift`

- [ ] **Step 10.1: Create `StoryMissionView.swift`**

Three reading pages, then a 3-choice quiz.

```swift
import SwiftUI

private struct StoryPage {
    let vocab: VocabItem
    let text: String
}

struct StoryMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase: StoryPhase = .reading(page: 0)
    @State private var quizSelected: String? = nil
    @State private var quizRevealed = false

    enum StoryPhase: Equatable {
        case reading(page: Int)
        case quiz
    }

    private var pages: [StoryPage] {
        let related = VOCAB.filter { $0.cat == vocab.cat && $0.id != vocab.id }
        var items = [vocab] + related.prefix(2)
        if items.count < 3 {
            items += VOCAB.filter { !items.contains($0) }.prefix(3 - items.count)
        }
        return [
            StoryPage(vocab: items[0], text: "Q found a \(items[0].en.lowercased())! In Mandarin, it's '\(items[0].hanzi)' — say \(items[0].pinyin)."),
            StoryPage(vocab: items[1], text: "Look — a \(items[1].en.lowercased())! '\(items[1].hanzi)' (\(items[1].pinyin)). Can you say it?"),
            StoryPage(vocab: items[min(2, items.count-1)], text: "Amazing work! You're becoming a Mandarin agent. Remember '\(vocab.hanzi)' (\(vocab.pinyin)) — \(vocab.en.lowercased())."),
        ]
    }

    private var quizChoices: [VocabItem] {
        var pool = VOCAB.filter { $0.id != vocab.id }.shuffled()
        return ([vocab] + pool.prefix(2)).shuffled()
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Story time", accent: .mint, onBack: { dismiss() })

                switch phase {
                case .reading(let page): readingView(page: page)
                case .quiz:              quizView
                }

                Spacer()

                ctaButton
            }
        }
        .animation(.easeOut(duration: 0.3), value: phase)
    }

    // MARK: Reading
    private func readingView(page: Int) -> some View {
        let storyPage = pages[min(page, pages.count - 1)]
        return VStack(spacing: 12) {
            // Progress bars
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= page ? Color.mint : Color.inkFaint)
                        .frame(height: 4)
                        .animation(.easeOut(duration: 0.3), value: page)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            // Story card
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(storyPage.vocab.tone.bg)
                    .grain()
                    .popShadow()

                Sparkles(count: 4, opacity: 0.4)

                VStack(spacing: 16) {
                    ObjectArt(vocab: storyPage.vocab, size: 100)
                    Text(storyPage.vocab.hanzi)
                        .font(.display(36, weight: .heavy))
                        .foregroundStyle(storyPage.vocab.tone.fg)
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding(.horizontal, 24)

            // Narration card
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.paper)
                    .cardShadow()

                HStack(spacing: 12) {
                    Mascot(state: .speaking, size: 48)
                    Text(storyPage.text)
                        .font(.bodyText(14))
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button {} label: {
                        QuackIcon(name: .speaker, size: 22, color: .quackOrange, strokeWidth: 2)
                    }
                    .buttonStyle(TapPress())
                }
                .padding(14)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Quiz
    @State private var quizChoicesCache: [VocabItem]? = nil

    private var quizView: some View {
        let choices = quizChoicesCache ?? quizChoices
        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: "Quick quiz", flank: false, size: 11)
                Text("Which one is '\(vocab.hanzi)'?")
                    .font(.display(22, weight: .heavy))
                    .foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)

            VStack(spacing: 10) {
                ForEach(choices) { choice in
                    Button {
                        guard !quizRevealed else { return }
                        quizSelected = choice.id
                        withAnimation(.easeOut(duration: 0.3)) { quizRevealed = true }
                    } label: {
                        HStack(spacing: 14) {
                            ObjectArt(vocab: choice, size: 52)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(choice.en)
                                    .font(.display(16, weight: .heavy))
                                    .foregroundStyle(Color.ink)
                                Text(choice.pinyin)
                                    .font(.bodyText(12))
                                    .foregroundStyle(Color.inkMuted)
                            }
                            Spacer()
                            if quizRevealed && quizSelected == choice.id {
                                Circle()
                                    .fill(choice.id == vocab.id ? Color.mintDeep : Color.quackOrange)
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        QuackIcon(
                                            name: choice.id == vocab.id ? .check : .close,
                                            size: 14, color: .white, strokeWidth: 2
                                        )
                                    )
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(quizRevealed && quizSelected == choice.id
                                      ? (choice.id == vocab.id ? Color.mint.opacity(0.3) : Color.rose.opacity(0.3))
                                      : Color.paper)
                        )
                        .cardShadow()
                    }
                    .buttonStyle(TapPress())
                    .disabled(quizRevealed)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            if quizChoicesCache == nil { quizChoicesCache = quizChoices }
        }
    }

    // MARK: CTA
    @ViewBuilder
    private var ctaButton: some View {
        switch phase {
        case .reading(let page):
            CTAButton(
                label: page < pages.count - 1 ? "Next page" : "Take the quiz",
                variant: page < pages.count - 1 ? .ghost : .orange,
                action: {
                    if page < pages.count - 1 {
                        withAnimation { phase = .reading(page: page + 1) }
                    } else {
                        withAnimation { phase = .quiz }
                    }
                }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 32)

        case .quiz:
            if quizRevealed {
                CTAButton(label: "Finish", variant: .ink, action: { onComplete(vocab.id) })
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .transition(.opacity.combined(with: .offset(y: 12)))
            }
        }
    }
}

#Preview {
    StoryMissionView(vocab: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
```

- [ ] **Step 10.2: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 10.3: Commit**

```bash
git add quack/StoryMissionView.swift
git commit -m "feat: add StoryMissionView with 3-page reading and character quiz"
```

---

## Task 11: MainTabView + HomeView Wiring

**Files:**
- Modify: `quack/MainTabView.swift`
- Modify: `quack/HomeView.swift`

- [ ] **Step 11.1: Replace `MainTabView.swift`**

Replace the entire file:

```swift
import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var activeTab: TabItem = .home
    @State private var activeMission: ActiveMission? = nil
    @State private var showComplete = false
    @State private var earnedVocabId: String? = nil

    struct ActiveMission: Identifiable {
        let id = UUID()
        let type: MissionType
        let vocab: VocabItem
    }

    var body: some View {
        ZStack {
            switch activeTab {
            case .home:
                NavigationStack {
                    HomeView(onMission: launchMission, activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)

            case .missions:
                NavigationStack {
                    MissionsHubView(onStartMission: launchMission, activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)

            case .library:
                NavigationStack {
                    LibraryPlaceholder(activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)

            case .parent:
                NavigationStack {
                    ParentPlaceholder(activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)
            }
        }
        .animation(.easeOut(duration: 0.22), value: activeTab)
        .fullScreenCover(item: $activeMission) { mission in
            missionView(for: mission)
                .environment(appState)
        }
        .fullScreenCover(isPresented: $showComplete) {
            if let id = earnedVocabId, let earned = VOCAB.first(where: { $0.id == id }) {
                CompleteView(earned: earned, onDone: { showComplete = false })
                    .environment(appState)
            }
        }
    }

    private func launchMission(_ type: MissionType, _ vocab: VocabItem) {
        activeMission = ActiveMission(type: type, vocab: vocab)
    }

    private func missionComplete(_ vocabId: String) {
        appState.addLearned(vocabId)
        earnedVocabId = vocabId
        activeMission = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showComplete = true
        }
    }

    @ViewBuilder
    private func missionView(for mission: ActiveMission) -> some View {
        switch mission.type {
        case .camera:
            CameraMissionView(vocab: mission.vocab, onComplete: missionComplete)
        case .speak:
            SpeakMissionView(vocab: mission.vocab, onComplete: missionComplete)
        case .match:
            MatchMissionView(target: mission.vocab, onComplete: missionComplete)
        case .story:
            StoryMissionView(vocab: mission.vocab, onComplete: missionComplete)
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Phase 3 placeholders
struct LibraryPlaceholder: View {
    @Binding var activeTab: TabItem
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                Text("Sticker Book").font(.display(24))
                Text("Coming in Phase 3").font(.bodyText(14)).foregroundStyle(Color.inkMuted)
                Spacer()
            }
            .background(Color.cream)
            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct ParentPlaceholder: View {
    @Binding var activeTab: TabItem
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                Text("Parent Dashboard").font(.display(24))
                Text("Coming in Phase 3").font(.bodyText(14)).foregroundStyle(Color.inkMuted)
                Spacer()
            }
            .background(Color.cream)
            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
```

- [ ] **Step 11.2: Update `HomeView.swift` — change `onMission` callback signature**

Change line 5 (`var onMission: (String) -> Void`) to:

```swift
    var onMission: (MissionType, VocabItem) -> Void
```

Change `missionHeroCard` button action (line 102) from `onMission("camera")` to:

```swift
Button { if let word = todayWord { onMission(.camera, word) } } label: {
```

Change `trainingGrid` `types` array (lines 243–248) and its usage. Replace the entire `trainingGrid` computed property with:

```swift
    private var trainingGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick your training")
                .font(.display(18, weight: .heavy))
                .foregroundStyle(Color.ink)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(MissionType.allCases) { type in
                    Button {
                        let word = todayWord ?? VOCAB[0]
                        onMission(type, word)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            QuackIcon(name: type.icon, size: 22, color: type.tone.fg, strokeWidth: 2)
                            Spacer()
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.title)
                                    .font(.display(16, weight: .heavy))
                                    .foregroundStyle(type.tone.fg)
                                Text(type.subtitle)
                                    .font(.bodyText(11, weight: .bold))
                                    .foregroundStyle(type.tone.fg.opacity(0.8))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 110)
                        .quackCard(tone: type.tone)
                    }
                    .buttonStyle(TapPress())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
```

Change the `#Preview` at the bottom to:

```swift
#Preview("HomeView") {
    @Previewable @State var tab = TabItem.home
    let state = AppState()
    state.streak = 4
    state.dailyProgress = 1
    return HomeView(onMission: { _, _ in }, activeTab: $tab)
        .environment(state)
}
```

- [ ] **Step 11.3: Build to verify**

```bash
cd /Users/mit/Documents/Projects/quack && xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -E 'error:|BUILD'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 11.4: Commit**

```bash
git add quack/MainTabView.swift quack/HomeView.swift
git commit -m "feat: wire Phase 2 missions into MainTabView, update HomeView onMission signature"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] LaunchSplashView — Task 1 (cold-start, auto-dismiss 1.8s, orange bg, mascot, wordmark)
- [x] AgeView arc/fan picker — Task 2 (U-shape, 6 o'clock selected, drag gesture, spring snap)
- [x] DEBUG override `hasOnboarded = false` — Task 1 AppView
- [x] ObjectArt — Task 3 (emoji + toned circles fallback)
- [x] MissionType enum + MissionHeader — Task 4
- [x] CompleteView — Task 5 (mint bg, confetti, staggered stars, sticker pop-in)
- [x] MissionsHubView — Task 6 (4 staggered mission cards, TabBar)
- [x] CameraMissionView — Task 7 (scan/word/listen phases, corner brackets, scan line)
- [x] SpeakMissionView — Task 8 (3-word series, simulated scoring)
- [x] MatchMissionView — Task 9 (3 rounds, 2×2 grid, reveal)
- [x] StoryMissionView — Task 10 (3 pages, quiz)
- [x] MainTabView + HomeView wiring — Task 11

**Type consistency:**
- `onMission: (MissionType, VocabItem) -> Void` — consistent in HomeView, MissionsHubView, MainTabView
- `onComplete: (String) -> Void` — consistent in all mission views and MainTabView.missionComplete
- `WaveBar(index:animating:color:)` — used identically in CameraMissionView and SpeakMissionView
- `StickerTile(item:size:justEarned:)` — correct parameter order per existing Components.swift
- `ActiveMission` struct — defined in MainTabView, not leaked to other files
