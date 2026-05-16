# Front Camera + Whole-App Landscape Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Switch the Camera Mission to the front camera with rotation-correct preview/capture, and make every screen usable in iPhone landscape.

**Architecture:** Camera changes live in `CameraCapture` (front device + `AVCaptureDevice.RotationCoordinator`). Landscape uses one shared `verticalSizeClass`-driven helper; 5 one-time screens get a scroll safety-net, 6 high-value screens get a designed side-by-side layout. Every screen is already decomposed into computed sub-views, so landscape work mostly recomposes existing pieces.

**Tech Stack:** Swift 6 / SwiftUI, AVFoundation (`RotationCoordinator`, iOS 17+; target is 18.5).

**Spec:** `docs/superpowers/specs/2026-05-16-front-camera-landscape-design.md`

## Notes for the implementer

- **No automated tests.** Verification is a project build after each task + a final on-device rotation pass. Consistent with the rest of this app.
- **Build:** use the `mcp__xcode__BuildProject` MCP tool (the Xcode tab identifier is `windowtab2`; if `ToolSearch` is needed, query `select:mcp__xcode__BuildProject` and `select:mcp__xcode__XcodeListWindows`). Pass condition: `"The project built successfully."` Build for a real device — the camera and the LiteRT static lib are device-oriented.
- **New `.swift` files auto-join the target** via `PBXFileSystemSynchronizedRootGroup` — no `project.pbxproj` edit.
- **SourceKit cross-file "cannot find type" / "unavailable in macOS" diagnostics are stale noise** — the `xcodebuild` result is authoritative.
- `verticalSizeClass == .compact` is true exactly for iPhone-in-landscape; iPad landscape stays `.regular` and is intentionally left on the portrait layouts.
- Commit after every task.

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `quack/AI/CameraCapture.swift` | Camera session, capture, preview layer, rotation | Modify (Tasks 1, 2) |
| `quack/CameraMissionView.swift` | Camera Mission UI | Modify (Tasks 2, 6) |
| `quack/LandscapeSupport.swift` | Shared `scrollableWhenCompact()` helper | Create (Task 3) |
| `quack/OnboardingFlow.swift` | Splash/Name/Age/Intro screens | Modify (Task 4) |
| `quack/CompleteView.swift` | Mission-complete screen | Modify (Task 4) |
| `quack/HomeView.swift` | Home tab | Modify (Task 5) |
| `quack/SpeakMissionView.swift` | Speak Mission UI | Modify (Task 7) |
| `quack/MatchMissionView.swift` | Match Mission UI | Modify (Task 8) |
| `quack/StoryMissionView.swift` | Story Mission UI | Modify (Task 9) |
| `quack/SnapPhotoView.swift` | Snap-photo parent screen | Modify (Task 10) |

---

### Task 1: Front camera

**Files:** Modify `quack/AI/CameraCapture.swift`

- [ ] **Step 1: Select the front camera in `configure()`**

In `quack/AI/CameraCapture.swift`, in `configure()`, change the device-selection `guard`. Replace:

```swift
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)
        else {
            throw CaptureError.unavailable
        }
```

with:

```swift
        // Front camera: the kid holds objects up to the selfie camera. iOS's
        // default selfie behaviour (mirrored preview, true-scene capture) is
        // left as-is — horizontal mirroring does not affect object recognition.
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(for: .video)
        else {
            throw CaptureError.unavailable
        }
```

- [ ] **Step 2: Build**

Build via `mcp__xcode__BuildProject` (tab `windowtab2`). Expected: `"The project built successfully."`

- [ ] **Step 3: Commit**

```bash
git add quack/AI/CameraCapture.swift
git commit -m "feat: use front camera in Camera Mission"
```

---

### Task 2: Rotation-correct camera preview & capture

**Files:**
- Modify `quack/AI/CameraCapture.swift`
- Modify `quack/CameraMissionView.swift`

`CameraCapture` will own the `AVCaptureVideoPreviewLayer` and use an `AVCaptureDevice.RotationCoordinator` to keep the live preview and the captured JPEG upright. `CameraPreview` becomes a thin host for that layer.

- [ ] **Step 1: Add the preview layer + rotation state to `CameraCapture`**

In `quack/AI/CameraCapture.swift`, add these stored properties immediately after the existing `private let sessionQueue = DispatchQueue(label: "dev.quack.camera.session")` line:

```swift

    /// The preview layer the SwiftUI `CameraPreview` displays. Owned here so a
    /// RotationCoordinator can keep it upright.
    let previewLayer = AVCaptureVideoPreviewLayer()
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var previewRotationObservation: NSKeyValueObservation?
```

- [ ] **Step 2: Wire the preview layer + RotationCoordinator in `configure()`**

In `configure()`, immediately after `session.commitConfiguration()` and before `configured = true`, insert:

```swift
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill

        // RotationCoordinator keeps preview + capture level with the horizon
        // regardless of device orientation. Without it a rotated phone yields
        // a sideways preview and a sideways JPEG (which Gemma then misreads).
        let coordinator = AVCaptureDevice.RotationCoordinator(
            device: device, previewLayer: previewLayer)
        rotationCoordinator = coordinator
        previewRotationObservation = coordinator.observe(
            \.videoRotationAngleForHorizonLevelPreview,
            options: [.initial, .new]
        ) { [weak self] coordinator, _ in
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            Task { @MainActor in
                self?.previewLayer.connection?.videoRotationAngle = angle
            }
        }
```

- [ ] **Step 3: Apply the capture rotation angle in `capturePhoto()`**

In `capturePhoto()`, inside the `withCheckedThrowingContinuation` closure, set the photo connection's rotation angle before triggering capture. Replace:

```swift
        return try await withCheckedThrowingContinuation { continuation in
            self.captureContinuation = continuation
            self.photoOutput.capturePhoto(
                with: AVCapturePhotoSettings(), delegate: self)
        }
```

with:

```swift
        return try await withCheckedThrowingContinuation { continuation in
            self.captureContinuation = continuation
            if let angle = self.rotationCoordinator?.videoRotationAngleForHorizonLevelCapture,
               let connection = self.photoOutput.connection(with: .video) {
                connection.videoRotationAngle = angle
            }
            self.photoOutput.capturePhoto(
                with: AVCapturePhotoSettings(), delegate: self)
        }
```

- [ ] **Step 4: Tear down the observation in `stop()`**

In `stop()`, add the observation teardown as the first lines of the method (before the `captureContinuation` handling):

```swift
    func stop() {
        previewRotationObservation?.invalidate()
        previewRotationObservation = nil
        if let continuation = captureContinuation {
```

(The rest of `stop()` is unchanged.)

- [ ] **Step 5: Rewrite `CameraPreview` to host the shared layer**

In `quack/AI/CameraCapture.swift`, replace the entire `struct CameraPreview: UIViewRepresentable { ... }` block at the bottom of the file with:

```swift
/// SwiftUI host for a `CameraCapture`-owned `AVCaptureVideoPreviewLayer`.
struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewHostView {
        let view = PreviewHostView()
        view.attach(previewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewHostView, context: Context) {}

    /// Plain UIView that keeps the externally-owned preview layer sized to its
    /// bounds. (The layer cannot be the view's backing `layerClass` because it
    /// is owned by `CameraCapture`, not the view.)
    final class PreviewHostView: UIView {
        private weak var previewLayer: AVCaptureVideoPreviewLayer?

        func attach(_ layer: AVCaptureVideoPreviewLayer) {
            previewLayer = layer
            layer.frame = bounds
            self.layer.addSublayer(layer)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }
}
```

- [ ] **Step 6: Update the `CameraPreview` call site**

In `quack/CameraMissionView.swift`, in `scanPhaseView`, change:

```swift
                CameraPreview(session: camera.session)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
```

to:

```swift
                CameraPreview(previewLayer: camera.previewLayer)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
```

- [ ] **Step 7: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."`

- [ ] **Step 8: Commit**

```bash
git add quack/AI/CameraCapture.swift quack/CameraMissionView.swift
git commit -m "feat: keep camera preview and capture upright on device rotation"
```

---

### Task 3: Shared `scrollableWhenCompact` helper

**Files:** Create `quack/LandscapeSupport.swift`

- [ ] **Step 1: Create the helper file**

Create `quack/LandscapeSupport.swift` with exactly:

```swift
import SwiftUI

extension View {
    /// Wraps the view in a `ScrollView` only when vertical space is compact
    /// (iPhone landscape). In regular height the view is returned untouched so
    /// portrait layouts — including their `Spacer()`s — behave exactly as before.
    /// Use on portrait-composed screens so tall content scrolls instead of
    /// clipping or pushing the CTA off-screen in landscape.
    func scrollableWhenCompact() -> some View {
        modifier(ScrollableWhenCompact())
    }
}

private struct ScrollableWhenCompact: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    func body(content: Content) -> some View {
        if verticalSizeClass == .compact {
            ScrollView(showsIndicators: false) { content }
        } else {
            content
        }
    }
}
```

- [ ] **Step 2: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."`

- [ ] **Step 3: Commit**

```bash
git add quack/LandscapeSupport.swift
git commit -m "feat: add scrollableWhenCompact landscape helper"
```

---

### Task 4: Safety-net — `ScrollView` wrap for 5 one-time screens

**Files:**
- Modify `quack/OnboardingFlow.swift` (SplashView, NameView, AgeView, IntroView)
- Modify `quack/CompleteView.swift`

Each of these screens has the shape `ZStack { <background>; VStack(spacing: 0 or N) { …content… } }`. Applying `.scrollableWhenCompact()` to that inner `VStack` makes it scroll in landscape only — portrait is unchanged.

- [ ] **Step 1: SplashView**

In `quack/OnboardingFlow.swift`, in `SplashView.body`, the `VStack(spacing: 0)` inside the `ZStack` ends with `Spacer().frame(height: 32)` followed by its closing `}`. Add `.scrollableWhenCompact()` directly after that closing brace of the `VStack`:

```swift
                Spacer().frame(height: 32)
            }
            .scrollableWhenCompact()
        }
        .onAppear { visible = true }
```

- [ ] **Step 2: NameView**

In `quack/OnboardingFlow.swift`, in `NameView.body`, the `VStack(spacing: 0)` inside the `ZStack` ends after the `CTAButton(...)` and its `.padding` modifiers. Add `.scrollableWhenCompact()` after that `VStack`'s closing brace:

```swift
                CTAButton(
                    label: "Continue",
                    variant: .ink,
                    disabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                    action: {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        onNext(trimmed.isEmpty ? "Agent" : trimmed)
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollableWhenCompact()
        }
        .onAppear { focused = true }
```

- [ ] **Step 3: AgeView**

In `quack/OnboardingFlow.swift`, in `AgeView.body`, the `VStack(spacing: 0)` inside the `ZStack` ends after the `CTAButton(...)` with its `.padding` modifiers. Add `.scrollableWhenCompact()` after that `VStack`'s closing brace:

```swift
                CTAButton(label: "Continue", variant: .ink, action: { onNext(ages[selectedIndex]) })
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
            .scrollableWhenCompact()
        }
    }
```

- [ ] **Step 4: IntroView**

In `quack/OnboardingFlow.swift`, in `IntroView.body`, the `VStack(spacing: 0)` inside the `ZStack` ends after the `CTAButton(...)` with its `.padding` modifiers. Add `.scrollableWhenCompact()` after that `VStack`'s closing brace:

```swift
                CTAButton(label: "Start my first mission", variant: .orange, action: onNext)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .scrollableWhenCompact()
        }
    }
```

- [ ] **Step 5: CompleteView**

In `quack/CompleteView.swift`, in `body`, the `VStack(spacing: 0)` inside the `ZStack` ends after the `CTAButton(...)` with its `.padding` modifiers. Add `.scrollableWhenCompact()` after that `VStack`'s closing brace:

```swift
                CTAButton(label: "Back home", variant: .ink, action: onDone)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
            .scrollableWhenCompact()
        }
        .onAppear {
```

- [ ] **Step 6: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."`

- [ ] **Step 7: Commit**

```bash
git add quack/OnboardingFlow.swift quack/CompleteView.swift
git commit -m "feat: scroll onboarding and complete screens in landscape"
```

---

### Task 5: HomeView landscape layout

**Files:** Modify `quack/HomeView.swift`

In landscape, the tall orange `missionHeroCard` sits in a left column; the rest scrolls in a right column.

- [ ] **Step 1: Add the size-class read**

In `quack/HomeView.swift`, add this property to `HomeView` immediately after `@State private var showProfile = false`:

```swift
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }
```

- [ ] **Step 2: Replace `body` with an orientation branch**

Replace the entire `var body: some View { ... }` in `HomeView` with:

```swift
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    greetingHeader
                    if isLandscape {
                        HStack(alignment: .top, spacing: 0) {
                            missionHeroCard
                                .frame(maxWidth: .infinity)
                            VStack(spacing: 0) {
                                dailyRingCard
                                statCards
                                recentStickers
                                trainingGrid
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        dailyRingCard
                        missionHeroCard
                        statCards
                        recentStickers
                        trainingGrid
                    }
                    Spacer().frame(height: 120)
                }
            }
            .background(Color.cream)

            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
```

(The sub-views `greetingHeader`, `dailyRingCard`, `missionHeroCard`, `statCards`, `recentStickers`, `trainingGrid` are unchanged. In landscape `dailyRingCard` moves into the right column; in portrait the order is identical to before.)

- [ ] **Step 3: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."`

- [ ] **Step 4: Commit**

```bash
git add quack/HomeView.swift
git commit -m "feat: side-by-side HomeView layout in landscape"
```

---

### Task 6: CameraMissionView landscape layout

**Files:** Modify `quack/CameraMissionView.swift`

In landscape, the scan-phase viewfinder goes in a left column; the title + CTA go in a right column. Word/listen phases stay centered (they already fit).

- [ ] **Step 1: Add the size-class read**

In `quack/CameraMissionView.swift`, add to `CameraMissionView` immediately after `@State private var waveAnimating = false`:

```swift
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }
```

- [ ] **Step 2: Extract the title block and the scan CTA into computed properties**

In `quack/CameraMissionView.swift`, add these two computed properties to `CameraMissionView` (place them just before `// MARK: Scan phase`):

```swift
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: "Camera mission", flank: false, size: 11)
            Text("Find the \(vocab.en.lowercased())")
                .font(.display(24, weight: .heavy))
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var scanCTA: some View {
        CTAButton(
            label: phase == .checking ? "Looking..." : "I found it!",
            variant: .ink,
            disabled: !cameraReady || phase == .checking,
            action: { captureAndCheck() }
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
```

- [ ] **Step 3: Replace `body` with an orientation branch**

Replace the entire `var body: some View { ... }` in `CameraMissionView` with:

```swift
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Scan it", onBack: { dismiss() })

                if isLandscape && (phase == .scan || phase == .checking) {
                    HStack(spacing: 0) {
                        scanPhaseView
                            .frame(maxWidth: .infinity)
                        VStack(spacing: 0) {
                            titleBlock
                            Spacer()
                            scanCTA
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    titleBlock

                    switch phase {
                    case .scan, .checking: scanPhaseView
                    case .word:            wordPhaseView
                    case .listen:          listenPhaseView
                    }

                    Spacer()

                    if phase == .scan || phase == .checking {
                        scanCTA
                    } else if phase == .word {
                        CTAButton(label: "Got it", variant: .ink, action: advanceToListen)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: phase)
        .task { await prepareCamera() }
        .onDisappear {
            checkTask?.cancel()
            camera.stop()
            SpeechSpeaker.shared.stop()
        }
    }
```

(`scanPhaseView`, `wordPhaseView`, `listenPhaseView`, the action methods, `CameraCornerBrackets`, and `#Preview` are unchanged.)

- [ ] **Step 4: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."`

- [ ] **Step 5: Commit**

```bash
git add quack/CameraMissionView.swift
git commit -m "feat: side-by-side CameraMission scan layout in landscape"
```

---

### Task 7: SpeakMissionView landscape layout

**Files:** Modify `quack/SpeakMissionView.swift`

In landscape: word hero card left, mic card + result CTAs right.

- [ ] **Step 1: Add the size-class read**

In `quack/SpeakMissionView.swift`, add to `SpeakMissionView` immediately after `@State private var autoStopTask: Task<Void, Never>?`:

```swift
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }
```

- [ ] **Step 2: Extract the word card, mic card, and result CTAs into computed properties**

In `quack/SpeakMissionView.swift`, add these three computed properties to `SpeakMissionView` (place them just before `@ViewBuilder private var micCardContent`):

```swift
    private var wordCard: some View {
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
    }

    private var micCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.paper)
                .cardShadow()

            micCardContent
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var resultCTAs: some View {
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
```

- [ ] **Step 3: Replace `body` with an orientation branch**

Replace the entire `var body: some View { ... }` in `SpeakMissionView` with:

```swift
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Say it", accent: .cobalt, onBack: { dismiss() })

                if isLandscape {
                    HStack(spacing: 0) {
                        wordCard
                            .frame(maxWidth: .infinity)
                        VStack(spacing: 0) {
                            micCard
                            Spacer()
                            resultCTAs
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    wordCard
                    micCard
                    Spacer()
                    resultCTAs
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: phase)
        .onAppear { waveAnimating = true }
    }
```

(`micCardContent`, the action methods, `words`, `current`, and `#Preview` are unchanged.)

- [ ] **Step 4: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."`

- [ ] **Step 5: Commit**

```bash
git add quack/SpeakMissionView.swift
git commit -m "feat: side-by-side SpeakMission layout in landscape"
```

---

### Task 8: MatchMissionView landscape layout

**Files:** Modify `quack/MatchMissionView.swift`

In landscape: prompt card left, 2×2 choice grid + CTA right.

- [ ] **Step 1: Add the size-class read**

In `quack/MatchMissionView.swift`, add to `MatchMissionView` immediately after `@State private var revealed = false`:

```swift
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }
```

- [ ] **Step 2: Extract the prompt card, choice grid, and CTA into computed properties**

In `quack/MatchMissionView.swift`, add these three computed properties to `MatchMissionView` (place them just before `var body`):

```swift
    private var promptCard: some View {
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
    }

    private var choiceGrid: some View {
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
    }

    @ViewBuilder
    private var matchCTA: some View {
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
```

- [ ] **Step 3: Replace `body` with an orientation branch**

Replace the entire `var body: some View { ... }` in `MatchMissionView` with:

```swift
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Match it", accent: .rose, onBack: { dismiss() })

                if isLandscape {
                    HStack(spacing: 0) {
                        promptCard
                            .frame(maxWidth: .infinity)
                        VStack(spacing: 0) {
                            choiceGrid
                            Spacer()
                            matchCTA
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    promptCard
                    choiceGrid
                    Spacer()
                    matchCTA
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: revealed)
    }
```

(`round`, `MatchChoiceCell`, the `init`, and `#Preview` are unchanged.)

- [ ] **Step 4: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."`

- [ ] **Step 5: Commit**

```bash
git add quack/MatchMissionView.swift
git commit -m "feat: side-by-side MatchMission layout in landscape"
```

---

### Task 9: StoryMissionView landscape layout

**Files:** Modify `quack/StoryMissionView.swift`

In landscape: in the reading phase the story card sits left, the progress bars + narration + CTA right; in the quiz phase the prompt sits left, the choices + CTA right.

- [ ] **Step 1: Add the size-class read**

In `quack/StoryMissionView.swift`, add to `StoryMissionView` immediately after `@State private var quizChoicesCache: [VocabItem]? = nil`:

```swift
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }
```

- [ ] **Step 2: Split `readingView` into a story card and a side panel**

In `quack/StoryMissionView.swift`, replace the entire `private func readingView(page: Int) -> some View { ... }` with these three methods:

```swift
    // MARK: Reading
    private func readingView(page: Int) -> some View {
        let storyPage = pages[min(page, pages.count - 1)]
        return Group {
            if isLandscape {
                HStack(spacing: 0) {
                    storyCard(storyPage)
                        .frame(maxWidth: .infinity)
                    VStack(spacing: 12) {
                        progressBars(page: page)
                        narrationCard(storyPage)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 12) {
                    progressBars(page: page)
                    storyCard(storyPage)
                    narrationCard(storyPage)
                }
            }
        }
    }

    private func progressBars(page: Int) -> some View {
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
    }

    private func storyCard(_ storyPage: StoryPage) -> some View {
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
    }

    private func narrationCard(_ storyPage: StoryPage) -> some View {
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
```

Note: `StoryPage` is the existing `private struct StoryPage` — no change. The `storyCard`/`narrationCard`/`progressBars` bodies are lifted verbatim from the old `readingView`.

- [ ] **Step 3: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."` (The reading phase now adapts; the quiz phase is handled next.)

- [ ] **Step 4: Split `quizView` for landscape**

In `quack/StoryMissionView.swift`, replace the entire `private var quizView: some View { ... }` with:

```swift
    // MARK: Quiz
    private var quizView: some View {
        Group {
            if isLandscape {
                HStack(spacing: 0) {
                    quizPrompt
                        .frame(maxWidth: .infinity)
                    quizChoices
                        .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 16) {
                    quizPrompt
                    quizChoices
                }
            }
        }
        .onAppear {
            if quizChoicesCache == nil { quizChoicesCache = makeQuizChoices() }
        }
    }

    private var quizPrompt: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: "Quick quiz", flank: false, size: 11)
            Text("Which one is '\(vocab.hanzi)'?")
                .font(.display(22, weight: .heavy))
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var quizChoices: some View {
        let choices = quizChoicesCache ?? makeQuizChoices()
        return VStack(spacing: 10) {
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
```

- [ ] **Step 5: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."`

- [ ] **Step 6: Commit**

```bash
git add quack/StoryMissionView.swift
git commit -m "feat: side-by-side StoryMission layout in landscape"
```

---

### Task 10: SnapPhotoView landscape layout

**Files:** Modify `quack/SnapPhotoView.swift`

In landscape: compose phase = camera panel left, title right; analyzing phase = the panel centered; result phase = title left, word grid right. This requires splitting each phase view into its title/grid and its panel so they can be recomposed.

- [ ] **Step 1: Add the size-class read**

In `quack/SnapPhotoView.swift`, add to `SnapPhotoView` immediately after `@State private var dotScale = [false, false, false]`:

```swift
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }
```

- [ ] **Step 2: Replace the three phase views with split sub-views**

In `quack/SnapPhotoView.swift`, replace everything from `// MARK: - Compose phase` down to (but not including) `// MARK: - Snap corner brackets` with the following. Each phase view is split into a title/grid piece and a panel piece (bodies lifted verbatim from the originals) so portrait composes them in a `VStack` exactly as before and landscape can recompose them:

```swift
    // MARK: - Compose phase
    private var composeTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: "Point Q's camera at anything", flank: false, size: 11)
            Text("What do you see?")
                .font(.display(24, weight: .heavy))
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private var composeCameraPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.ink)
                .grain(opacity: 0.12)

            SnapCornerBrackets()

            Mascot(state: .idle, size: 80)
                .opacity(0.3)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.horizontal, 24)
    }

    private var composePhaseView: some View {
        VStack(spacing: 16) {
            composeTitle
            composeCameraPanel
        }
        .padding(.top, 8)
    }

    // MARK: - Analyzing phase
    private var analyzingPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.ink)
                .grain(opacity: 0.12)

            SnapCornerBrackets()

            VStack(spacing: 20) {
                Mascot(state: .speaking, size: 80)

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.quackOrange)
                            .frame(width: 12, height: 12)
                            .scaleEffect(dotScale[i] ? 1.4 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.18),
                                value: dotScale[i]
                            )
                    }
                }

                Text("Q is looking...")
                    .font(.display(16, weight: .heavy))
                    .foregroundStyle(Color.cream)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.horizontal, 24)
    }

    private var analyzingPhaseView: some View {
        VStack(spacing: 28) {
            analyzingPanel
        }
        .padding(.top, 8)
        .onAppear {
            for i in 0..<3 { dotScale[i] = true }
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation { phase = .result }
            }
        }
    }

    // MARK: - Result phase
    private var resultTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: "Q found these words!", flank: false, size: 11)
            Text("Pick one to learn")
                .font(.display(24, weight: .heavy))
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private var resultGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(resultWords) { word in
                Button { selectedId = word.id } label: {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 8) {
                            ObjectArt(vocab: word, size: 60)
                            Text(word.hanzi)
                                .font(.display(20, weight: .heavy))
                                .foregroundStyle(Color.ink)
                            Text(word.en)
                                .font(.bodyText(12))
                                .foregroundStyle(Color.inkMuted)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cream)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            selectedId == word.id ? Color.quackOrange : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                        )
                        .cardShadow()

                        if selectedId == word.id {
                            Circle()
                                .fill(Color.quackOrange)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    QuackIcon(name: .check, size: 13, color: .white, strokeWidth: 2)
                                )
                                .padding(8)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
    }

    private var resultPhaseView: some View {
        VStack(spacing: 16) {
            resultTitle
            resultGrid
        }
        .padding(.top, 8)
    }

    // MARK: - Landscape phase content
    @ViewBuilder
    private var landscapePhaseContent: some View {
        switch phase {
        case .compose:
            HStack(alignment: .center, spacing: 0) {
                composeCameraPanel.frame(maxWidth: .infinity)
                VStack { composeTitle; Spacer() }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.top, 8)
        case .analyzing:
            analyzingPanel.padding(.top, 8)
        case .result:
            HStack(alignment: .top, spacing: 0) {
                VStack { resultTitle; Spacer() }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                resultGrid.frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
        }
    }
```

- [ ] **Step 3: Branch the phase content in `body`**

In `quack/SnapPhotoView.swift`, in `body`, replace this block:

```swift
                switch phase {
                case .compose:   composePhaseView
                case .analyzing: analyzingPhaseView
                case .result:    resultPhaseView
                }

                Spacer()
```

with:

```swift
                if isLandscape {
                    landscapePhaseContent
                } else {
                    switch phase {
                    case .compose:   composePhaseView
                    case .analyzing: analyzingPhaseView
                    case .result:    resultPhaseView
                    }
                }

                Spacer()
```

Note: the analyzing phase's `.onAppear` (the 1.5 s timer that advances to `.result`) lives on `analyzingPhaseView`, which is not used in landscape. Move that `.onAppear` so it always runs: attach it to the `if isLandscape { ... } else { ... }` block — append `.onAppear { for i in 0..<3 { dotScale[i] = true }; Task { try? await Task.sleep(nanoseconds: 1_500_000_000); if phase == .analyzing { withAnimation { phase = .result } } } }` is NOT correct here because it would fire for every phase. Instead, keep the `.onAppear` on `analyzingPhaseView` AND add the identical `.onAppear` to the `.analyzing` case of `landscapePhaseContent`. Update the `.analyzing` case of `landscapePhaseContent` to:

```swift
        case .analyzing:
            analyzingPanel
                .padding(.top, 8)
                .onAppear {
                    for i in 0..<3 { dotScale[i] = true }
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        withAnimation { phase = .result }
                    }
                }
```

- [ ] **Step 4: Build**

Build via `mcp__xcode__BuildProject`. Expected: `"The project built successfully."`

- [ ] **Step 5: Commit**

```bash
git add quack/SnapPhotoView.swift
git commit -m "feat: side-by-side SnapPhotoView layout in landscape"
```

---

### Task 11: On-device verification

**Files:** none (verification).

- [ ] **Step 1: Build and run on a physical iPhone**

- [ ] **Step 2: Verify the camera**

1. Open the Camera Mission — it shows the **front** camera.
2. Rotate the phone through portrait, landscape-left, landscape-right: the live preview stays upright (not sideways).
3. Capture in landscape and confirm a correct recognition — the JPEG handed to Gemma is upright.
4. In landscape the scan phase shows viewfinder-left / title+CTA-right.

- [ ] **Step 3: Rotate every screen**

Visit Home, all 4 mission screens, Snap-photo, onboarding (Splash/Name/Age/Intro), and the mission-complete screen. In landscape on each: no content is clipped, and every CTA button is reachable (scroll if needed on the safety-net screens). The 6 adaptive screens show their side-by-side layout.

- [ ] **Step 4: Confirm portrait is unchanged**

Quickly walk the same screens in portrait — layouts must look exactly as before this work.

- [ ] **Step 5: File issues for any defects, otherwise done**

If a screen looks broken, debug with the systematic-debugging skill. Otherwise the feature is complete.

---

## Self-Review

**Spec coverage:**
- Front camera → Task 1. ✓
- Camera orientation (`RotationCoordinator`, preview + capture upright, `CameraCapture` owns preview layer, `CameraPreview` thin host) → Task 2. ✓
- Landscape signal (`verticalSizeClass == .compact`) → Task 3 helper + per-screen `isLandscape` reads. ✓
- 6 adaptive screens (CameraMission, SnapPhoto, Speak, Match, Story, Home) → Tasks 5–10. ✓
- 5 safety-net screens (onboarding Splash/Name/Age/Intro, Complete) → Task 4. ✓
- 9 screens untouched → not in any task. ✓
- iPad landscape left on portrait layouts → `verticalSizeClass == .compact` is false on iPad, so every `isLandscape` branch and `scrollableWhenCompact` no-ops there. ✓
- Testing → Task 11. ✓

**Placeholder scan:** No TBD/TODO; every code step shows complete code. Extracted computed properties carry the verbatim bodies from the originals.

**Type consistency:** `isLandscape` / `verticalSizeClass` named identically across Tasks 5–10. `CameraPreview(previewLayer:)` (Task 2 Step 5) matches the call site update (Task 2 Step 6). `previewLayer` property (Task 2 Step 1) matches its uses. `scrollableWhenCompact()` (Task 3) matches the 5 applications (Task 4). Extracted property names (`titleBlock`, `scanCTA`, `wordCard`, `micCard`, `resultCTAs`, `promptCard`, `choiceGrid`, `matchCTA`, `storyCard`, `narrationCard`, `progressBars`, `quizPrompt`, `quizChoices`, `composeTitle`, `composeCameraPanel`, `analyzingPanel`, `resultTitle`, `resultGrid`, `landscapePhaseContent`) are each defined once and used within their own file. Task 10 Step 2 fully replaces the original `composePhaseView`/`analyzingPhaseView`/`resultPhaseView` so no duplicate definitions remain.
