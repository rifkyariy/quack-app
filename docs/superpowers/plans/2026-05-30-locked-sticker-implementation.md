# Locked Sticker Visual Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance locked stickers with a "hint + flair" design showing faded hanzi, warm gradient background, and animated pulsing border.

**Architecture:** Extend the `StickerTile` component with a new `PulsingBorderEffect` modifier. When `locked == true`, display a warm gradient background matching the sticker's tone colors, overlay the hanzi at 20% opacity, show the lock icon, and apply the pulsing border animation. Retain the existing 3D motion effect for consistency.

**Tech Stack:** SwiftUI (Canvas for border animation), TimelineView for animation timing

---

## File Structure

**Modified Files:**
- `quack/Components.swift` — Contains `StickerTile` component and new `PulsingBorderEffect` modifier

**No new files needed** — all changes are additive to the existing `StickerTile` component.

---

## Task 1: Create PulsingBorderEffect Modifier

**Files:**
- Modify: `quack/Components.swift` (add new modifier before `StickerTile`)

- [ ] **Step 1: Add PulsingBorderEffect modifier**

Add this new modifier right before the `LoopingStickerMotionEffect` modifier definition (around line 565):

```swift
// MARK: - PulsingBorderEffect
struct PulsingBorderEffect: ViewModifier {
    @State private var pulse = false
    
    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let progress = (t.truncatingRemainder(dividingBy: 1.5)) / 1.5
            let scale = 0.95 + (sin(progress * .pi * 2) + 1) / 4 * 0.1
            let opacity = 0.3 + (sin(progress * .pi * 2) + 1) / 2 * 0.3
            
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: [4, 4]
                            )
                        )
                        .foregroundStyle(Color.quackOrange.opacity(opacity))
                        .scaleEffect(scale)
                )
        }
    }
}
```

- [ ] **Step 2: Verify syntax by checking the file compiles**

Just check that Xcode shows no errors on Components.swift. Don't run the full app yet.

---

## Task 2: Update StickerTile for Locked State

**Files:**
- Modify: `quack/Components.swift:580-654` (the `StickerTile` struct body)

- [ ] **Step 1: Update the ZStack background logic**

In the `StickerTile` body, find the ZStack that starts around line 601. Replace the background fill logic:

**Find this:**
```swift
RoundedRectangle(cornerRadius: 22)
    .fill(locked ? Color.inkFaint : item.tone.bg)
```

**Replace with:**
```swift
RoundedRectangle(cornerRadius: 22)
    .fill(locked ? item.tone.bg : item.tone.bg)
```

(Yes, both branches now use `item.tone.bg` — locked stickers get the warm gradient too)

- [ ] **Step 2: Update the locked sticker content**

Find the conditional block that displays lock vs. hanzi (around line 621-631). Replace it:

**Find this:**
```swift
VStack(spacing: 4) {
    if locked {
        QuackIcon(name: .lock, size: 28, color: .inkMuted, strokeWidth: 1.8)
    } else {
        Text(item.hanzi)
            .font(.display(hanziSize, weight: .heavy))
            .foregroundStyle(item.tone.fg)
        Text(item.pinyin)
            .font(.bodyText(10, weight: .bold))
            .foregroundStyle(item.tone.fg.opacity(0.9))
    }
}
```

**Replace with:**
```swift
ZStack {
    // Faded hanzi in background (locked only)
    if locked {
        Text(item.hanzi)
            .font(.display(hanziSize, weight: .heavy))
            .foregroundStyle(item.tone.fg.opacity(0.2))
    }
    
    // Lock icon on top
    VStack(spacing: 4) {
        if locked {
            QuackIcon(name: .lock, size: 28, color: .inkMuted, strokeWidth: 1.8)
        } else {
            Text(item.hanzi)
                .font(.display(hanziSize, weight: .heavy))
                .foregroundStyle(item.tone.fg)
            Text(item.pinyin)
                .font(.bodyText(10, weight: .bold))
                .foregroundStyle(item.tone.fg.opacity(0.9))
        }
    }
}
```

- [ ] **Step 3: Add pulsing border modifier to locked stickers**

Find the `.modifier(LoopingStickerMotionEffect())` line (around line 637). Add the pulsing border modifier right after it:

**Find this:**
```swift
.modifier(LoopingStickerMotionEffect())
.cardShadow()
```

**Replace with:**
```swift
.modifier(LoopingStickerMotionEffect())
.modifier(PulsingBorderEffect())
.cardShadow()
```

The pulsing border will only be visually relevant on locked stickers (will render but be subtle on unlocked ones), so it's safe to apply to all stickers. If you want to optimize, you can wrap it in `if locked { }`, but it's not necessary.

- [ ] **Step 4: Verify the file compiles**

Check that Xcode shows no errors on Components.swift after these changes.

---

## Task 3: Visual Test in App

**Files:**
- No file changes; testing only

- [ ] **Step 1: Run the app and navigate to Library tab**

Open the app in the simulator/device and tap the "Stickers" (Library) tab.

- [ ] **Step 2: Inspect locked stickers**

Look at the locked stickers in the grid. Verify:
- ✓ Background is warm (matching unlocked sticker colors, not gray)
- ✓ Hanzi is very faint (barely visible, ~20% opacity)
- ✓ Lock icon is clear and centered
- ✓ Border pulses smoothly (expands/contracts every ~1.5 seconds)
- ✓ 3D motion effect still works (gentle rotation)

- [ ] **Step 3: Compare locked vs. unlocked**

Scroll to see both locked and unlocked stickers of the same category. Verify:
- ✓ Unlocked stickers show full content (hanzi + pinyin, full opacity, no border)
- ✓ Locked stickers show faded hanzi + lock + pulsing border
- ✓ Both have the same gradient background color
- ✓ Visual hierarchy is clear (locked = dimmed preview, unlocked = full content)

- [ ] **Step 4: Test different sticker sizes**

If possible, navigate to screens that show stickers in .sm or .lg sizes (e.g., HomeView shows recent stickers). Verify the design works at all sizes.

---

## Task 4: Commit Changes

**Files:**
- Modified: `quack/Components.swift`

- [ ] **Step 1: Stage the file**

```bash
git add quack/Components.swift
```

- [ ] **Step 2: Commit with message**

```bash
git commit -m "feat: enhance locked stickers with hint + flair design

- Show warm gradient background for locked stickers (matching unlock color)
- Display very faint hanzi (20% opacity) behind lock icon
- Add pulsing dashed border animation (1.5s cycle)
- Retain 3D motion effect for visual polish

Locked stickers now feel exciting and collectible while maintaining
clear locked state.

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>"
```

- [ ] **Step 3: Verify commit**

```bash
git log --oneline -1
```

Expected output: `<hash> feat: enhance locked stickers with hint + flair design`

---

## Plan Summary

**4 tasks, ~20 minutes total:**
1. Add `PulsingBorderEffect` modifier — 2 min
2. Update `StickerTile` locked logic — 5 min
3. Visual test in app — 10 min
4. Commit — 2 min

**Success criteria:** Locked stickers display with warm gradient, faint hanzi, pulsing border, and 3D motion across all views (Library, Home recent stickers, etc.).
