# Camera Mission — Gemma Vision Object Recognition

**Issue:** quack-app-oe3
**Date:** 2026-05-16
**Status:** Approved

## Problem

`CameraMissionView.swift` fakes object detection: a 2-second timer flips
`showDetection` to `true` regardless of what the camera sees, and the "Hear it"
button (`:140`) is an empty closure. The mission needs to actually capture an
image, verify it against the target vocab word with on-device Gemma 4 vision,
and speak the target word in Mandarin.

## Goals

- Capture a real still image from the device camera (no faked detection).
- Verify the captured object against the target vocab word using Gemma
  multimodal inference.
- Correct object advances the mission; wrong object shows a try-again UI.
- Wire the "Hear it" button to Mandarin TTS.
- Handle camera-permission denial gracefully.

## Non-Goals

- Changes to the `.listen` phase (out of scope for this issue).
- Static-content fallback (that belongs to the Story Mission issue).
- Unit tests — the existing AI layer has none; verification is manual on-device.

## Design Decisions

- **Capture flow:** tap-to-capture. The kid aims at the object and taps
  "I found it!", which captures one still frame and runs Gemma. Mirrors the
  Speak Mission's tap-to-act pattern.
- **Vision prompt:** open-ended naming, not yes/no. We ask Gemma what the main
  object is and compare its answer to the target word in Swift. Handing a small
  model the expected answer ("Is this a cat?") biases it toward "yes" — the
  audio path in `QuackGemma.swift` documents this exact pitfall.

## Architecture

The vision path mirrors the existing audio path through all four layers.

### 1. Bridge layer — image inference

- **`LiteRTBridge.mm/.h`** — new `inferWithImage(imageFilePath, textPrompt)`,
  a near-copy of `inferWithAudio` building JSON `{type:"image",path:...}`
  followed by `{type:"text",text:...}`. The bundled `chat_template.jinja`
  already handles `type == 'image'`.
- **Verify during implementation:** whether `ConversationConfig` needs
  `SetVisionModalityEnabled(true)` alongside the existing
  `SetAudioModalityEnabled(true)`. If the C++ API exposes such a flag, set it.
- **`LiteRTBridgeSwift.h/.mm`** — new `inferWithImagePath:prompt:` wrapper
  returning `NSString *_Nullable`.
- **`LiteRTRepository.swift`** — new `inferImage(imageData:prompt:)` that writes
  the JPEG to a temp file (mirrors `inferAudio`'s temp-WAV pattern with a
  `defer` cleanup), passes the path to the bridge, returns the raw output.

### 2. QuackGemma — vision use case

```swift
struct VisionResult { let recognized: String; let matched: Bool }
func recognizeObject(image: Data, target: VocabItem) async throws -> VisionResult
```

Prompt: *"What is the main object in this photo? Answer with one or two English
words, lowercase, no punctuation. If unclear, answer: none."*

A static `objectMatches(recognized:target:)` helper normalizes both strings and
matches via substring containment or Levenshtein similarity against `vocab.en`,
reusing the existing `normalize`/`levenshtein` helpers. Returns `false` when the
model answers "none".

**Known limitation:** a synonym ("kitten" vs "cat") reads as a mismatch; the
retry flow covers this — the kid simply re-aims.

### 3. CameraCapture.swift — new capture component

Analogous to `MicRecorder`. `@MainActor` class wrapping:

- `AVCaptureSession` + `AVCapturePhotoOutput`.
- `requestPermission()` via `AVCaptureDevice.requestAccess(for: .video)`.
- `start()` / `stop()` for session lifecycle.
- `capturePhoto() async throws -> Data` — captures one still, downscales to
  ~768px max dimension, returns JPEG `Data`. Downscaling keeps inference fast;
  full-resolution photos are wasteful for the vision encoder.
- `CameraPreview: UIViewRepresentable` wrapping `AVCaptureVideoPreviewLayer`
  for the live feed.

### 4. CameraMissionView rewrite

- **Scan phase:** replace the fake dark rectangle (`scanPhaseView`) with the
  live `CameraPreview`, keeping the `CameraCornerBrackets` overlay. Remove the
  fake 2s `showDetection` timer and the scan-line animation.
- **New `.checking` phase:** tapping "I found it!" captures a still, shows a
  spinner ("Looking..."), and runs `recognizeObject`.
  - Match → advance to `.word`.
  - No match → return to scan with a try-again message
    ("Hmm, I see a {recognized}. Point at the {target}!").
- **Word phase:** wire the empty "Hear it" button (`CameraMissionView.swift:140`)
  to `SpeechSpeaker.shared.speak(vocab.hanzi)`.
- **Permission denied:** friendly message with a Settings hint (mirrors
  `MicRecorder` / Speak Mission).
- **Gemma/model failure:** error message + retry, same as Speak Mission.
- **`.listen` phase:** left untouched.
- **Simulator:** the camera is unavailable in the iOS Simulator; the preview
  shows a graceful placeholder so the build still runs.

### Info.plist

`NSCameraUsageDescription` is already present in the project build settings
(`INFOPLIST_KEY_NSCameraUsageDescription`, both Debug and Release). No change
needed.

## Data Flow

```
[ Camera preview ] --tap "I found it!"--> CameraCapture.capturePhoto()
        |                                         |
        |                                  JPEG Data (~768px)
        v                                         v
  .checking phase  <----  QuackGemma.recognizeObject(image:target:)
        |                                         |
        |                          LiteRTRepository.inferImage(prompt:)
        |                                         |
        |                          LiteRTBridgeSwift.inferWithImagePath:prompt:
        |                                         |
        |                          LiteRTBridge::inferWithImage(...)
        v                                         |
   VisionResult  <-------- objectMatches() <-- raw model output
        |
   matched? --yes--> .word phase --> "Hear it" --> SpeechSpeaker.speak(hanzi)
        |
        +--no--> back to scan, try-again message
```

## Error Handling

| Failure | Behavior |
|---|---|
| Camera permission denied | Message + Settings hint; mission cannot proceed |
| Model not ready / load failed | Error message in scan phase, retry allowed |
| Inference throws | Error message, retry allowed |
| Gemma answers "none" / no match | Try-again message, kid re-aims |
| Running in Simulator | Placeholder view instead of live preview |

## Testing

Manual, on-device:

1. Point camera at the correct object → mission advances.
2. Point at a wrong object → try-again UI appears.
3. "Hear it" button speaks the target word in Mandarin.
4. Deny camera permission → graceful message, no crash.
