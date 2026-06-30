# Onboarding Redesign: Swipe Navigation & Progress Indicators

**Date:** 2026-05-30  
**Feature:** Enhance onboarding flow with horizontal swipe navigation, progress bar, and asymmetric transitions

---

## Overview

Redesign the 4-step onboarding flow to match the horizon.swiftpm interaction patterns while maintaining quack's playful, colorful aesthetic. Add a progress indicator, directional swipe navigation, smooth spring animations, and a setup/loading state for permission requests.

**Current flow:** Splash (separate) → Name → Age → Intro → Complete  
**Enhanced flow:** Splash (separate) → Name → Age → Intro → Setup (permissions) → Complete

---

## Visual Design

### Progress Indicator (Top Bar)
- **Position:** Below status bar, 16pt padding from top
- **Style:** Horizontal HStack of 4 capsule pills
  - **Completed steps:** `Color.quackOrange` full opacity
  - **Current step:** `Color.quackOrange` with expanded width (28pt vs 8pt)
  - **Pending steps:** `Color.quackOrange.opacity(0.25)`
- **Animation:** Spring animation on step change
  - Response: `0.4`, Damping: `0.7`
  - Smoothly transitions width and opacity

### Step Views (1-4)

#### Step 1: Name Entry
- Existing NameView, enhanced with entry animation
- Can advance: Only if name is non-empty
- Can retreat: No (first step)

#### Step 2: Age Selection
- Existing AgeView, enhanced with entry animation
- Can advance: Always (age has default)
- Can retreat: Back to Name

#### Step 3: How It Works (Intro)
- Existing IntroView, enhanced with entry animation
- Can advance: Always
- Can retreat: Back to Age

#### Step 4: Setup/Loading (NEW)
- **Header:** "Getting Q ready" title + "We'll ask for a few things" subtitle
- **Setup sequence:** Sequential permission requests
  - Camera access ("For pointing at things")
  - Microphone access ("For saying words aloud")
- **Step states:** Waiting → Active (spinner) → Done (checkmark)
- **Visual style:** Matches quack card design, uses quack colors
- **Bottom action:** "Enter the app" button (disabled until all steps complete)
- **Animation sequence:**
  1. View enters with spring animation (slide up + fade)
  2. Setup steps fade in with staggered delays (0.06s between each)
  3. Camera step activates, shows loading spinner, requests permission
  4. Once granted, shows checkmark and moves to next step
  5. Microphone step activates, shows loading spinner, requests permission
  6. Once both granted, button becomes enabled
  7. Button press calls `onComplete` callback

---

## Animations & Interactions

### Entry Animation (Onboarding First Load)
- **Trigger:** When OnboardingFlow appears
- **Effect:** Full container slides up + fades in
  - Y offset: `48` → `0`
  - Opacity: `0` → `1`
  - Spring: `response: 0.55, dampingFraction: 0.82`
  - Delay: `0.2s` before animation starts

### Step Transitions (Between Steps)
- **Asymmetric slide transitions:**
  - Advancing (left swipe): Exit slides left + fade, new view slides in from right
  - Retreating (right swipe): Exit slides right + fade, new view slides in from left
  - Spring: `response: 0.45, dampingFraction: 0.75`
- **Implementation:** Use ZStack with `.id(currentStep)` to force view replacement, apply asymmetric `.transition()`

### Swipe Gesture Handling
- **Location:** Root container (OnboardingFlow)
- **Gesture type:** `DragGesture` with minimumDistance 20pt
- **Detection logic:**
  - Calculate `dx` (width) and `dy` (height) translations
  - Require: `abs(dx) > abs(dy) * 2` (2× horizontal bias)
  - Require: `abs(dx) > 50` (minimum 50pt translation)
- **Actions:**
  - Left swipe (`dx < 0`): Advance to next step (if valid)
  - Right swipe (`dx > 0`): Retreat to previous step (if allowed)
- **Validation:**
  - Step 1 (Name): Block advance if name is empty (shake + error haptic)
  - Can't go before step 1 or after step 4
- **Keyboard handling:** Dismiss keyboard before transitioning via `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), ...)`

### Progress Bar Animation
- **Trigger:** When `currentStep` changes
- **Effect:** Current pill expands, fill colors update
- **Spring:** `response: 0.4, dampingFraction: 0.7`
- **Persistence:** Visible throughout steps 1-4 (splash is separate)

### Haptic Feedback
- **Valid advance:** Light impact (`UIImpactFeedbackGenerator(style: .light)`)
- **Valid retreat:** Medium impact (`UIImpactFeedbackGenerator(style: .medium)`)
- **Invalid action:** Error notification (`UINotificationFeedbackGenerator().notificationOccurred(.error)`)
- **Setup completion:** Success notification when all permissions granted

---

## Technical Architecture

### State Management
- **OnboardingFlow:** Coordinator view managing current step via enum
  - `currentStep: Step` (splash, name, age, intro, setup)
  - `slideDirection: CGFloat` (1 = forward, -1 = back)
  - `currentStep` drives all transitions and progress indicator

### Components
- **SplashView:** Standalone, no progress bar, special entry animation
- **NameView:** Enhanced with entry offset/opacity animation
- **AgeView:** Enhanced with entry offset/opacity animation
- **IntroView:** Enhanced with entry offset/opacity animation
- **SetupView:** NEW - loading state with sequential permission requests

### Gesture & Navigation
- Root ZStack applies `DragGesture` to all steps
- Gesture handlers validate transitions and update `currentStep`
- View replacement via ZStack with `.id()` forces transition application

---

## Data & State Flow

### User Input → State Change → Visual Update
1. User swipes left/right
2. Gesture handler validates and updates `currentStep`
3. ZStack detects `.id()` change and applies transition
4. Progress bar animates to reflect new step
5. New step view enters with animation

### Setup Flow
1. User advances to step 4
2. SetupView loads, shows 2 setup step rows
3. Camera step auto-activates, spinner shows
4. Request permission → user grants/denies
5. Update step state → spinner → checkmark
6. Microphone step auto-activates
7. Repeat permission flow
8. Button enables when all done

---

## Acceptance Criteria

- [ ] Progress bar shows 4 capsules at top of screen
- [ ] Progress bar updates smoothly on step change (spring animation)
- [ ] Horizontal swipe gestures work (left = advance, right = back)
- [ ] Swipe requires 20pt min distance and 2× horizontal bias
- [ ] Asymmetric transitions: advance from right, retreat from left
- [ ] Name validation: can't advance with empty name (shake effect)
- [ ] Setup state shows camera & mic permission rows
- [ ] Setup requests permissions sequentially with loading states
- [ ] Button in setup only enables after both permissions granted
- [ ] Haptic feedback on swipe (light/medium/error)
- [ ] Entry animation on first load (slide up + fade)
- [ ] All animations use spring timing (not linear)
- [ ] Keyboard dismisses before transitioning
- [ ] Splash screen remains separate (no progress bar)

---

## Design Rationale

**Why progress bar with all 4 steps visible?**
- Shows users their position and remaining steps
- Creates sense of progress through onboarding
- Matches horizon pattern which users expect

**Why asymmetric transitions?**
- Direction-aware feedback (visual reinforcement of navigation direction)
- More intuitive than uniform transitions
- Matches horizon design and modern app patterns

**Why spring animations?**
- Feels playful and responsive, matches quack's personality
- Smoother than linear animations
- Standard for modern iOS interactions

**Why setup as step 4?**
- Keeps permissions grouped together
- Users understand all setup happens in one place
- Natural transition point before entering app

---

## Open Questions

None. Design is approved and ready for implementation.
