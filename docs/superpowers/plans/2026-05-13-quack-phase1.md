# Quack Phase 1 — Foundation & Core Screens

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing Quack SwiftUI app with a clean rewrite matching the `quack_example` reference — new design system, onboarding flow (4 screens), home screen, and 4-tab navigation.

**Architecture:** `quackApp.swift` owns an `@Observable AppState` instance and injects it via `.environment`. `AppView` gates onboarding vs. `MainTabView` using `@AppStorage("hasOnboarded")`. All screens share design tokens from `Theme.swift` and primitives from `Components.swift`.

**Tech Stack:** SwiftUI, Swift 5.9+, iOS 17+ (`@Observable`), `Canvas`, `TimelineView`, `DragGesture`, `@AppStorage`, `UserDefaults`.

**Minimum deployment target:** iOS 17.0 — required for `@Observable` macro.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `quack/quackApp.swift` | Modify | Own AppState, inject environment, point to AppView |
| `quack/Theme.swift` | Rewrite | Color tokens, Tone enum, font helpers, shadow/radius tokens, TapPress, QuackCard, GrainOverlay |
| `quack/Models.swift` | Rewrite | VocabItem, Category structs, VOCAB + CATEGORIES constants, AppState |
| `quack/Components.swift` | New | All 14 shared view primitives |
| `quack/Mascot.swift` | New | Mascot view with 4 animation states |
| `quack/AppView.swift` | New | Onboarding gate |
| `quack/OnboardingFlow.swift` | New | SplashView, NameView, AgeView, IntroView |
| `quack/HomeView.swift` | Rewrite | Full home screen |
| `quack/MainTabView.swift` | New | 4-tab container with placeholder tab screens |
| `quackTests/AppStateTests.swift` | New | Unit tests for AppState logic |

**Delete before starting:**
- `quack/ContentView.swift`
- `quack/WelcomeView.swift`
- `quack/LessonView.swift`
- `quack/CelebrationView.swift`
- `quack/DuckView.swift`

---

## Task 1: Delete old files

**Files:** Delete 5 Swift files listed above.

- [ ] **Step 1: Delete old screen files**

```bash
cd /Users/mit/Documents/Projects/quack
rm quack/ContentView.swift quack/WelcomeView.swift quack/LessonView.swift quack/CelebrationView.swift quack/DuckView.swift
```

- [ ] **Step 2: Remove deleted files from Xcode project**

Open `quack.xcodeproj` in Xcode. In the Project Navigator, the deleted files will show in red. Select all 5 red entries, right-click → "Delete" → "Remove Reference". Build (`Cmd+B`) — expect errors about missing types. That's fine; the next tasks fix them.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: delete old screens before clean rewrite"
```

---

## Task 2: Theme.swift — complete design system

**Files:**
- Rewrite: `quack/Theme.swift`

- [ ] **Step 1: Rewrite Theme.swift**

```swift
import SwiftUI

// MARK: - Color tokens
extension Color {
    static let quackOrange     = Color(hex: 0xF86A38)
    static let quackOrangeDeep = Color(hex: 0xE54E1B)
    static let quackOrangeSoft = Color(hex: 0xFFB7A0)
    static let quackYellow     = Color(hex: 0xFCC83C)
    static let cream           = Color(hex: 0xFFF1E1)
    static let creamDeep       = Color(hex: 0xFBE6CB)
    static let paper           = Color.white
    static let ink             = Color(hex: 0x14213D)
    static let inkSoft         = Color(hex: 0x2A3556)
    static let inkMuted        = Color(hex: 0x9098AE)
    static let inkFaint        = Color(hex: 0xD7DAE3)
    static let cobalt          = Color(hex: 0x4F5DDB)
    static let cobaltDeep      = Color(hex: 0x2F3CB8)
    static let mint            = Color(hex: 0x93D5B8)
    static let mintDeep        = Color(hex: 0x5FB594)
    static let rose            = Color(hex: 0xFF8FA3)
    static let lilac           = Color(hex: 0xC9C5F2)

    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255
        )
    }
}

// MARK: - Tone
enum Tone: String, CaseIterable {
    case orange, yellow, cobalt, mint, rose, lilac, cream

    var bg: Color {
        switch self {
        case .orange: return .quackOrange
        case .yellow: return .quackYellow
        case .cobalt: return .cobalt
        case .mint:   return .mint
        case .rose:   return .rose
        case .lilac:  return .lilac
        case .cream:  return .creamDeep
        }
    }

    var fg: Color {
        switch self {
        case .orange, .cobalt: return .white
        default: return .ink
        }
    }
}

// MARK: - Font helpers
extension Font {
    // Display / headings — SF Rounded
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    // Body / captions — SF Pro
    static func body(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }
    // Eyebrow — small caps rounded
    static var eyebrow: Font { .system(size: 11, weight: .heavy, design: .rounded) }
}

// MARK: - Shadow helpers
extension View {
    func cardShadow() -> some View {
        self.shadow(color: .ink.opacity(0.08), radius: 6, x: 0, y: 2)
    }
    func popShadow() -> some View {
        self.shadow(color: .ink.opacity(0.16), radius: 12, x: 0, y: 4)
    }
}

// MARK: - QuackCard modifier
struct QuackCardModifier: ViewModifier {
    var fill: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .cardShadow()
    }
}

extension View {
    func quackCard(fill: Color = .paper, radius: CGFloat = 22) -> some View {
        modifier(QuackCardModifier(fill: fill, radius: radius))
    }
    func quackCard(tone: Tone, radius: CGFloat = 22) -> some View {
        modifier(QuackCardModifier(fill: tone.bg, radius: radius))
    }
}

// MARK: - GrainOverlay
struct GrainOverlay: View {
    var opacity: Double = 0.07

    var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / 4)
            let rows = Int(size.height / 4)
            for row in 0..<rows {
                for col in 0..<cols {
                    let hash = (UInt32(row) &* 2_654_435_761 &+ UInt32(col) &* 40_503) & 0xFF
                    if hash < 18 {
                        let x = CGFloat(col) * 4 + CGFloat(hash % 4)
                        let y = CGFloat(row) * 4 + CGFloat((hash / 4) % 4)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                            with: .color(.white.opacity(opacity))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func grain(opacity: Double = 0.07) -> some View {
        self.overlay(GrainOverlay(opacity: opacity))
    }
}

// MARK: - TapPress button style
struct TapPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Screen-in transition helper
extension AnyTransition {
    static var screenIn: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 8)),
            removal: .opacity
        )
    }
}
```

- [ ] **Step 2: Verify build**

In Xcode, `Cmd+B`. Expect build errors in other files (they reference old color names). Those get fixed in later tasks.

- [ ] **Step 3: Commit**

```bash
git add quack/Theme.swift
git commit -m "feat: add Quack design system tokens — colors, Tone, fonts, shadows, grain"
```

---

## Task 3: Models.swift — data + AppState

**Files:**
- Rewrite: `quack/Models.swift`
- Create: `quackTests/AppStateTests.swift`

- [ ] **Step 1: Write AppStateTests.swift first (TDD)**

```swift
import Testing
@testable import quack

@Suite("AppState")
struct AppStateTests {
    @Test func addLearnedDeduplicates() {
        let s = AppState()
        s.addLearned("apple")
        s.addLearned("apple")
        #expect(s.learned.count == 1)
    }

    @Test func addLearnedIncrementsDailyProgress() {
        let s = AppState()
        let before = s.dailyProgress
        s.addLearned("cat")
        #expect(s.dailyProgress == before + 1)
    }

    @Test func resetProgressClearsLearned() {
        let s = AppState()
        s.addLearned("apple")
        s.resetProgress()
        #expect(s.learned.isEmpty)
        #expect(s.dailyProgress == 0)
        #expect(s.streak == 0)
    }

    @Test func vocabCoversAllCategories() {
        let cats = Set(VOCAB.map(\.cat))
        #expect(cats == Set(CATEGORIES.map(\.id)))
    }

    @Test func vocabCount() {
        #expect(VOCAB.count == 20)
    }

    @Test func todayMissionTargetInVocab() {
        let s = AppState()
        #expect(VOCAB.contains { $0.id == s.todayMission.target })
    }
}
```

- [ ] **Step 2: Run tests — expect compile failure**

In Xcode: `Cmd+U`. Expected: compile errors because `AppState`, `VOCAB`, `CATEGORIES` don't exist yet.

- [ ] **Step 3: Rewrite Models.swift**

```swift
import SwiftUI
import Observation

// MARK: - Vocab
struct VocabItem: Identifiable {
    let id: String
    let hanzi: String
    let pinyin: String
    let en: String
    let cat: String
    let tone: Tone
    let emoji: String
}

struct Category: Identifiable {
    let id: String
    let label: String
    let tone: Tone
}

let VOCAB: [VocabItem] = [
    // Fruits
    VocabItem(id: "apple",   hanzi: "苹果", pinyin: "píngguǒ",   en: "Apple",   cat: "fruits",    tone: .orange, emoji: "🍎"),
    VocabItem(id: "orange",  hanzi: "橘子", pinyin: "júzi",      en: "Orange",  cat: "fruits",    tone: .orange, emoji: "🍊"),
    VocabItem(id: "banana",  hanzi: "香蕉", pinyin: "xiāngjiāo", en: "Banana",  cat: "fruits",    tone: .yellow, emoji: "🍌"),
    VocabItem(id: "grape",   hanzi: "葡萄", pinyin: "pútáo",     en: "Grapes",  cat: "fruits",    tone: .lilac,  emoji: "🍇"),
    // Animals
    VocabItem(id: "cat",     hanzi: "猫",  pinyin: "māo",       en: "Cat",     cat: "animals",   tone: .yellow, emoji: "🐱"),
    VocabItem(id: "dog",     hanzi: "狗",  pinyin: "gǒu",       en: "Dog",     cat: "animals",   tone: .orange, emoji: "🐶"),
    VocabItem(id: "bird",    hanzi: "鸟",  pinyin: "niǎo",      en: "Bird",    cat: "animals",   tone: .cobalt, emoji: "🐦"),
    VocabItem(id: "fish",    hanzi: "鱼",  pinyin: "yú",        en: "Fish",    cat: "animals",   tone: .mint,   emoji: "🐟"),
    // Household
    VocabItem(id: "chair",   hanzi: "椅子", pinyin: "yǐzi",      en: "Chair",   cat: "household", tone: .cobalt, emoji: "🪑"),
    VocabItem(id: "book",    hanzi: "书",  pinyin: "shū",       en: "Book",    cat: "household", tone: .rose,   emoji: "📖"),
    VocabItem(id: "cup",     hanzi: "杯子", pinyin: "bēizi",     en: "Cup",     cat: "household", tone: .lilac,  emoji: "🥤"),
    VocabItem(id: "lamp",    hanzi: "灯",  pinyin: "dēng",      en: "Lamp",    cat: "household", tone: .yellow, emoji: "💡"),
    // Food
    VocabItem(id: "rice",    hanzi: "米饭", pinyin: "mǐfàn",     en: "Rice",    cat: "food",      tone: .cream,  emoji: "🍚"),
    VocabItem(id: "noodle",  hanzi: "面",  pinyin: "miàn",      en: "Noodles", cat: "food",      tone: .yellow, emoji: "🍜"),
    VocabItem(id: "egg",     hanzi: "蛋",  pinyin: "dàn",       en: "Egg",     cat: "food",      tone: .cream,  emoji: "🥚"),
    VocabItem(id: "tea",     hanzi: "茶",  pinyin: "chá",       en: "Tea",     cat: "food",      tone: .mint,   emoji: "🍵"),
    // Family
    VocabItem(id: "mom",     hanzi: "妈妈", pinyin: "māma",      en: "Mom",     cat: "family",    tone: .rose,   emoji: "👩"),
    VocabItem(id: "dad",     hanzi: "爸爸", pinyin: "bàba",      en: "Dad",     cat: "family",    tone: .cobalt, emoji: "👨"),
    VocabItem(id: "brother", hanzi: "哥哥", pinyin: "gēge",      en: "Brother", cat: "family",    tone: .orange, emoji: "🧒"),
    VocabItem(id: "sister",  hanzi: "姐姐", pinyin: "jiějie",    en: "Sister",  cat: "family",    tone: .lilac,  emoji: "👧"),
]

let CATEGORIES: [Category] = [
    Category(id: "fruits",    label: "Fruits",    tone: .orange),
    Category(id: "animals",   label: "Animals",   tone: .yellow),
    Category(id: "household", label: "Household", tone: .cobalt),
    Category(id: "food",      label: "Food",      tone: .mint),
    Category(id: "family",    label: "Family",    tone: .rose),
]

// MARK: - TodayMission
struct TodayMission {
    var id: String
    var title: String
    var target: String

    static func defaultMission() -> TodayMission {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        let month = calendar.component(.month, from: Date())
        let idx = (day + month * 3) % VOCAB.count
        let word = VOCAB[idx]
        return TodayMission(
            id: "today",
            title: "Find the \(word.en.lowercased())",
            target: word.id
        )
    }
}

// MARK: - AppState
@Observable
final class AppState {
    var name: String {
        didSet { UserDefaults.standard.set(name, forKey: "quack.name") }
    }
    var age: Int {
        didSet { UserDefaults.standard.set(age, forKey: "quack.age") }
    }
    var streak: Int {
        didSet { UserDefaults.standard.set(streak, forKey: "quack.streak") }
    }
    var dailyProgress: Int = 0
    var dailyGoal: Int = 3
    var learned: [String] {
        didSet { saveLearned() }
    }
    var todayMission: TodayMission

    init() {
        let ud = UserDefaults.standard
        name          = ud.string(forKey: "quack.name") ?? "Alex"
        age           = ud.integer(forKey: "quack.age").nonZero ?? 8
        streak        = ud.integer(forKey: "quack.streak")
        learned       = (try? JSONDecoder().decode([String].self,
                          from: ud.data(forKey: "quack.learned") ?? Data())) ?? []
        todayMission  = TodayMission.defaultMission()
        dailyProgress = min(learned.count, 99)
    }

    func addLearned(_ id: String) {
        guard !learned.contains(id) else { return }
        learned.append(id)
        dailyProgress = min(dailyProgress + 1, 99)
    }

    func resetProgress() {
        learned = []
        dailyProgress = 0
        streak = 0
    }

    private func saveLearned() {
        let data = (try? JSONEncoder().encode(learned)) ?? Data()
        UserDefaults.standard.set(data, forKey: "quack.learned")
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
```

- [ ] **Step 4: Run tests — expect pass**

`Cmd+U`. All 6 tests should pass.

- [ ] **Step 5: Commit**

```bash
git add quack/Models.swift quackTests/AppStateTests.swift
git commit -m "feat: add VOCAB, CATEGORIES, AppState with UserDefaults persistence"
```

---

## Task 4: Components.swift — text & decorative primitives

**Files:**
- Create: `quack/Components.swift`

- [ ] **Step 1: Create Components.swift with Eyebrow, Sparkles, Pill**

```swift
import SwiftUI

// MARK: - Eyebrow
struct Eyebrow: View {
    let text: String
    var color: Color = .quackOrange
    var flank: Bool = true
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 8) {
            if flank { Text("✦").font(.display(size)) }
            Text(text)
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .tracking(size * 0.14)
                .textCase(.uppercase)
            if flank { Text("✦").font(.display(size)) }
        }
        .foregroundStyle(color)
    }
}

// MARK: - Sparkles
private let sparklePositions: [(top: CGFloat, left: CGFloat, size: CGFloat, rot: Double)] = [
    (0.08, 0.12, 14, 12),  (0.18, 0.78, 22, -18),
    (0.42, 0.06, 16, 30),  (0.60, 0.84, 12,   0),
    (0.74, 0.20, 18, 22),  (0.32, 0.50, 10,  -8),
    (0.88, 0.70, 14, -14), (0.50, 0.30, 12,  14),
]

struct Sparkles: View {
    var count: Int = 6
    var color: Color = .white
    var opacity: Double = 0.7
    var animate: Bool = false

    @State private var floating = false

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<min(count, sparklePositions.count), id: \.self) { i in
                let p = sparklePositions[i]
                Text("✦")
                    .font(.system(size: p.size, weight: .black))
                    .foregroundStyle(color.opacity(opacity))
                    .rotationEffect(.degrees(p.rot))
                    .offset(
                        x: p.left * geo.size.width,
                        y: (floating && animate ? p.top * geo.size.height - 6 : p.top * geo.size.height)
                    )
                    .animation(
                        animate
                            ? .easeInOut(duration: 2.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3)
                            : .default,
                        value: floating
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { floating = animate }
    }
}

// MARK: - Pill
struct Pill: View {
    let text: String
    var color: Color = .quackOrange
    var bg: Color = .white
    var pulseDot: Bool = false

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            if pulseDot {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .opacity(pulse ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }
            }
            Text(text)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(11 * 0.08)
                .textCase(.uppercase)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(bg)
        .clipShape(Capsule())
        .cardShadow()
    }
}
```

- [ ] **Step 2: Add preview to verify**

```swift
#Preview("Eyebrow") {
    VStack(spacing: 16) {
        Eyebrow(text: "Mission begins")
        Eyebrow(text: "Step 1 of 3", flank: false, size: 11)
        Pill(text: "Q is listening", pulseDot: true)
    }
    .padding()
    .background(Color.cream)
}
```

- [ ] **Step 3: Open preview in Xcode, verify renders correctly**

In Xcode: click the preview canvas button. Eyebrow shows ✦ flanks with orange text. Pill shows a pulsing dot.

- [ ] **Step 4: Commit**

```bash
git add quack/Components.swift
git commit -m "feat: add Eyebrow, Sparkles, Pill components"
```

---

## Task 5: Components — buttons & navigation

**Files:**
- Modify: `quack/Components.swift` (append)

- [ ] **Step 1: Append CTAButton and BackBtn to Components.swift**

```swift
// MARK: - CTAButton
enum CTAVariant { case ink, orange, ghost }

struct CTAButton: View {
    let label: String
    var variant: CTAVariant = .ink
    var disabled: Bool = false
    let action: () -> Void

    private var bg: Color {
        switch variant {
        case .ink:    return .ink
        case .orange: return .quackOrange
        case .ghost:  return .clear
        }
    }
    private var fg: Color {
        switch variant {
        case .ink, .orange: return .white
        case .ghost:        return .ink
        }
    }

    var body: some View {
        Button(action: disabled ? {} : action) {
            Text(label)
                .font(.body(16, weight: .heavy))
                .foregroundStyle(fg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(bg)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(variant == .ghost ? Color.inkFaint : .clear, lineWidth: 2)
                )
                .cardShadow()
                .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(TapPress())
        .disabled(disabled)
    }
}

// MARK: - BackBtn
struct BackBtn: View {
    var dark: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(dark ? Color.ink : Color.white)
                .frame(width: 44, height: 44)
                .background(dark ? Color.white : Color.ink)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .cardShadow()
        }
        .buttonStyle(TapPress())
    }
}
```

- [ ] **Step 2: Add preview**

```swift
#Preview("Buttons") {
    VStack(spacing: 12) {
        CTAButton(label: "Let's go", variant: .ink) {}
        CTAButton(label: "Start mission", variant: .orange) {}
        CTAButton(label: "Skip", variant: .ghost) {}
        CTAButton(label: "Disabled", disabled: true) {}
        HStack {
            BackBtn { }
            BackBtn(dark: true) { }
        }
    }
    .padding()
    .background(Color.cream)
}
```

- [ ] **Step 3: Verify preview — ink/orange/ghost variants, back buttons both variants**

- [ ] **Step 4: Commit**

```bash
git add quack/Components.swift
git commit -m "feat: add CTAButton (3 variants) and BackBtn components"
```

---

## Task 6: Components — ProgressBar and DailyRing

**Files:**
- Modify: `quack/Components.swift` (append)

- [ ] **Step 1: Append ProgressBar and DailyRing**

```swift
// MARK: - ProgressBar
struct ProgressBar: View {
    var value: Double
    var max: Double
    var color: Color = .quackOrange
    var trackColor: Color = .inkFaint
    var height: CGFloat = 12

    private var pct: Double { Swift.max(0, Swift.min(1, value / max)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor).frame(height: height)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * pct, height: height)
                    .animation(.easeOut(duration: 0.4), value: pct)
            }
        }
        .frame(height: height)
    }
}

// MARK: - DailyRing
struct DailyRing: View {
    var value: Int
    var max: Int

    private var pct: Double { Double(value) / Double(Swift.max(1, max)) }
    private let r: CGFloat = 24
    private let strokeWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let circumference = 2 * Double.pi * r
                let startAngle = Angle.degrees(-90)

                // Track
                var trackPath = Path()
                trackPath.addArc(center: center, radius: r,
                                 startAngle: .degrees(0), endAngle: .degrees(360),
                                 clockwise: false)
                ctx.stroke(trackPath,
                           with: .color(.inkFaint),
                           style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

                // Progress
                let endDegrees = -90 + 360 * pct
                var progressPath = Path()
                progressPath.addArc(center: center, radius: r,
                                    startAngle: startAngle,
                                    endAngle: .degrees(endDegrees),
                                    clockwise: false)
                ctx.stroke(progressPath,
                           with: .color(.quackOrange),
                           style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            }
            .frame(width: 64, height: 64)
            .animation(.easeOut(duration: 0.4), value: pct)

            Text("\(value)")
                .font(.display(20, weight: .heavy))
                .foregroundStyle(Color.ink)
        }
        .frame(width: 64, height: 64)
    }
}
```

- [ ] **Step 2: Add preview**

```swift
#Preview("Progress") {
    VStack(spacing: 24) {
        ProgressBar(value: 0.6, max: 1.0, height: 12)
        ProgressBar(value: 2, max: 5, color: .cobalt, height: 8)
        DailyRing(value: 2, max: 3)
        DailyRing(value: 3, max: 3)
    }
    .padding()
    .background(Color.cream)
}
```

- [ ] **Step 3: Verify preview — ring arc renders at correct angle, progress bar fills proportionally**

- [ ] **Step 4: Commit**

```bash
git add quack/Components.swift
git commit -m "feat: add ProgressBar and DailyRing components"
```

---

## Task 7: Components — TabBar and QuackIcon

**Files:**
- Modify: `quack/Components.swift` (append)

- [ ] **Step 1: Append QuackIcon and TabBar**

```swift
// MARK: - QuackIcon
enum QuackIconName {
    case home, mission, book, parent
    case back, close, mic, camera, speaker, star, fire
    case check, plus, chevron, lock, shield, photo, clock, heart, sound
}

struct QuackIcon: View {
    let name: QuackIconName
    var size: CGFloat = 24
    var color: Color = .primary
    var strokeWidth: CGFloat = 1.8

    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width
            ctx.stroke(path(for: name, in: sz), with: .color(color),
                       style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            if name == .star || name == .fire || name == .heart || name == .speaker || name == .play {
                ctx.fill(path(for: name, in: sz), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }

    private func path(for icon: QuackIconName, in sz: CGSize) -> Path {
        let s = sz.width / 24   // scale factor (icons designed on 24pt grid)
        var p = Path()
        switch icon {
        case .home:
            p.move(to: CGPoint(x: 3*s, y: 11*s))
            p.addLine(to: CGPoint(x: 12*s, y: 3*s))
            p.addLine(to: CGPoint(x: 21*s, y: 11*s))
            p.move(to: CGPoint(x: 5*s, y: 10*s))
            p.addLine(to: CGPoint(x: 5*s, y: 20*s))
            p.addLine(to: CGPoint(x: 19*s, y: 20*s))
            p.addLine(to: CGPoint(x: 19*s, y: 10*s))
        case .mission:
            p.addEllipse(in: CGRect(x: 3*s, y: 3*s, width: 18*s, height: 18*s))
            p.addEllipse(in: CGRect(x: 8*s, y: 8*s, width: 8*s, height: 8*s))
        case .book:
            p.move(to: CGPoint(x: 4*s, y: 4*s))
            p.addLine(to: CGPoint(x: 11*s, y: 4*s))
            p.addCurve(to: CGPoint(x: 14*s, y: 7*s),
                       control1: CGPoint(x: 14*s, y: 4*s), control2: CGPoint(x: 14*s, y: 5.5*s))
            p.addLine(to: CGPoint(x: 14*s, y: 17*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 15*s),
                       control1: CGPoint(x: 14*s, y: 17*s), control2: CGPoint(x: 13*s, y: 15*s))
            p.addLine(to: CGPoint(x: 4*s, y: 15*s))
            p.closeSubpath()
            p.move(to: CGPoint(x: 20*s, y: 4*s))
            p.addLine(to: CGPoint(x: 13*s, y: 4*s))
            p.addCurve(to: CGPoint(x: 10*s, y: 7*s),
                       control1: CGPoint(x: 10*s, y: 4*s), control2: CGPoint(x: 10*s, y: 5.5*s))
            p.addLine(to: CGPoint(x: 10*s, y: 17*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 15*s),
                       control1: CGPoint(x: 10*s, y: 17*s), control2: CGPoint(x: 11*s, y: 15*s))
            p.addLine(to: CGPoint(x: 20*s, y: 15*s))
            p.closeSubpath()
        case .parent:
            p.addEllipse(in: CGRect(x: 8*s, y: 4*s, width: 8*s, height: 8*s))
            p.move(to: CGPoint(x: 4*s, y: 21*s))
            p.addCurve(to: CGPoint(x: 20*s, y: 21*s),
                       control1: CGPoint(x: 5*s, y: 17*s), control2: CGPoint(x: 19*s, y: 17*s))
        case .back:
            p.move(to: CGPoint(x: 15*s, y: 6*s))
            p.addLine(to: CGPoint(x: 9*s, y: 12*s))
            p.addLine(to: CGPoint(x: 15*s, y: 18*s))
        case .close:
            p.move(to: CGPoint(x: 6*s, y: 6*s))
            p.addLine(to: CGPoint(x: 18*s, y: 18*s))
            p.move(to: CGPoint(x: 6*s, y: 18*s))
            p.addLine(to: CGPoint(x: 18*s, y: 6*s))
        case .mic:
            p.addRoundedRect(in: CGRect(x: 9*s, y: 3*s, width: 6*s, height: 12*s), cornerSize: CGSize(width: 3*s, height: 3*s))
            p.move(to: CGPoint(x: 5*s, y: 11*s))
            p.addCurve(to: CGPoint(x: 19*s, y: 11*s),
                       control1: CGPoint(x: 5*s, y: 18*s), control2: CGPoint(x: 19*s, y: 18*s))
            p.move(to: CGPoint(x: 12*s, y: 18*s))
            p.addLine(to: CGPoint(x: 12*s, y: 21*s))
        case .camera:
            p.move(to: CGPoint(x: 4*s, y: 7*s))
            p.addLine(to: CGPoint(x: 7*s, y: 7*s))
            p.addLine(to: CGPoint(x: 9*s, y: 4*s))
            p.addLine(to: CGPoint(x: 15*s, y: 4*s))
            p.addLine(to: CGPoint(x: 17*s, y: 7*s))
            p.addLine(to: CGPoint(x: 20*s, y: 7*s))
            p.addLine(to: CGPoint(x: 20*s, y: 19*s))
            p.addLine(to: CGPoint(x: 4*s, y: 19*s))
            p.closeSubpath()
            p.addEllipse(in: CGRect(x: 8*s, y: 9*s, width: 8*s, height: 8*s))
        case .speaker:
            p.move(to: CGPoint(x: 4*s, y: 9*s))
            p.addLine(to: CGPoint(x: 8*s, y: 9*s))
            p.addLine(to: CGPoint(x: 13*s, y: 5*s))
            p.addLine(to: CGPoint(x: 13*s, y: 19*s))
            p.addLine(to: CGPoint(x: 8*s, y: 15*s))
            p.addLine(to: CGPoint(x: 4*s, y: 15*s))
            p.closeSubpath()
            p.move(to: CGPoint(x: 16*s, y: 8*s))
            p.addCurve(to: CGPoint(x: 16*s, y: 16*s),
                       control1: CGPoint(x: 19*s, y: 9.5*s), control2: CGPoint(x: 19*s, y: 14.5*s))
        case .star:
            p.move(to: CGPoint(x: 12*s, y: 3*s))
            p.addLine(to: CGPoint(x: 14.6*s, y: 8.5*s))
            p.addLine(to: CGPoint(x: 20.7*s, y: 9.2*s))
            p.addLine(to: CGPoint(x: 16.2*s, y: 13.2*s))
            p.addLine(to: CGPoint(x: 17.4*s, y: 19.2*s))
            p.addLine(to: CGPoint(x: 12*s, y: 16.1*s))
            p.addLine(to: CGPoint(x: 6.6*s, y: 19.2*s))
            p.addLine(to: CGPoint(x: 7.8*s, y: 13.2*s))
            p.addLine(to: CGPoint(x: 3.3*s, y: 9.2*s))
            p.addLine(to: CGPoint(x: 9.4*s, y: 8.5*s))
            p.closeSubpath()
        case .fire:
            p.move(to: CGPoint(x: 12*s, y: 3*s))
            p.addCurve(to: CGPoint(x: 17*s, y: 13*s),
                       control1: CGPoint(x: 13*s, y: 7*s), control2: CGPoint(x: 17*s, y: 8*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 21*s),
                       control1: CGPoint(x: 21*s, y: 18*s), control2: CGPoint(x: 17*s, y: 21*s))
            p.addCurve(to: CGPoint(x: 7*s, y: 13*s),
                       control1: CGPoint(x: 7*s, y: 21*s), control2: CGPoint(x: 3*s, y: 18*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 3*s),
                       control1: CGPoint(x: 7*s, y: 8*s), control2: CGPoint(x: 11*s, y: 7*s))
        case .check:
            p.move(to: CGPoint(x: 5*s, y: 12*s))
            p.addLine(to: CGPoint(x: 9*s, y: 16*s))
            p.addLine(to: CGPoint(x: 19*s, y: 6*s))
        case .chevron:
            p.move(to: CGPoint(x: 9*s, y: 6*s))
            p.addLine(to: CGPoint(x: 15*s, y: 12*s))
            p.addLine(to: CGPoint(x: 9*s, y: 18*s))
        case .lock:
            p.addRoundedRect(in: CGRect(x: 5*s, y: 11*s, width: 14*s, height: 9*s), cornerSize: CGSize(width: 2*s, height: 2*s))
            p.move(to: CGPoint(x: 8*s, y: 11*s))
            p.addLine(to: CGPoint(x: 8*s, y: 8*s))
            p.addCurve(to: CGPoint(x: 16*s, y: 8*s),
                       control1: CGPoint(x: 8*s, y: 4*s), control2: CGPoint(x: 16*s, y: 4*s))
            p.addLine(to: CGPoint(x: 16*s, y: 11*s))
        case .shield:
            p.move(to: CGPoint(x: 12*s, y: 3*s))
            p.addLine(to: CGPoint(x: 20*s, y: 6*s))
            p.addLine(to: CGPoint(x: 20*s, y: 12*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 21*s),
                       control1: CGPoint(x: 20*s, y: 17*s), control2: CGPoint(x: 16*s, y: 20*s))
            p.addCurve(to: CGPoint(x: 4*s, y: 12*s),
                       control1: CGPoint(x: 8*s, y: 20*s), control2: CGPoint(x: 4*s, y: 17*s))
            p.addLine(to: CGPoint(x: 4*s, y: 6*s))
            p.closeSubpath()
        case .photo:
            p.addRoundedRect(in: CGRect(x: 3*s, y: 5*s, width: 18*s, height: 14*s), cornerSize: CGSize(width: 2*s, height: 2*s))
            p.addEllipse(in: CGRect(x: 7*s, y: 9*s, width: 4*s, height: 4*s))
            p.move(to: CGPoint(x: 3*s, y: 17*s))
            p.addLine(to: CGPoint(x: 9*s, y: 12*s))
            p.addLine(to: CGPoint(x: 14*s, y: 16*s))
            p.addLine(to: CGPoint(x: 17*s, y: 14*s))
            p.addLine(to: CGPoint(x: 21*s, y: 17*s))
        case .clock:
            p.addEllipse(in: CGRect(x: 3*s, y: 3*s, width: 18*s, height: 18*s))
            p.move(to: CGPoint(x: 12*s, y: 7*s))
            p.addLine(to: CGPoint(x: 12*s, y: 12*s))
            p.addLine(to: CGPoint(x: 15*s, y: 14*s))
        case .heart:
            p.move(to: CGPoint(x: 12*s, y: 20*s))
            p.addCurve(to: CGPoint(x: 5*s, y: 10*s),
                       control1: CGPoint(x: 12*s, y: 20*s), control2: CGPoint(x: 5*s, y: 16*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 6*s),
                       control1: CGPoint(x: 5*s, y: 6*s), control2: CGPoint(x: 8*s, y: 6*s))
            p.addCurve(to: CGPoint(x: 19*s, y: 10*s),
                       control1: CGPoint(x: 16*s, y: 6*s), control2: CGPoint(x: 19*s, y: 6*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 20*s),
                       control1: CGPoint(x: 19*s, y: 16*s), control2: CGPoint(x: 12*s, y: 20*s))
        case .sound:
            p.move(to: CGPoint(x: 4*s, y: 9*s))
            p.addLine(to: CGPoint(x: 8*s, y: 9*s))
            p.addLine(to: CGPoint(x: 13*s, y: 5*s))
            p.addLine(to: CGPoint(x: 13*s, y: 19*s))
            p.addLine(to: CGPoint(x: 8*s, y: 15*s))
            p.addLine(to: CGPoint(x: 4*s, y: 15*s))
            p.closeSubpath()
        case .plus:
            p.move(to: CGPoint(x: 12*s, y: 5*s))
            p.addLine(to: CGPoint(x: 12*s, y: 19*s))
            p.move(to: CGPoint(x: 5*s, y: 12*s))
            p.addLine(to: CGPoint(x: 19*s, y: 12*s))
        case .play:
            p.move(to: CGPoint(x: 7*s, y: 5*s))
            p.addLine(to: CGPoint(x: 18*s, y: 12*s))
            p.addLine(to: CGPoint(x: 7*s, y: 19*s))
            p.closeSubpath()
        }
        return p
    }
}

// MARK: - TabBar
enum TabItem: String, CaseIterable {
    case home, missions, library, parent

    var label: String {
        switch self {
        case .home:     return "Home"
        case .missions: return "Missions"
        case .library:  return "Stickers"
        case .parent:   return "Parent"
        }
    }
    var icon: QuackIconName {
        switch self {
        case .home:     return .home
        case .missions: return .mission
        case .library:  return .book
        case .parent:   return .parent
        }
    }
}

struct TabBar: View {
    @Binding var active: TabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                let on = active == tab
                Button { active = tab } label: {
                    VStack(spacing: 3) {
                        // indicator bar
                        RoundedRectangle(cornerRadius: 999)
                            .fill(on ? Color.quackOrange : Color.clear)
                            .frame(width: 28, height: 4)

                        QuackIcon(name: tab.icon, size: 24,
                                  color: on ? .quackOrange : .inkMuted,
                                  strokeWidth: on ? 2.2 : 1.8)

                        Text(tab.label)
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(0.4)
                            .foregroundStyle(on ? Color.quackOrange : Color.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                }
                .buttonStyle(TapPress())
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(Color.paper)
        .shadow(color: .ink.opacity(0.08), radius: 8, x: 0, y: -4)
    }
}
```

- [ ] **Step 2: Add preview**

```swift
#Preview("TabBar") {
    VStack {
        Spacer()
        TabBarPreviewWrapper()
    }
}

private struct TabBarPreviewWrapper: View {
    @State var active: TabItem = .home
    var body: some View { TabBar(active: $active) }
}
```

- [ ] **Step 3: Verify all 4 tabs render, active indicator shows in orange**

- [ ] **Step 4: Commit**

```bash
git add quack/Components.swift
git commit -m "feat: add QuackIcon (20 paths) and TabBar (4 tabs)"
```

---

## Task 8: Components — StickerTile and Confetti

**Files:**
- Modify: `quack/Components.swift` (append)

- [ ] **Step 1: Append StickerTile and Confetti**

```swift
// MARK: - StickerTile
enum StickerSize { case sm, md, lg }

struct StickerTile: View {
    let item: VocabItem
    var locked: Bool = false
    var size: StickerSize = .md
    var justEarned: Bool = false
    var onTap: (() -> Void)? = nil

    private var dim: CGFloat {
        switch size { case .sm: 78; case .md: 110; case .lg: 140 }
    }
    private var hanziSize: CGFloat {
        switch size { case .sm: 28; case .md: 38; case .lg: 48 }
    }

    @State private var appeared = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(locked ? Color.inkFaint : item.tone.bg)

                if !locked {
                    GrainOverlay()
                    // Emoji halo top-right
                    Text(item.emoji)
                        .font(.system(size: 18))
                        .opacity(0.35)
                        .rotationEffect(.degrees(14))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(10)
                    // ✦ bottom-left
                    Text("✦")
                        .font(.system(size: 14, weight: .black))
                        .opacity(0.35)
                        .rotationEffect(.degrees(-10))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(8)
                }

                VStack(spacing: 4) {
                    if locked {
                        QuackIcon(name: .lock, size: 28, color: .inkMuted, strokeWidth: 1.8)
                    } else {
                        Text(item.hanzi)
                            .font(.display(hanziSize, weight: .heavy))
                            .foregroundStyle(item.tone.fg)
                        Text(item.pinyin)
                            .font(.body(10, weight: .bold))
                            .foregroundStyle(item.tone.fg.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .cardShadow()
            .scaleEffect(appeared ? 1 : 0.05)
            .opacity(appeared ? 1 : 0)
        }
        .buttonStyle(TapPress())
        .disabled(onTap == nil || locked)
        .onAppear {
            if justEarned {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.45).delay(0.2)) {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
    }
}

// MARK: - Confetti
private struct ConfettiPiece {
    let x: Double
    let delay: Double
    let duration: Double
    let rotation: Double
    let colorIndex: Int
    let shape: Int   // 0=rect, 1=tall, 2=circle
}

private let confettiColors: [Color] = [.quackOrange, .quackYellow, .mint, .cobalt, .rose]

struct Confetti: View {
    var count: Int = 30

    private let pieces: [ConfettiPiece] = (0..<30).map { i in
        ConfettiPiece(
            x: Double(i * 3337 % 100) / 100,
            delay: Double(i * 1234 % 800) / 1000,
            duration: 1.6 + Double(i * 567 % 1600) / 1000,
            rotation: Double(i * 137 % 360),
            colorIndex: i % 5,
            shape: i % 3
        )
    }

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let now = tl.date.timeIntervalSinceReferenceDate
                for piece in pieces.prefix(count) {
                    let elapsed = (now - piece.delay).truncatingRemainder(dividingBy: piece.duration + 0.5)
                    guard elapsed > 0 else { continue }
                    let progress = elapsed / (piece.duration + 0.5)
                    let y = -20 + progress * (size.height + 40)
                    let x = piece.x * size.width
                    let rot = Angle.degrees(piece.rotation + progress * 720)

                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: rot)
                    let w: CGFloat = piece.shape == 0 ? 10 : 14
                    let h: CGFloat = piece.shape == 1 ? 16 : 10
                    let rect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
                    let path = piece.shape == 2 ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 2)
                    ctx.fill(path, with: .color(confettiColors[piece.colorIndex].opacity(1 - progress * 0.5)))
                    ctx.translateBy(x: -x, y: -y)
                    ctx.rotate(by: .degrees(-rot.degrees))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
```

- [ ] **Step 2: Add preview**

```swift
#Preview("StickerTile") {
    let apple = VOCAB[0]
    let fish  = VOCAB[7]
    return VStack {
        HStack {
            StickerTile(item: apple, size: .sm)
            StickerTile(item: fish, size: .sm)
            StickerTile(item: apple, locked: true, size: .sm)
        }
        StickerTile(item: apple, size: .md)
        StickerTile(item: fish, justEarned: true, size: .lg)
    }
    .padding()
    .background(Color.cream)
}

#Preview("Confetti") {
    ZStack {
        Color.mint.ignoresSafeArea()
        Confetti(count: 30)
    }
}
```

- [ ] **Step 3: Verify confetti animates continuously, sticker tiles show hanzi/pinyin/emoji**

- [ ] **Step 4: Commit**

```bash
git add quack/Components.swift
git commit -m "feat: add StickerTile and Confetti components"
```

---

## Task 9: Mascot.swift

**Files:**
- Create: `quack/Mascot.swift`
- Modify: `Assets.xcassets` — add duck-mascot image set

- [ ] **Step 1: Add duck-mascot.png to Assets.xcassets**

In Xcode's Project Navigator, expand `Assets.xcassets`. Drag `quack_example/assets/duck-mascot.png` into the asset catalog. Xcode creates a new image set. Name it `duck-mascot`.

Verify the file appears as `duck-mascot` in the asset catalog with a 1x slot filled.

- [ ] **Step 2: Create Mascot.swift**

```swift
import SwiftUI

enum MascotState {
    case idle, speaking, celebrating, listening
}

struct Mascot: View {
    var state: MascotState = .idle
    var size: CGFloat = 160

    @State private var animating = false

    var body: some View {
        ZStack {
            // Listening rings
            if state == .listening {
                ForEach([0.0, 0.5, 1.0], id: \.self) { delay in
                    Circle()
                        .stroke(Color.quackOrange, lineWidth: 3)
                        .frame(width: size * 0.84, height: size * 0.84)
                        .scaleEffect(animating ? 2.2 : 0.8)
                        .opacity(animating ? 0 : 0.4)
                        .animation(
                            .easeOut(duration: 1.8)
                                .repeatForever(autoreverses: false)
                                .delay(delay),
                            value: animating
                        )
                }
            }

            // Celebrating sparkles
            if state == .celebrating {
                ForEach(["✦", "★", "✦", "+", "★"].indices, id: \.self) { i in
                    let glyphs = ["✦", "★", "✦", "+", "★"]
                    let tops: [CGFloat]  = [0.10, 0.30, 0.60, 0.20, 0.70]
                    let lefts: [CGFloat] = [-0.08, 1.00, -0.04, 1.08, 0.95]
                    let sizes: [CGFloat] = [22, 16, 18, 14, 20]
                    let colors: [Color]  = [.quackYellow, .quackOrange, .white, .quackYellow, .quackOrange]
                    Text(glyphs[i])
                        .font(.system(size: sizes[i], weight: .black))
                        .foregroundStyle(colors[i])
                        .offset(x: lefts[i] * size, y: tops[i] * size)
                        .rotationEffect(
                            .degrees(animating ? 360 : 0),
                            anchor: .center
                        )
                        .scaleEffect(animating ? 1.2 : 1.0)
                        .animation(
                            .easeOut(duration: 1.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: animating
                        )
                }
            }

            // Duck image
            Image("duck-mascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: .ink.opacity(0.18), radius: 16, x: 0, y: 8)
                .modifier(MascotAnimationModifier(state: state, animating: animating))
        }
        .frame(width: size, height: size)
        .onAppear { animating = true }
    }
}

private struct MascotAnimationModifier: ViewModifier, Animatable {
    let state: MascotState
    let animating: Bool

    func body(content: Content) -> some View {
        switch state {
        case .idle:
            content
                .offset(y: animating ? -6 : 0)
                .rotationEffect(.degrees(animating ? 1 : -1), anchor: .bottom)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: animating
                )
        case .speaking:
            content
                .scaleEffect(animating ? CGSize(width: 1.02, height: 0.98) : CGSize(width: 0.99, height: 1.02))
                .offset(y: animating ? -2 : -1)
                .animation(
                    .easeInOut(duration: 0.35).repeatForever(autoreverses: true),
                    value: animating
                )
        case .celebrating:
            content
                .rotationEffect(.degrees(animating ? 8 : -8), anchor: .bottom)
                .offset(y: animating ? -22 : 0)
                .animation(
                    .spring(response: 0.7, dampingFraction: 0.45).repeatForever(autoreverses: true),
                    value: animating
                )
        case .listening:
            content
                .offset(y: animating ? -6 : 0)
                .animation(
                    .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                    value: animating
                )
        }
    }
}

#Preview("Mascot States") {
    HStack(spacing: 16) {
        VStack {
            Mascot(state: .idle, size: 100)
            Text("idle").font(.caption)
        }
        VStack {
            Mascot(state: .speaking, size: 100)
            Text("speak").font(.caption)
        }
        VStack {
            Mascot(state: .celebrating, size: 100)
            Text("celebrate").font(.caption)
        }
        VStack {
            Mascot(state: .listening, size: 100)
            Text("listen").font(.caption)
        }
    }
    .padding()
    .background(Color.cream)
}
```

- [ ] **Step 3: Open preview — verify duck image renders and all 4 states have distinct animations**

If duck-mascot image doesn't load, check the asset name matches "duck-mascot" exactly (no .png extension in code).

- [ ] **Step 4: Commit**

```bash
git add quack/Mascot.swift quack/Assets.xcassets
git commit -m "feat: add Mascot component with 4 animation states (idle/speaking/celebrating/listening)"
```

---

## Task 10: AppView.swift — onboarding gate

**Files:**
- Create: `quack/AppView.swift`
- Modify: `quack/quackApp.swift`

- [ ] **Step 1: Create AppView.swift**

```swift
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
```

- [ ] **Step 2: Update quackApp.swift**

```swift
import SwiftUI

@main
struct quackApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add quack/AppView.swift quack/quackApp.swift
git commit -m "feat: add AppView onboarding gate and inject AppState into environment"
```

---

## Task 11: OnboardingFlow — Splash and Name screens

**Files:**
- Create: `quack/OnboardingFlow.swift`

- [ ] **Step 1: Create OnboardingFlow.swift with SplashView and NameView**

```swift
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
                    .font(.body(14))
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

                Text("Already have an agent? ")
                    .font(.body(13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                + Text("Sign in")
                    .font(.body(13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .underline()

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
                // Top bar
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Step 1 of 3", flank: false, size: 11)
                    Text("Tell us your name")
                        .font(.display(30, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("So Q knows what to call you")
                        .font(.body(14))
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Orange card with input + mascot
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.quackOrange)
                        .grain()
                        .popShadow()

                    Sparkles(count: 4, opacity: 0.55)

                    VStack(spacing: 0) {
                        Text("First name")
                            .font(.body(13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.top, 24)

                        TextField("e.g. Nia", text: $name)
                            .font(.body(18, weight: .heavy))
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
                            .onSubmit { if !name.trimmingCharacters(in: .whitespaces).isEmpty { onNext(name.trimmingCharacters(in: .whitespaces)) } }

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
                    action: { onNext(name.trimmingCharacters(in: .whitespaces).isEmpty ? "Agent" : name.trimmingCharacters(in: .whitespaces)) }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear { focused = true }
    }
}
```

- [ ] **Step 2: Add preview**

```swift
#Preview("Splash") {
    SplashView(onNext: {})
        .environment(AppState())
}

#Preview("Name") {
    NameView(initial: "Alex", onBack: {}, onNext: { _ in })
        .environment(AppState())
}
```

- [ ] **Step 3: Verify previews — splash has orange bg + duck + ✦ sparkles; name has orange card with input field**

- [ ] **Step 4: Commit**

```bash
git add quack/OnboardingFlow.swift
git commit -m "feat: add SplashView and NameView onboarding screens"
```

---

## Task 12: OnboardingFlow — AgeView (drag wheel)

**Files:**
- Modify: `quack/OnboardingFlow.swift` (append AgeView)

- [ ] **Step 1: Append AgeView to OnboardingFlow.swift**

```swift
// MARK: - AgeView
struct AgeView: View {
    let initial: Int
    let onBack: () -> Void
    let onNext: (Int) -> Void

    private let ages = [4, 5, 6, 7, 8, 9, 10, 11, 12]
    private let itemWidth: CGFloat = 110

    @State private var selectedIndex: Int
    @GestureState private var dragOffset: CGFloat = 0
    @State private var dragging = false

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
                // Top bar
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Step 2 of 3", flank: false, size: 11)
                    Text("How old are you?")
                        .font(.display(28, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("Drag to spin · Q sets the level")
                        .font(.body(13))
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 14)

                // Orange card with wheel
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.quackOrange)
                        .grain()
                        .popShadow()

                    Sparkles(count: 4, opacity: 0.5)

                    VStack(spacing: 0) {
                        // Wheel
                        ZStack {
                            // Centre indicator circle
                            Circle()
                                .stroke(Color.white.opacity(0.45), lineWidth: 3)
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 110, height: 110)

                            // Drag track
                            GeometryReader { geo in
                                let offset = -CGFloat(selectedIndex) * itemWidth + dragOffset
                                HStack(spacing: 0) {
                                    ForEach(ages.indices, id: \.self) { i in
                                        let dist = abs(CGFloat(i - selectedIndex) - dragOffset / itemWidth)
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
                                .animation(dragging ? nil : .spring(response: 0.32, dampingFraction: 0.7), value: offset)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .updating($dragOffset) { val, state, _ in
                                            state = val.translation.width
                                            dragging = true
                                        }
                                        .onEnded { val in
                                            let steps = Int((-val.translation.width / itemWidth).rounded())
                                            selectedIndex = max(0, min(ages.count - 1, selectedIndex + steps))
                                            dragging = false
                                        }
                                )
                            }
                            .frame(height: 180)
                            .clipped()
                            // Edge fades
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
```

- [ ] **Step 2: Add preview**

```swift
#Preview("Age") {
    AgeView(initial: 8, onBack: {}, onNext: { _ in })
        .environment(AppState())
}
```

- [ ] **Step 3: Verify drag wheel scrolls, numbers scale and fade correctly, selected number is largest**

- [ ] **Step 4: Commit**

```bash
git add quack/OnboardingFlow.swift
git commit -m "feat: add AgeView with drag wheel picker (ages 4–12)"
```

---

## Task 13: OnboardingFlow — IntroView

**Files:**
- Modify: `quack/OnboardingFlow.swift` (append IntroView)

- [ ] **Step 1: Append IntroView to OnboardingFlow.swift**

```swift
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
                // Top bar
                HStack {
                    BackBtn(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Step 3 of 3", flank: false, size: 11)
                    Text("How it works, \(name)")
                        .font(.display(30, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("Three things to know before your first mission")
                        .font(.body(14))
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Tip cards
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
                                    .font(.body(13))
                                    .foregroundStyle(Color.inkMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .quackCard()
                        .opacity(1)
                        .offset(y: 0)
                        .animation(.easeOut(duration: 0.4).delay(Double(i) * 0.1), value: true)
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
```

- [ ] **Step 2: Verify preview — 3 tip cards with coloured icon squares, cream background**

- [ ] **Step 3: Test full onboarding flow in simulator**

Build and run on iPhone 15 Pro simulator. Tap through Splash → Name (enter name) → Age (drag wheel) → Intro → app transitions to placeholder MainTabView. Verify `@AppStorage("quack.hasOnboarded")` persists: kill and relaunch, app should skip onboarding.

To reset onboarding for testing, add to AppView temporarily:
```swift
// DEBUG only — delete before shipping
Button("Reset") { hasOnboarded = false }.padding()
```

- [ ] **Step 4: Commit**

```bash
git add quack/OnboardingFlow.swift
git commit -m "feat: add IntroView, complete onboarding flow (Splash→Name→Age→Intro)"
```

---

## Task 14: HomeView — header, daily ring, mission hero card

**Files:**
- Rewrite: `quack/HomeView.swift`

- [ ] **Step 1: Rewrite HomeView.swift with header and mission hero sections**

```swift
import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    var onMission: (String) -> Void
    @Binding var activeTab: TabItem

    @State private var showProfile = false

    private var todayWord: VocabItem? {
        VOCAB.first { $0.id == appState.todayMission.target }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    greetingHeader
                    dailyRingCard
                    missionHeroCard
                    statCards
                    recentStickers
                    trainingGrid
                    Spacer().frame(height: 120) // tab bar clearance
                }
            }
            .background(Color.cream)

            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showProfile) {
            ProfilePlaceholder()
        }
    }

    // MARK: - Greeting header
    private var greetingHeader: some View {
        HStack(spacing: 12) {
            // Avatar initial
            Button { showProfile = true } label: {
                Text(String((appState.name.isEmpty ? "A" : appState.name).prefix(1)).uppercased())
                    .font(.display(22, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.quackOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .cardShadow()
            }
            .buttonStyle(TapPress())

            VStack(alignment: .leading, spacing: 2) {
                Text("WELCOME BACK")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(11 * 0.12)
                    .foregroundStyle(Color.inkMuted)
                Text("Hey, \(appState.name)")
                    .font(.display(22, weight: .heavy))
                    .foregroundStyle(Color.ink)
            }

            Spacer()

            // Streak chip
            HStack(spacing: 6) {
                QuackIcon(name: .fire, size: 16, color: .quackOrangeDeep, strokeWidth: 1.8)
                Text("\(appState.streak)")
                    .font(.display(16, weight: .heavy))
                    .foregroundStyle(Color.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .quackCard()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Daily ring card
    private var dailyRingCard: some View {
        HStack(spacing: 14) {
            DailyRing(value: appState.dailyProgress, max: appState.dailyGoal)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(appState.dailyProgress) / \(appState.dailyGoal) stars today")
                    .font(.display(18, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text(appState.dailyProgress >= appState.dailyGoal
                     ? "Goal smashed! Keep going for bonus stickers."
                     : "Finish your mission to hit today's goal.")
                    .font(.body(12))
                    .foregroundStyle(Color.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .quackCard()
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    // MARK: - Today's mission hero card
    private var missionHeroCard: some View {
        Button { onMission("camera") } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.quackOrange)
                    .grain()
                    .popShadow()
                    .frame(minHeight: 220)

                Sparkles(count: 6, opacity: 0.6, animate: true)

                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: "Today's mission", color: .quackYellow, flank: false)
                        .padding(.top, 22)
                        .padding(.horizontal, 22)

                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.todayMission.title)
                                .font(.display(26, weight: .heavy))
                                .foregroundStyle(.white)
                            if let word = todayWord {
                                Text("Q is listening. Say ")
                                    .font(.body(14))
                                    .foregroundStyle(.white.opacity(0.9))
                                + Text(word.hanzi)
                                    .font(.display(18, weight: .heavy))
                                    .foregroundStyle(.white)
                                + Text(" (\(word.pinyin)) — earn 3 stars.")
                                    .font(.body(14))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        Spacer()
                        Mascot(state: .idle, size: 70)
                            .padding(.top, -4)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 22)

                    HStack {
                        // 3 star slots
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(.white.opacity(0.18))
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        QuackIcon(name: .star, size: 14, color: .white.opacity(0.45), strokeWidth: 1.6)
                                    )
                            }
                        }
                        Spacer()
                        // Start button
                        HStack(spacing: 6) {
                            Text("Start mission")
                                .font(.body(14, weight: .heavy))
                            QuackIcon(name: .chevron, size: 16, color: .quackOrange, strokeWidth: 2.2)
                        }
                        .foregroundStyle(Color.quackOrange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .cardShadow()
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
                }
            }
        }
        .buttonStyle(TapPress())
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }
}
```

- [ ] **Step 2: Add temporary preview stub (full HomeView preview in next task)**

```swift
#Preview("HomeView partial") {
    @State var tab = TabItem.home
    return HomeView(onMission: { _ in }, activeTab: $tab)
        .environment(AppState())
}
```

- [ ] **Step 3: Verify preview — orange mission hero card with Mascot visible, DailyRing rendered, greeting header with avatar**

- [ ] **Step 4: Commit**

```bash
git add quack/HomeView.swift
git commit -m "feat: add HomeView header, daily ring card, and today's mission hero card"
```

---

## Task 15: HomeView — stat cards, recent stickers, training grid

**Files:**
- Modify: `quack/HomeView.swift` (append stat card, stickers, training grid sections)

- [ ] **Step 1: Append remaining HomeView sections after the `missionHeroCard` var**

```swift
    // MARK: - Stat cards
    private var statCards: some View {
        HStack(spacing: 12) {
            // Streak card
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Streak", color: .ink, flank: false, size: 11)
                Text("\(appState.streak)")
                    .font(.display(38, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text("days in a row")
                    .font(.body(12))
                    .foregroundStyle(Color.ink.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .quackCard(tone: .mint)

            // Stickers card
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Stickers", color: .white.opacity(0.85), flank: false, size: 11)
                Text("\(appState.learned.count)")
                    .font(.display(38, weight: .heavy))
                    .foregroundStyle(.white)
                Text("of \(VOCAB.count) collected")
                    .font(.body(12))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .quackCard(tone: .cobalt)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    // MARK: - Recent stickers
    @ViewBuilder
    private var recentStickers: some View {
        let recent = appState.learned.suffix(4).reversed().compactMap { id in
            VOCAB.first { $0.id == id }
        }
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Recent stickers")
                        .font(.display(18, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Button("See all") { activeTab = .library }
                        .font(.body(13, weight: .heavy))
                        .foregroundStyle(Color.quackOrange)
                        .buttonStyle(TapPress())
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(recent) { item in
                        StickerTile(item: item, size: .sm)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Training type grid
    private var trainingGrid: some View {
        let types: [(id: String, label: String, sub: String, tone: Tone, icon: QuackIconName)] = [
            ("camera", "Camera scan", "Point at it", .orange, .camera),
            ("speak",  "Say it back", "Mic check",   .cobalt, .mic),
            ("match",  "Match cards", "Word ↔ pic",  .rose,   .star),
            ("story",  "Q's story",   "Listen & learn", .mint, .book),
        ]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Pick your training")
                .font(.display(18, weight: .heavy))
                .foregroundStyle(Color.ink)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(types, id: \.id) { t in
                    Button { onMission(t.id) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            QuackIcon(name: t.icon, size: 22, color: t.tone.fg, strokeWidth: 2)

                            Spacer()

                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.label)
                                    .font(.display(16, weight: .heavy))
                                    .foregroundStyle(t.tone.fg)
                                Text(t.sub)
                                    .font(.body(11, weight: .bold))
                                    .foregroundStyle(t.tone.fg.opacity(0.8))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 110)
                        .quackCard(tone: t.tone)
                    }
                    .buttonStyle(TapPress())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}

// Placeholder for profile sheet (Phase 3)
struct ProfilePlaceholder: View {
    var body: some View {
        VStack { Text("Profile — Phase 3").font(.display(20)) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.cream)
    }
}

#Preview("HomeView") {
    @Previewable @State var tab = TabItem.home
    let state = AppState()
    state.streak = 4
    state.dailyProgress = 1
    return HomeView(onMission: { _ in }, activeTab: $tab)
        .environment(state)
}
```

- [ ] **Step 2: Verify preview — scroll reveals all sections: stat cards (mint/cobalt), training grid (4 toned cards), tab bar at bottom**

- [ ] **Step 3: Commit**

```bash
git add quack/HomeView.swift
git commit -m "feat: complete HomeView — stat cards, recent stickers grid, training type grid"
```

---

## Task 16: MainTabView.swift — tab container

**Files:**
- Create: `quack/MainTabView.swift`

- [ ] **Step 1: Create MainTabView.swift**

```swift
import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var activeTab: TabItem = .home
    @State private var missionType: String? = nil

    var body: some View {
        ZStack {
            switch activeTab {
            case .home:
                NavigationStack {
                    HomeView(onMission: { type in missionType = type }, activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)

            case .missions:
                NavigationStack {
                    MissionsPlaceholder(activeTab: $activeTab)
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
        // Mission sheet — placeholder until Phase 2
        .sheet(item: $missionType) { type in
            MissionPlaceholder(type: type, onDismiss: { missionType = nil })
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Phase 2 / 3 placeholders
struct MissionsPlaceholder: View {
    @Binding var activeTab: TabItem
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                Text("Missions Hub").font(.display(24))
                Text("Coming in Phase 2").font(.body(14)).foregroundStyle(Color.inkMuted)
                Spacer()
            }
            .background(Color.cream)
            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct LibraryPlaceholder: View {
    @Binding var activeTab: TabItem
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                Text("Sticker Book").font(.display(24))
                Text("Coming in Phase 3").font(.body(14)).foregroundStyle(Color.inkMuted)
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
                Text("Coming in Phase 3").font(.body(14)).foregroundStyle(Color.inkMuted)
                Spacer()
            }
            .background(Color.cream)
            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct MissionPlaceholder: View {
    let type: String
    let onDismiss: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("Mission: \(type)").font(.display(24))
            Text("Coming in Phase 2").font(.body(14)).foregroundStyle(Color.inkMuted)
            CTAButton(label: "Close", variant: .ink, action: onDismiss)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cream)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
```

- [ ] **Step 2: Build and run on iPhone 15 Pro simulator (`Cmd+R`)**

Expected behaviour:
- App launches to Splash screen (first run)
- Complete onboarding → reaches HomeView with tab bar
- Tab bar switches between Home / Missions / Stickers / Parent
- Mission type buttons in HomeView open a placeholder sheet
- Kill app and relaunch → skips onboarding, goes straight to Home

- [ ] **Step 3: Verify against reference**

Open `quack_example/Quack.html` in a browser. Compare:
- Home screen layout matches (greeting + ring card + mission hero + stat cards + training grid)
- Colors match reference hex values
- Tab bar position + active indicator matches
- Onboarding screens match step by step

- [ ] **Step 4: Commit**

```bash
git add quack/MainTabView.swift
git commit -m "feat: add MainTabView with 4-tab navigation, placeholder screens for Phase 2/3"
```

---

## Phase 1 Complete ✓

Run full test suite: `Cmd+U`

Expected: 6 AppState tests pass.

Manually test on simulator:
- [ ] Onboarding completes, `hasOnboarded` persists across relaunches
- [ ] Name and age from onboarding appear on HomeView header
- [ ] DailyRing animates when `dailyProgress` changes
- [ ] All 4 tabs navigate
- [ ] Mission type buttons open placeholder sheet
- [ ] Profile sheet opens from avatar tap in HomeView

**Deliverable:** App launches, onboards, lands on a fully designed Home screen with correct design system, 4-tab navigation, and placeholder screens for Phases 2 and 3.
