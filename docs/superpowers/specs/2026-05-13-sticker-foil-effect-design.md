# StickerTile Holographic Foil Effect

**Date:** 2026-05-13  
**Status:** Approved

## Goal

Add a looping holographic foil (Pokémon-card shimmer) to every `StickerTile` — locked and unlocked — using the `bpisano/Sticker` Swift package. The effect runs idle with no user interaction, making tiles look tempting to earn.

## Library

**Package:** `https://github.com/bpisano/Sticker`  
**Requires:** iOS 18+  (project targets iOS 18.5 ✓)  
**Mechanism:** Metal shader applied via `.stickerEffect()`. Motion (shimmer position) is driven by a `StickerMotionEffect` conforming type that feeds `StickerTransform(x:y:)` values into `shaderUpdater.update(with:)`.

## Components

### 1. SPM Dependency (manual Xcode step)

Add package `https://github.com/bpisano/Sticker` to the `quack` target in Xcode's Package Dependencies panel.

### 2. `LoopingStickerMotionEffect` — new struct in `Components.swift`

Implements `StickerMotionEffect` (which is `ViewModifier`).

**Behavior:**
- Reads `@Environment(\.stickerShaderUpdater)` — same pattern as the built-in `AccelerometerStickerMotionEffect`
- Tracks view size via `.onGeometryChange(for: CGSize.self)`
- Wraps content in `TimelineView(.animation)` and on each frame computes:
  - `x = sin(t × speed) × radius × width/2`
  - `y = cos(t × speed × 0.7) × radius × height/2`
- Calls `shaderUpdater.update(with: .init(x: x, y: y))` each frame

**Parameters:**
| Param | Default | Effect |
|-------|---------|--------|
| `speed` | `0.4` | Angular velocity; 0.4 ≈ 15 s full cycle |
| `radius` | `0.5` | Sweep amplitude as fraction of half-width |

**Error handling:** None needed — if `shaderUpdater` is the default no-op instance, calls are silently ignored.

### 3. `StickerTile` modification — `Components.swift:555`

Add two modifiers to the `ZStack` after `.aspectRatio(1, contentMode: .fit)`:

```swift
.stickerEffect()
.stickerMotionEffect(LoopingStickerMotionEffect())
```

Chain goes: `.aspectRatio` → `.stickerEffect()` → `.stickerMotionEffect(...)` → `.cardShadow()` → `.scaleEffect` → `.opacity`

### 4. Shader pre-compilation — app entry point

In the `@main` App struct `init()`:

```swift
init() {
    ShaderLibrary.compileStickerShaders()
}
```

Eliminates first-render shader stutter on iOS 18+.

## What Does Not Change

- Locked tile appearance — grey fill naturally mutes the rainbow; no special-casing needed
- `justEarned` spring pop animation — foil composites on top, no conflict
- All three size variants (`sm`/`md`/`lg`) — effect scales with view geometry automatically
- `cardShadow`, `TapPress`, `GrainOverlay` — untouched
- `onTap` / `disabled` logic — untouched

## Files Touched

| File | Change |
|------|--------|
| `quack/Components.swift` | Add `import Sticker`, add `LoopingStickerMotionEffect` struct, add 2 modifiers to `StickerTile` |
| `quack/quackApp.swift` | Add `ShaderLibrary.compileStickerShaders()` in `init()` |
| Xcode project (manual) | Add SPM dependency |

## Testing

- Build and run on device (Metal shaders don't render in Simulator)
- Confirm shimmer loops on locked + unlocked tiles
- Confirm `justEarned` spring animation still plays on top of foil
- Confirm no jank on tile grid scroll (foil runs per-tile on GPU, should be cheap)
