# Quack iOS — Full UI Port Design

**Date:** 2026-05-13  
**Reference:** `quack_example/` (React/JSX web prototype)  
**Target:** SwiftUI iOS app in `quack/`  

---

## 1. Goal

Port every screen, component, interaction, and animation from the `quack_example` web reference into native SwiftUI. The result must be visually and behaviourally identical to the reference on an iPhone.

---

## 2. Decisions

| Decision | Choice | Reason |
|---|---|---|
| Approach | Clean rewrite (delete old screens) | Existing screens have different nav model and design system |
| Phasing | 3 phases, each independently shippable | Validate as we go |
| Fonts | SF Rounded (display/headings), SF Pro (body) | Baloo 2 + Nunito not available on iOS; SF Rounded is closest native equivalent |
| Mission interactivity | Simulated (no real camera/mic) | Matches web reference behaviour; no AVFoundation complexity |
| State persistence | `@Observable AppState` + `UserDefaults` for name/age/learned | In-memory session state + cross-launch persistence |

---

## 3. Architecture

### Navigation Model

```
AppView  (@AppStorage hasOnboarded gate)
├── OnboardingFlow          (if !hasOnboarded)
│   ├── SplashView
│   ├── NameView
│   ├── AgeView
│   └── IntroView
└── MainTabView             (if hasOnboarded)
    ├── Tab 1: HomeView
    │   ├── → CameraMissionView
    │   ├── → SpeakMissionView
    │   ├── → MatchMissionView
    │   ├── → StoryMissionView
    │   └── ProfileView     (sheet, avatar tap)
    ├── Tab 2: MissionsHubView
    │   └── → same 4 mission views
    ├── Tab 3: LibraryView
    └── Tab 4: ParentView
        └── → SnapPhotoView
CompleteView                (fullScreenCover, any tab)
```

Each tab wrapped in `NavigationStack`. Missions pushed via `NavigationLink`. `CompleteView` presented as `.fullScreenCover` from `MainTabView`.

### State Model

```swift
@Observable class AppState {
    var name: String          // persisted: UserDefaults "quack.name"
    var age: Int              // persisted: UserDefaults "quack.age"
    var streak: Int           // persisted: UserDefaults "quack.streak"
    var dailyProgress: Int
    var dailyGoal: Int = 3
    var learned: [String]     // persisted: UserDefaults "quack.learned" (JSON)
    var todayMission: TodayMission

    func addLearned(_ id: String)
    func resetProgress()
}

struct TodayMission {
    var id: String
    var title: String
    var target: String        // vocab id
}
```

`AppState` injected via `.environment(appState)` at `AppView` level.

---

## 4. Design System

### 4.1 Colors (`Theme.swift`)

All tokens as `Color` extensions:

| Swift name | Hex | Replaces |
|---|---|---|
| `.quackOrange` | `#F86A38` | `.quOrange` |
| `.quackOrangeDeep` | `#E54E1B` | `.quRed` (partial) |
| `.quackYellow` | `#FCC83C` | `.quYellow` |
| `.cream` | `#FFF1E1` | `.quCream` |
| `.creamDeep` | `#FBE6CB` | — new — |
| `.ink` | `#14213D` | `.quNavy` |
| `.inkMuted` | `#9098AE` | — new — |
| `.inkFaint` | `#D7DAE3` | — new — |
| `.cobalt` | `#4F5DDB` | `.quBlue` |
| `.mint` | `#93D5B8` | `.quGreen` |
| `.mintDeep` | `#5FB594` | — new — |
| `.rose` | `#FF8FA3` | — new — |
| `.lilac` | `#C9C5F2` | — new — |

Dropped: `.quPurple`, `.quNavy`, `.quRed`, `.quOrange`, `.quBlue`, `.quGreen` (all renamed above).

### 4.2 Tone Map

Maps a vocab item's `tone` string to bg/fg `Color` pair. Used by `StickerTile`, `ObjectArt`, mission cards.

```swift
enum Tone: String {
    case orange, yellow, cobalt, mint, rose, lilac, cream
    var bg: Color { ... }
    var fg: Color { ... }
}
```

| Tone | Background | Foreground |
|---|---|---|
| orange | `.quackOrange` | `.white` |
| yellow | `.quackYellow` | `.ink` |
| cobalt | `.cobalt` | `.white` |
| mint | `.mint` | `.ink` |
| rose | `.rose` | `.ink` |
| lilac | `.lilac` | `.ink` |
| cream | `.creamDeep` | `.ink` |

### 4.3 Typography

All text uses `.rounded` font design for display roles, default for body:

| Role | Size | Weight | Design |
|---|---|---|---|
| Hero / wordmark | 38 | `.black` | `.rounded` |
| H1 | 28–30 | `.heavy` | `.rounded` |
| H2 | 22–26 | `.heavy` | `.rounded` |
| H3 | 18 | `.bold` | `.rounded` |
| Eyebrow | 11–12 | `.heavy` | `.rounded` |
| Body | 14–16 | `.semibold` | default |
| Caption | 11–13 | `.bold` | default |

### 4.4 Shadows & Radii

```swift
// Shadows
.shadow(color: .ink.opacity(0.08), radius: 6, x: 0, y: 2)   // card
.shadow(color: .ink.opacity(0.16), radius: 12, x: 0, y: 4)  // pop

// Corner radii
6, 10, 16, 22 (default card), 28 (hero card), 999 (pill/circle)
```

### 4.5 Animations

| Name | Spec |
|---|---|
| screen-in | `.opacity` + `.offset(y: 8)` → 0, 320ms easeOut |
| pop-in | `.scale(0→1.1→1)`, 500ms spring bounce |
| mascot-idle | float Y –6pt, 3.6s ease infinite |
| mascot-speaking | scale pulse 1→1.02→1, 0.7s infinite |
| mascot-celebrating | bounce + rotate ±8°, 1.4s infinite |
| mascot-listening | ring-grow concentric circles, 1.8s stagger |
| confetti-drop | Y offset –20 → +560, rotate 720°, 1.6–3.2s |
| dot-bounce | Y –6pt bounce, 3 dots staggered 0.16s |
| star-spin | rotate 360° + scale 1→1.2→1, 1.6s |

---

## 5. Components (`Components.swift`)

### Eyebrow
Small-caps label, optional ✦ flanks. `color` param. Used as section labels throughout.

### Sparkles
Scattered ✦ glyphs at fixed positions, optional `float-y` animation. Used on orange/toned bg cards.

### CTAButton
Full-width pill button. Variants: `ink` (dark bg), `orange`, `ghost` (outline). `TapPress` ButtonStyle sinks 2pt on press.

### BackBtn
44×44 rounded square (r=14). Dark/light variants. ChevronLeft SF Symbol fallback or custom path.

### Mascot
Image("duck-mascot") with 4 animation states via `.keyframeAnimator`. Listening state adds 3 concentric ring pulses behind the image.

### ProgressBar
Animated fill capsule. `value`, `max`, `color`, `trackColor`, `height` params.

### DailyRing
64×64 `Canvas`-drawn circle progress. Orange stroke on ink-faint track. Centred number label overlay.

### Confetti
`TimelineView` + `Canvas`. 30 pieces, 5 colours, 3 shapes (rect/tall-rect/circle), random X positions, continuous drop loop.

### StickerTile
Tapped `Button`, sizes sm/md/lg (78/110/140pt). Toned bg, hanzi hero text, pinyin caption, emoji halo top-right + ✦ bottom-left. Locked state shows lock icon on grey bg. `justEarned` triggers pop-in animation.

### ObjectArt
`Canvas`-based illustrations for all 20 vocab items. Each is a hand-ported version of the reference SVG paths. Fallback: emoji on toned circle blob.

### Pill
Inline status chip. Optional animated pulse dot (recording/listening states).

### TabBar
Custom `HStack` pinned to bottom. 4 tabs: Home / Missions / Stickers / Parent. Active tab shows orange indicator bar above icon + orange icon colour. White paper bg with top shadow.

### QuackCard
`ViewModifier`: white (or toned) bg, `cornerRadius(22)`, card shadow. Used as `.quackCard()` or `.quackCard(tone: .mint)`.

### QuackIcon
SwiftUI `Path` implementations of 20 icons: back, close, home, mission, book, parent, mic, camera, speaker, star, fire, check, plus, chevron, lock, shield, photo, clock, heart, sound.

---

## 6. Data Model (`Models.swift`)

### VOCAB — 20 items, 5 categories

```
Fruits:    apple, orange, banana, grape
Animals:   cat, dog, bird, fish
Household: chair, book, cup, lamp
Food:      rice, noodle, egg, tea
Family:    mom, dad, brother, sister
```

Each item: `id`, `hanzi`, `pinyin`, `en`, `cat`, `tone` (Tone enum), `emoji`.

### CATEGORIES — 5 items
Each: `id`, `label`, `tone`.

---

## 7. Screens

### Phase 1 Screens

**SplashView** — orange bg, Sparkles, Mascot(speaking, 170pt), "Mission begins" eyebrow, "Hi, I'm Q" h1, subtitle, "Let's go" ink CTA, "Already have an agent?" ghost link.

**NameView** — cream bg, BackBtn, "Step 1 of 3" eyebrow, h1, orange grain card with Sparkles + text input (orange-soft bg, centred, 18pt heavy) + Mascot at bottom, "Continue" CTA.

**AgeView** — cream bg, BackBtn, "Step 2 of 3" eyebrow, horizontal drag wheel (ages 4–12, 110pt spacing, scale+opacity falloff, bounce snap, edge fade gradient), "I am X years old" label, Mascot, "Continue" CTA.

**IntroView** — cream bg, BackBtn, "Step 3 of 3" eyebrow, 3 tip cards (icon square + title + body, staggered screen-in), "Start my first mission" orange CTA.

**HomeView** — cream bg, greeting header (avatar initial chip + name + "Welcome back", streak chip), DailyRing card, today's mission hero (orange grain, Sparkles, Mascot 70pt, title, hanzi + pinyin hint, 3 star slots, "Start mission" white pill), 2-col stat cards (streak mint, stickers cobalt), recent stickers 4-col grid (if any), 2×2 mission type grid (camera/speak/match/story, toned), TabBar.

**MainTabView** — SwiftUI `TabView` with custom `TabBar` overlaid. 4 NavigationStack tabs.

### Phase 2 Screens

**MissionsHubView** — "Daily Briefing" eyebrow, h1, 4 large mission cards (grain, icon circle, title/subtitle, star row), staggered screen-in per card, TabBar.

**CameraMissionView** — MissionHeader, Eyebrow + h1, dark grain viewport (corner brackets, scan line sweeping 0→100%, ObjectArt fades in, detection bubble top-left), Q word card (Mascot speaking + hanzi/pinyin + speaker button), listen phase (waveform bars + mic button → tap to complete), phase-gated CTAs.

**SpeakMissionView** — MissionHeader (cobalt), 3-word series, toned grain hero card (ObjectArt + hanzi large + pinyin + en), mic card (idle/recording/scoring/result states), animated level bars during recording, score circle (%) with result text, Retry button, next/finish CTA.

**MatchMissionView** — MissionHeader (rose), ink prompt card (hanzi 56pt + pinyin), 2×2 ObjectArt choice grid (toned grain, correct green outline + check badge, wrong orange outline + ×badge on reveal), next CTA.

**StoryMissionView** — reading: toned bg per page, Sparkles, progress bars top, ObjectArt centred, Q narration card (Mascot speaking + text + speaker button), page progress CTAs. Quiz: 3 choices (ObjectArt + hanzi + pinyin/en), correct/wrong reveal, finish CTA.

**CompleteView** — mint bg, Confetti(30), Sparkles, Mascot(celebrating, 170pt), "Mission complete" eyebrow, "Nice one, {name}!" h1, sticker pop-in reveal, 3 star circles (staggered pop-in), "Back home" ink CTA.

### Phase 3 Screens

**LibraryView** — quackYellow grain header (Sparkles, "Your sticker book" eyebrow, "Words I know" h1, ProgressBar + count), horizontal category chip scroll (all/fruits/animals/household/food/family), sticker grid 3-col by category with section headers, TabBar.

**ParentView** — 3-col stat cards (stars today/streak/words, orange/cobalt/mint), week bar chart (7 bars drawn with SwiftUI Rectangles, today=orange, M–S labels), Snap Photo button (ink bg, orange icon, chevron), vocabulary list (Card with rows: hanzi tile + en + pinyin + check), edge-device dark card (pulse dot "Connected"), screentime card (ProgressBar + "Adjust limit"), reset ghost button, TabBar.

**SnapPhotoView** — BackBtn, 3 phases: compose (dark grain viewport, corner brackets, aim instructions), analyzing (dot-bounce loader), result (2×2 tappable word grid, selected=orange). Phase-gated CTAs.

**ProfileView** — (sheet from HomeView avatar) orange grain agent card (Mascot 120pt, "Agent file" eyebrow, name, age+level), 3-col stat cards (streak/words/today), recent stickers 3×2 grid, "See full sticker book" ghost CTA.

---

## 8. File Inventory

### Phase 1 (new/rewritten)
- `Theme.swift` — rewrite
- `Models.swift` — rewrite
- `Components.swift` — new (Eyebrow, Sparkles, CTAButton, BackBtn, ProgressBar, DailyRing, Pill, QuackCard, TabBar, QuackIcon, StickerTile, Confetti)
- `Mascot.swift` — new
- `OnboardingFlow.swift` — new (SplashView, NameView, AgeView, IntroView)
- `HomeView.swift` — rewrite
- `MainTabView.swift` — new
- `AppView.swift` — new
- `Assets.xcassets` — add duck-mascot.png

### Phase 2 (new)
- `MissionsHubView.swift`
- `MissionHeader.swift`
- `CameraMissionView.swift`
- `SpeakMissionView.swift`
- `MatchMissionView.swift`
- `StoryMissionView.swift`
- `CompleteView.swift`
- `ObjectArt.swift`
- `MainTabView.swift` — update (wire missions, fullScreenCover)

### Phase 3 (new)
- `LibraryView.swift`
- `ParentView.swift`
- `SnapPhotoView.swift`
- `ProfileView.swift`

### Deleted
- `ContentView.swift`
- `WelcomeView.swift`
- `HomeView.swift` (old, before rewrite)
- `LessonView.swift`
- `CelebrationView.swift`
- `DuckView.swift`

### Kept
- `quackApp.swift`
- `Assets.xcassets` (extended)
- `quack.xcodeproj`
- `quackTests/`, `quackUITests/`

---

## 9. Out of Scope

- Real camera (AVFoundation) — simulated
- Real microphone / speech recognition — simulated  
- Push notifications
- Backend / server sync
- Dark mode (reference supports it; not porting to SwiftUI for now)
- Landscape mode (reference supports it; not porting)
- iCloud sync

---

## 10. Success Criteria

- All 15 screens render on iPhone 15 Pro simulator without crashes
- Onboarding completes and sets `hasOnboarded = true`, never shown again
- Full mission loop: pick mission → play → complete → sticker added to `learned[]` → appears in Library
- Parent dashboard shows correct streak, word count, week chart
- Mascot animates correctly in all 4 states
- Tab bar navigates between all 4 main sections
- Profile sheet opens from Home header avatar tap
- All colour tokens match reference hex values
- All text uses SF Rounded for display roles
