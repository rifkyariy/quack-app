# Onboarding Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance OnboardingFlow with swipe navigation, progress indicators, asymmetric transitions, and a new SetupView for permission requests.

**Architecture:** Refactor OnboardingFlow to be a coordinator managing 4 steps with a progress bar at top and unified swipe gesture handling. Add direction-aware asymmetric transitions. Create new SetupView for camera & microphone permission requests. Enhance existing views with entry animations.

**Tech Stack:** SwiftUI (ZStack, DragGesture, TimelineView for animations), UIKit (haptic feedback), Async/await for permissions

---

## File Structure

**Modified Files:**
- `quack/OnboardingFlow.swift` — Main coordinator, progress bar, gesture handling, step transitions

**New Files:**
- `quack/SetupView.swift` — Step 4: camera & microphone permission requests with loading states

---

## Task 1: Add Progress Bar Component to OnboardingFlow

**Files:**
- Modify: `quack/OnboardingFlow.swift` (add progress bar view and state)

- [ ] **Step 1: Add progress bar to OnboardingFlow body**

In `OnboardingFlow.swift`, add this progress bar computed property right after the `body` property begins:

```swift
private var progressBar: some View {
    HStack(spacing: 8) {
        ForEach(0..<4, id: \.self) { idx in
            Capsule()
                .fill(idx <= currentStep.rawValue ? Color.quackOrange : Color.quackOrange.opacity(0.25))
                .frame(width: idx == currentStep.rawValue ? 28 : 8, height: 6)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
        }
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
}
```

- [ ] **Step 2: Update OnboardingFlow Step enum to have rawValue**

Change the Step enum to:
```swift
enum Step: Int { case splash = 0, name = 1, age = 2, intro = 3, setup = 4 }
```

This allows the progress bar to use `currentStep.rawValue` for comparisons.

- [ ] **Step 3: Add progress bar to the body above step container**

In the OnboardingFlow body, add the progress bar right after the ZStack opening and before the step container:

```swift
var body: some View {
    Group {
        switch currentStep {
        case .splash:
            SplashView(onNext: { advance() })
        case .name:
            VStack(spacing: 0) {
                progressBar  // Add here
                
                ZStack {
                    NameView(initial: appState.name, onBack: retreat, onNext: { name in
                        appState.name = name
                        advance()
                    })
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(currentStep)
                .transition(asymmetricTransition)
            }
        // ... repeat for age, intro, setup
        }
    }
    .transition(.screenIn)
    .animation(.easeOut(duration: 0.32), value: currentStep)
}
```

- [ ] **Step 4: Verify OnboardingFlow compiles**

Check Xcode for no errors on OnboardingFlow.swift.

---

## Task 2: Add Swipe Gesture Handling & Direction Tracking

**Files:**
- Modify: `quack/OnboardingFlow.swift` (add slide direction, gesture handling)

- [ ] **Step 1: Add slideDirection and entry animation state**

In OnboardingFlow, add these state variables:

```swift
struct OnboardingFlow: View {
    let onComplete: () -> Void
    @Environment(AppState.self) private var appState

    enum Step: Int { case splash = 0, name = 1, age = 2, intro = 3, setup = 4 }
    @State private var currentStep: Step = .splash
    @State private var slideDirection: CGFloat = 1  // 1 = forward, -1 = back
    @State private var flowVisible: Bool = false    // For entry animation
```

- [ ] **Step 2: Add asymmetric transition computed property**

Add this property to OnboardingFlow:

```swift
private var asymmetricTransition: AnyTransition {
    .asymmetric(
        insertion: .move(edge: slideDirection > 0 ? .trailing : .leading)
            .combined(with: .opacity),
        removal: .move(edge: slideDirection > 0 ? .leading : .trailing)
            .combined(with: .opacity)
    )
}
```

- [ ] **Step 3: Add swipe gesture to the root Group**

Wrap the Group in the body with a gesture modifier. Add this after the Group closing brace:

```swift
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
                if currentStep == .name,
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
```

- [ ] **Step 4: Add entry animation**

In the body, wrap the Group like this:

```swift
Group {
    // ... existing switch
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
```

- [ ] **Step 5: Add advance() and retreat() helper methods**

Add to OnboardingFlow:

```swift
private func advance() {
    if currentStep.rawValue < 4 {
        currentStep = Step(rawValue: currentStep.rawValue + 1) ?? .setup
    }
}

private func retreat() {
    if currentStep.rawValue > 1 {
        currentStep = Step(rawValue: currentStep.rawValue - 1) ?? .name
    }
}
```

- [ ] **Step 6: Verify gesture handling compiles**

Check Xcode for no errors on the updated OnboardingFlow.

---

## Task 3: Update Existing Views with Entry Animations

**Files:**
- Modify: `quack/OnboardingFlow.swift` (enhance NameView, AgeView, IntroView)

- [ ] **Step 1: Add state and animation to NameView**

In NameView, add this state at the top:

```swift
@State private var appeared = false
```

Wrap the header VStack with:

```swift
VStack(alignment: .leading, spacing: 14) {
    // ... existing content
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 24)
.padding(.top, 24)
.offset(y: appeared ? 0 : 16)
.opacity(appeared ? 1 : 0)
.animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)
.onAppear { appeared = true }
```

Do the same for the text field section and button section with appropriate delays.

- [ ] **Step 2: Add state and animation to AgeView**

In AgeView, add:

```swift
@State private var appeared = false
```

Wrap the header with offset/opacity animation like NameView.

- [ ] **Step 3: Add state and animation to IntroView**

In IntroView, add:

```swift
@State private var appeared = false
```

Wrap the header with offset/opacity animation.

- [ ] **Step 4: Verify animations compile**

Check Xcode for no errors on all three views.

---

## Task 4: Create SetupView for Permission Requests

**Files:**
- Create: `quack/SetupView.swift`

- [ ] **Step 1: Create SetupView file with basic structure**

Create new file `quack/SetupView.swift`:

```swift
import SwiftUI
import AVFoundation

struct SetupView: View {
    let onNext: () -> Void
    @Environment(AppState.self) private var appState
    
    @State private var appeared = false
    @State private var cameraPermissionState: PermissionState = .waiting
    @State private var micPermissionState: PermissionState = .waiting
    
    enum PermissionState { case waiting, active, done }
    
    var body: some View {
        ZStack {
            Color.quackOrange.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting Q ready")
                        .font(.display(32, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("We'll ask for a few things")
                        .font(.bodyText(15))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)
                
                Spacer(minLength: 20)
                
                // Setup steps
                VStack(spacing: 12) {
                    SetupStepRow(
                        icon: "camera.fill",
                        title: "Camera access",
                        subtitle: "For pointing at things",
                        state: cameraPermissionState
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.06), value: appeared)
                    
                    SetupStepRow(
                        icon: "mic.fill",
                        title: "Microphone access",
                        subtitle: "For saying words aloud",
                        state: micPermissionState
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.12), value: appeared)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Button
                CTAButton(
                    label: "Enter the app",
                    variant: .ink,
                    disabled: cameraPermissionState != .done || micPermissionState != .done,
                    action: onNext
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
            Task { await runSetupSequence() }
        }
    }
    
    private func runSetupSequence() async {
        // Camera
        withAnimation { cameraPermissionState = .active }
        let cameraGranted = await requestCameraPermission()
        if cameraGranted {
            withAnimation { cameraPermissionState = .done }
        }
        
        // Microphone
        withAnimation { micPermissionState = .active }
        let micGranted = await requestMicrophonePermission()
        if micGranted {
            withAnimation { micPermissionState = .done }
        }
    }
    
    private func requestCameraPermission() async -> Bool {
        // Implementation will request actual camera permission
        return true
    }
    
    private func requestMicrophonePermission() async -> Bool {
        // Implementation will request actual mic permission
        return true
    }
}

// MARK: - Setup Step Row

private struct SetupStepRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let state: SetupView.PermissionState
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 40, height: 40)
                
                if state == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                } else if state == .active {
                    ProgressView()
                        .tint(.white.opacity(0.7))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(state == .waiting ? 0.05 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private var circleColor: Color {
        switch state {
        case .waiting: return .white.opacity(0.15)
        case .active: return .white.opacity(0.2)
        case .done: return .white
        }
    }
}

#Preview {
    SetupView(onNext: {})
        .environment(AppState())
}
```

- [ ] **Step 2: Verify SetupView compiles**

Check Xcode for no errors on the new file.

---

## Task 5: Wire SetupView into OnboardingFlow

**Files:**
- Modify: `quack/OnboardingFlow.swift` (add setup case to switch statement)

- [ ] **Step 1: Add setup case to the switch in OnboardingFlow body**

In the switch statement in OnboardingFlow body, add:

```swift
case .setup:
    VStack(spacing: 0) {
        progressBar
        
        ZStack {
            SetupView(onNext: onComplete)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(currentStep)
        .transition(asymmetricTransition)
    }
```

- [ ] **Step 2: Verify setup case compiles**

Check Xcode for no errors.

---

## Task 6: Implement Actual Permission Requests in SetupView

**Files:**
- Modify: `quack/SetupView.swift` (implement permission logic)

- [ ] **Step 1: Import required frameworks**

At the top of SetupView.swift, add:

```swift
import UIKit
```

- [ ] **Step 2: Implement requestCameraPermission()**

Replace the stub with:

```swift
private func requestCameraPermission() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    switch status {
    case .authorized:
        return true
    case .denied, .restricted:
        return false
    case .notDetermined:
        return await AVCaptureDevice.requestAccess(for: .video)
    @unknown default:
        return false
    }
}
```

- [ ] **Step 3: Implement requestMicrophonePermission()**

Replace the stub with:

```swift
private func requestMicrophonePermission() async -> Bool {
    let status = AVAudioApplication.shared.recordPermission
    
    switch status {
    case .granted:
        return true
    case .denied:
        return false
    case .undetermined:
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    @unknown default:
        return false
    }
}
```

- [ ] **Step 4: Verify permission implementations compile**

Check Xcode for no errors.

---

## Task 7: Visual Test in Simulator

**Files:**
- No file changes; testing only

- [ ] **Step 1: Build and run the app in simulator**

Run the app and tap through to the onboarding.

- [ ] **Step 2: Verify splash screen**

Check:
- ✓ Splash appears with no progress bar
- ✓ Progress bar not visible on splash
- ✓ Can tap "Let's go" to advance

- [ ] **Step 3: Verify progress bar and transitions**

At name step:
- ✓ Progress bar shows 4 pills, first one expanded/orange
- ✓ Remaining pills are faded
- ✓ Swipe left → slides to age step smoothly
- ✓ Progress bar pill 1 becomes pill-sized, pill 2 expands
- ✓ Swipe right → slides back to name smoothly

- [ ] **Step 4: Verify name validation**

At name step with empty name:
- ✓ Try swiping left with empty name
- ✓ Should see error haptic and no transition
- ✓ Field doesn't shake visibly (optional enhancement)

- [ ] **Step 5: Verify setup state**

Navigate to step 4:
- ✓ Progress bar shows all 4 pills filled/expanded
- ✓ Setup header appears with animation
- ✓ Camera and mic rows appear with staggered delays
- ✓ "Enter the app" button is disabled initially
- ✓ Tapping camera permission works
- ✓ Camera row shows loading spinner, then checkmark
- ✓ Mic row activates, shows loading, then checkmark
- ✓ Button becomes enabled when both are done
- ✓ Tapping button completes onboarding

- [ ] **Step 6: Verify haptic feedback**

- ✓ Light haptic when swiping left (advance)
- ✓ Medium haptic when swiping right (back)
- ✓ Error haptic when trying to advance with empty name

---

## Task 8: Commit All Changes

**Files:**
- Modified: `quack/OnboardingFlow.swift`
- Created: `quack/SetupView.swift`

- [ ] **Step 1: Stage all changes**

```bash
git add quack/OnboardingFlow.swift quack/SetupView.swift
```

- [ ] **Step 2: Commit with detailed message**

```bash
git commit -m "feat: redesign onboarding with swipe navigation and progress bar

Add horizontal swipe gesture navigation (left=advance, right=back) with:
- Progress bar showing 4 steps as capsule pills
- Asymmetric slide transitions based on swipe direction
- Spring animations (0.45s response, 0.75 damping)
- Entry animation on initial load (slide up + fade)
- Direction-aware haptic feedback (light/medium/error)

New SetupView (step 4) requests permissions sequentially:
- Camera access ('Point at things' mission)
- Microphone access ('Say it back' mission)
- Loading states with checkmarks when granted
- Button enables only when all permissions done

Enhanced existing views (name, age, intro) with:
- Entry animations (offset + opacity)
- Staggered animation delays for visual polish

Adapts horizon.swiftpm patterns to quack's playful aesthetic.

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>"
```

- [ ] **Step 3: Verify commit**

```bash
git log --oneline -1
```

Expected: Shows the commit with message about onboarding redesign.

---

## Plan Summary

**8 tasks, ~3-4 hours total:**
1. Add progress bar component — 15 min
2. Add swipe gesture handling & direction tracking — 30 min
3. Update existing views with entry animations — 20 min
4. Create SetupView for permissions — 45 min
5. Wire SetupView into OnboardingFlow — 10 min
6. Implement actual permission requests — 20 min
7. Visual test in simulator — 30 min
8. Commit — 5 min

**Success criteria:** All 4 steps visible with progress bar, swipe navigation works, asymmetric transitions smooth, setup requests permissions, haptic feedback present.
