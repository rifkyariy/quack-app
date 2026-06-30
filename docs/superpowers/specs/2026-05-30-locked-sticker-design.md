# Locked Sticker Visual Design
**Date:** 2026-05-30  
**Feature:** Enhance locked sticker appearance to feel "excited to be collected"

---

## Overview

Currently, locked stickers in the sticker book show only a plain gray background with a lock icon. This update makes them visually appealing and exciting while maintaining the locked state, so players feel motivated to collect them.

**Design Approach:** Hint + Flair — hybrid approach combining a subtle content preview with animated visual flourishes.

---

## Visual Design

### Locked Sticker Appearance

**Colors & Styling:**
- Background: Warm gradient matching the sticker's unlocked color palette
  - Same as unlocked stickers (e.g., golden orange for words, not gray)
  - Creates visual continuity and suggests the reward inside
- Hanzi character: Very faint (20% opacity), centered
  - Visible enough to identify the character
  - Subtle enough to preserve surprise/mystery
- Lock icon: Standard lock emoji (🔒), prominently displayed
- Border: Dashed border with soft orange tone, pulses rhythmically

### Animations

**1. Pulsing Border**
- Animation: Dashed border scales and fades (0.95 → 1.05 scale, 0.3 → 0.6 opacity)
- Duration: 1.5 seconds, easing in/out
- Effect: Creates a "breathing" feeling, draws attention to the locked sticker
- Staggered across grid: Each sticker can pulse with slight delays for visual rhythm

**2. 3D Motion Effect**
- Existing `LoopingStickerMotionEffect` continues to apply
- Gentle rotation on X and Y axes creates depth
- Makes sticker feel "alive" and interactive despite being locked

**Combined Effect:**
The locked sticker feels special and worth pursuing—not boring or inaccessible. The subtle hanzi gives a clear sense of the reward, while the animations and gradient colors match the overall app aesthetic.

---

## Technical Implementation

### Component Changes: `StickerTile`

**Current Behavior (locked = true):**
```
- Gray background (Color.inkFaint)
- Lock icon only
- No content preview
```

**New Behavior (locked = true):**
```
- Warm gradient background (matching sticker's tone colors)
- Hanzi at 20% opacity, centered
- Lock icon on top of hanzi
- Dashed border with pulsing animation
- Existing LoopingStickerMotionEffect still applies
```

### Animation Implementation

**Pulsing Border:**
- Option A: Use Canvas with animated dashed stroke + timeline
- Option B: Use `stickerEffect()` modifier (existing) + add border pulse as separate modifier
- Option C: CSS-like animation via StateManager + manual recalculation

**Recommendation:** Extend existing modifier pattern or add new `PulsingBorderEffect` modifier for consistency.

### Key Files to Modify

- `Components.swift` — `StickerTile` struct
  - Add pulsing border modifier when locked
  - Show faded hanzi alongside lock icon
  - Change background from gray to color gradient

---

## User Experience

### Motivation Flows

**Unlocked Stickers:**
- Full color, clear content, vibrant
- Player feels ownership/pride

**Locked Stickers:**
- Warm colors suggest value inside
- Faint hanzi shows what you're earning
- Animations make it feel alive, special
- Lock icon reminds you it's not yet earned
- **Result:** Player feels motivated to complete the mission/challenge to unlock

### Interaction

- Locked stickers remain un-tappable (disabled state)
- No tap action, no popover
- Visual-only excitement
- Matches current behavior; only appearance changes

---

## Acceptance Criteria

- [ ] Locked stickers show warm gradient background (not gray)
- [ ] Hanzi visible at 20% opacity
- [ ] Lock icon visible and clear
- [ ] Dashed border pulses smoothly (1.5s cycle)
- [ ] 3D motion effect still applies
- [ ] Animation is smooth across all sticker grid positions
- [ ] Staggered animation timing creates pleasing visual rhythm
- [ ] Locked stickers remain un-tappable
- [ ] Works at all sticker sizes (sm, md, lg)
- [ ] Visual style matches quack app aesthetic

---

## Design Rationale

**Why gradient instead of gray?**
- Gray feels inactive, like "don't bother"
- Warm gradient signals value and reward
- Matches unlocked sticker palette, creating visual continuity

**Why 20% opacity hanzi?**
- Balances hint with mystery
- Clear enough to identify the word
- Subtle enough to not overshadow the lock

**Why pulsing border?**
- Adds visual life without overwhelming
- Draws attention in the grid
- Suggests interactivity (even though locked)
- Works well with existing motion effect

**Why keep 3D motion?**
- Maintains consistency across all stickers
- Adds polish and personality
- Makes locked stickers feel "ready to unlock" rather than "permanently unavailable"

---

## Open Questions

None. Design is approved and ready for implementation.
