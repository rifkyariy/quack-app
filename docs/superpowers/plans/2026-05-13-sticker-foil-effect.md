# Sticker Foil Effect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a looping holographic foil effect to every `StickerTile` using the `bpisano/Sticker` Metal shader package so all tiles shimmer idly without user interaction.

**Architecture:** A custom `LoopingStickerMotionEffect: StickerMotionEffect` drives a sine/cosine sweep through `StickerShaderUpdater` on every animation frame via `TimelineView(.animation)`. The modifier is applied to the existing `StickerTile` ZStack with two new chained modifiers. Shader pre-compilation is added in the app `init()` to prevent first-render stutter.

**Tech Stack:** Swift 5.0, SwiftUI, iOS 18.5, `bpisano/Sticker` (Metal shaders, SPM)

---

## File Map

| File | Change |
|------|--------|
| `quack/Components.swift` | Add `import Sticker`, add `LoopingStickerMotionEffect` struct (new MARK section), add 2 modifiers to `StickerTile` ZStack |
| `quack/quackApp.swift` | Add `init()` calling `ShaderLibrary.compileStickerShaders()` |
| Xcode project | Add SPM dependency (manual step — Task 1) |

---

### Task 1: Add SPM Package (Manual Xcode Step)

**Files:**
- Modify: `quack.xcodeproj` (via Xcode UI)

- [ ] **Step 1: Open Xcode package dependencies**

In Xcode: File → Add Package Dependencies…

- [ ] **Step 2: Add the package**

Paste URL: `https://github.com/bpisano/Sticker`

Click **Add Package**. When prompted for target, select the `quack` target. Click **Add Package** again.

- [ ] **Step 3: Verify build**

Run: `xcodebuild -scheme quack -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

If build fails with "no such module 'Sticker'", the package was not added to the target — re-do Step 2 and ensure the `quack` target checkbox is checked.

---

### Task 2: Add `LoopingStickerMotionEffect`

**Files:**
- Modify: `quack/Components.swift` (add after line 534 — the `// MARK: - StickerTile` comment, insert new MARK section just before it)

- [ ] **Step 1: Add import at top of Components.swift**

In `quack/Components.swift` line 1, change:

```swift
import SwiftUI
```

to:

```swift
import SwiftUI
import Sticker
```

- [ ] **Step 2: Add LoopingStickerMotionEffect struct**

In `quack/Components.swift`, insert the following block immediately before the `// MARK: - StickerTile` comment (currently at line 536):

```swift
// MARK: - LoopingStickerMotionEffect

struct LoopingStickerMotionEffect: StickerMotionEffect {
    var speed: Double = 0.4
    var radius: Double = 0.5

    @Environment(\.stickerShaderUpdater) private var shaderUpdater
    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            content
                .onGeometryChange(for: CGSize.self, of: { $0.size }) { _, newSize in
                    size = newSize
                }
                .onChange(of: timeline.date) { _, date in
                    let t = date.timeIntervalSinceReferenceDate
                    let x = sin(t * speed) * radius * size.width / 2
                    let y = cos(t * speed * 0.7) * radius * size.height / 2
                    shaderUpdater.update(with: .init(x: x, y: y))
                }
        }
        .onDisappear {
            shaderUpdater.setNeutral()
        }
    }
}

```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -scheme quack -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

If you see "type 'LoopingStickerMotionEffect' does not conform to protocol 'StickerMotionEffect'", check that the `body(content:)` signature exactly matches `func body(content: Content) -> some View`.

- [ ] **Step 4: Commit**

```bash
git add quack/Components.swift
git commit -m "feat: add LoopingStickerMotionEffect for idle foil shimmer"
```

---

### Task 3: Apply Foil Effect to StickerTile

**Files:**
- Modify: `quack/Components.swift` — `StickerTile.body`, the ZStack modifier chain (currently around line 592–596)

- [ ] **Step 1: Add foil modifiers to StickerTile ZStack**

In `quack/Components.swift`, find this block inside `StickerTile.body` (around line 592):

```swift
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .cardShadow()
```

Replace with:

```swift
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .stickerEffect()
            .stickerMotionEffect(LoopingStickerMotionEffect())
            .cardShadow()
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -scheme quack -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Test on device**

Metal shaders do not render in Simulator. Run on a physical iPhone (iOS 18+).

Verify:
- All unlocked tiles show a slow looping rainbow shimmer
- Locked tiles also shimmer (grey fill mutes rainbow naturally)
- The `justEarned` spring-pop animation still plays on top of the foil with no visual conflict
- Scrolling a tile grid (e.g. LibraryView) shows no jank

- [ ] **Step 4: Commit**

```bash
git add quack/Components.swift
git commit -m "feat: apply holographic foil effect to StickerTile"
```

---

### Task 4: Shader Pre-compilation in App Init

**Files:**
- Modify: `quack/quackApp.swift`

- [ ] **Step 1: Add init() to quackApp**

Current `quack/quackApp.swift`:

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

Replace with:

```swift
import SwiftUI
import Sticker

@main
struct quackApp: App {
    @State private var appState = AppState()

    init() {
        ShaderLibrary.compileStickerShaders()
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -scheme quack -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Test on device — first launch**

Cold-launch the app on device. The first tile grid should show the foil immediately with no stutter or black-flash on the tiles. If there is still a brief stutter, it is acceptable — `compileStickerShaders()` is a best-effort optimization.

- [ ] **Step 4: Commit**

```bash
git add quack/quackApp.swift
git commit -m "perf: pre-compile Sticker Metal shaders on app launch"
```
