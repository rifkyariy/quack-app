# Front Camera + Whole-App Landscape Support

**Date:** 2026-05-16
**Status:** Approved

## Problem

Two requests for the quack-app:

1. The Camera Mission uses the back camera only — the user wants it to use the
   front camera.
2. The app permits landscape in `Info.plist`, but no screen adapts to it. The
   camera preview and captured photo ignore device rotation (sideways preview,
   misoriented JPEG — which also makes Gemma misread the object), and 11
   portrait-composed screens clip content or hide their CTA in landscape.

## Goals

- The Camera Mission uses the front camera by default.
- The camera preview and the captured photo stay upright in every device
  orientation.
- Every screen is usable in iPhone landscape — nothing clips, every CTA is
  reachable. Screens where landscape matters get a designed side-by-side
  layout; the rest get a scroll safety-net.

## Non-Goals

- iPad landscape redesign — iPad keeps the existing portrait-composed layouts
  (its `.regular` height class has ample room; portrait layouts simply center).
- Front/back camera toggle — the mission uses the front camera; there is no
  in-mission switch.
- Redesigning the 9 screens already landscape-safe (see audit below).

## Design Decisions

- **Front camera, no toggle.** `CameraCapture.configure()` selects the front
  camera. iOS's default selfie behavior (mirrored preview, true-scene capture)
  is left untouched — horizontal mirroring does not affect Gemma's object
  recognition.
- **Landscape signal: `verticalSizeClass == .compact`.** This is true exactly
  for iPhone-in-landscape, which is where content cramps. iPad landscape is
  `.regular` and needs no change.
- **Hybrid landscape depth.** Six screens where landscape genuinely matters get
  a designed side-by-side layout; five one-time/celebration screens get a
  `ScrollView` safety-net only.

## Architecture

### 1. Front camera — `CameraCapture.configure()`

Change device selection from `.back` to `.front`:

```swift
AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    ?? AVCaptureDevice.default(for: .video)
```

The generic fallback is retained for devices without a front wide-angle camera.

### 2. Camera orientation — `CameraCapture` + `CameraPreview`

Use `AVCaptureDevice.RotationCoordinator` (iOS 17+; the deployment target is
18.5).

- **Preview-layer ownership moves into `CameraCapture`.** `CameraCapture`
  creates and owns the `AVCaptureVideoPreviewLayer` (so it can construct the
  `RotationCoordinator` and apply preview-rotation updates). `CameraPreview`
  (the `UIViewRepresentable`) becomes a thin host that mounts `CameraCapture`'s
  layer into its backing `UIView`.
- `CameraCapture` creates `RotationCoordinator(device:previewLayer:)` after the
  session is configured.
- KVO-observe `videoRotationAngleForHorizonLevelPreview` → apply to the preview
  layer's connection so the live preview stays upright.
- At capture time, set the `AVCapturePhotoOutput` connection's
  `videoRotationAngle` from `videoRotationAngleForHorizonLevelCapture` so the
  JPEG handed to Gemma is always upright.
- The KVO observers are torn down in `stop()`/`deinit` alongside the existing
  session teardown.

### 3. Landscape strategy

Each adaptive screen reads `@Environment(\.verticalSizeClass)` and branches.
No new shared component — inline branching keeps each screen self-contained;
the convention (compact height ⇒ landscape layout) is applied consistently.

### 4. Adaptive screens (6) — designed side-by-side layout

When height-compact, the screen's portrait top-level `VStack` becomes an
`HStack` with two columns; each column scrolls independently if its content
still overflows.

| Screen | Landscape layout |
|---|---|
| `CameraMissionView` (scan phase) | Viewfinder left · title + status + CTA right |
| `SnapPhotoView` (compose/analyze) | Camera preview left · controls right |
| `SpeakMissionView` | Word hero card left · mic card + CTA right |
| `MatchMissionView` | Prompt card left · 2×2 choice grid right |
| `StoryMissionView` | Story card left · narration/quiz + CTA right |
| `HomeView` | Hero card left · stats + stickers + training grid (scrolling) right |

The word/listen phases of `CameraMissionView` and other already-compact
sub-layouts stay centered; only the portrait-composed parts get the HStack
treatment.

### 5. Safety-net screens (5) — `ScrollView` wrap

`OnboardingFlow`'s SplashView / NameView / AgeView / IntroView, and
`CompleteView`: wrap the main content `VStack` in a `ScrollView` so tall cards
and mascots scroll instead of clipping or pushing the CTA off-screen. No layout
redesign — these are one-time onboarding and celebration screens.

## Screen Audit (reference)

Landscape-safe as-is, untouched (9): `AppView`, `MainTabView`,
`MissionsHubView`, `LibraryView`, `ParentView`, `ProfileView`,
`LaunchSplashView`, `MissionHeader`, and `OnboardingFlow`'s router shell.

Needs work (11): the 6 adaptive screens + the 5 safety-net screens above.

## Error Handling

- Front camera unavailable → existing `CameraCapture.CaptureError.unavailable`
  path (already handled in `CameraMissionView` as a friendly message).
- `RotationCoordinator` KVO: applying a rotation angle to a connection is
  best-effort; if a connection is momentarily unavailable the update is skipped,
  not fatal.
- No new error surfaces — orientation and layout changes do not introduce
  failure modes.

## Testing

Manual, on-device (consistent with the rest of the app — no automated UI tests):

1. Camera Mission shows the front camera.
2. Rotate the device through all four orientations: live preview stays upright;
   the captured photo is upright (verify a correct recognition after rotating).
3. Rotate every screen: no content clips, every CTA stays reachable.
4. The 6 adaptive screens show their side-by-side layout in iPhone landscape.
5. iPad landscape still renders the portrait-composed layouts without breakage.
