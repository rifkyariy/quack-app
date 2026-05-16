# Camera Mission — Gemma Vision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Camera Mission's faked object detection with real on-device Gemma 4 vision recognition, and wire its "Hear it" button to Mandarin TTS.

**Architecture:** Plumb an image-inference path through the four existing layers (C++ bridge → Obj-C++ wrapper → repository → `QuackGemma`), mirroring the audio path exactly (JSON `{type:"image",path:...}`). Add a new `CameraCapture` component (an `AVCaptureSession` wrapper analogous to `MicRecorder`) and rewrite `CameraMissionView` to capture a still on tap, verify it with Gemma, and advance or show try-again.

**Tech Stack:** Swift 6 / SwiftUI, Objective-C++, AVFoundation, LiteRT-LM C++ Conversation API, Gemma 4 E2B multimodal.

**Spec:** `docs/superpowers/specs/2026-05-16-camera-mission-gemma-vision-design.md`
**Issue:** quack-app-oe3

## Notes for the implementer

- **No automated tests.** The AI layer has no test target; verification is a project build after each task plus a final on-device manual pass. This was approved during brainstorming.
- **Build command:** prefer the `mcp__xcode__BuildProject` tool. CLI fallback: `xcodebuild -project quack.xcodeproj -scheme quack -destination 'platform=iOS,name=<your device>' build`. "BUILD SUCCEEDED" is the pass condition. The LiteRT-LM static lib is built for device arm64 — build for a real device, not the Simulator.
- **New files are auto-included.** The project uses `PBXFileSystemSynchronizedRootGroup`; a new `.swift` file under `quack/` joins the target with no `project.pbxproj` edit.
- **`NSCameraUsageDescription`** is already set (`INFOPLIST_KEY_NSCameraUsageDescription` in `project.pbxproj`, Debug + Release). No Info.plist work.
- Commit after every task.

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `quack/AI/LiteRTBridge.h` | C++ bridge interface | Modify — declare `inferWithImage` |
| `quack/AI/LiteRTBridge.mm` | C++ bridge impl | Modify — enable vision modality, add `inferWithImage` |
| `quack/AI/LiteRTBridgeSwift.h` | Obj-C wrapper interface | Modify — declare `inferWithImagePath:prompt:` |
| `quack/AI/LiteRTBridgeSwift.mm` | Obj-C wrapper impl | Modify — add `inferWithImagePath:prompt:` |
| `quack/AI/LiteRTRepository.swift` | Swift repository | Modify — add `inferImage(imageData:prompt:)` |
| `quack/AI/QuackGemma.swift` | Mission-facing inference service | Modify — add `recognizeObject` + `objectMatches` |
| `quack/AI/CameraCapture.swift` | Camera session + still capture + SwiftUI preview | Create |
| `quack/CameraMissionView.swift` | Camera Mission UI | Modify — rewrite scan/word phases |

---

### Task 1: C++ bridge — enable vision modality and add `inferWithImage`

**Files:**
- Modify: `quack/AI/LiteRTBridge.h`
- Modify: `quack/AI/LiteRTBridge.mm`

- [ ] **Step 1: Declare `inferWithImage` in the header**

In `quack/AI/LiteRTBridge.h`, add this method declaration immediately after the `inferWithAudio` declaration (after line 58, before `void shutdown();`):

```cpp
  /// Performs blocking inference with image input (multimodal).
  /// - Parameter imageFilePath: Path to a JPEG/PNG image file on disk.
  /// - Parameter textPrompt: Text instruction.
  /// - Returns: Complete model output string, or empty on error.
  std::string inferWithImage(const std::string &imageFilePath,
                             const std::string &textPrompt);
```

- [ ] **Step 2: Enable the vision modality in `initialize`**

In `quack/AI/LiteRTBridge.mm`, in `LiteRTBridge::initialize`, change the `EngineSettings::CreateDefault` call (currently lines 67-70) so `vision_backend` is `Backend::CPU` instead of `std::nullopt`:

```cpp
    auto engine_settings_or = EngineSettings::CreateDefault(
        std::move(*model_assets_or), Backend::CPU,
        /*vision_backend=*/Backend::CPU,
        /*audio_backend=*/Backend::CPU);
```

Then, in the cache-directory block, bump the stale-cache marker from `.audio_cache_v1` to `.vision_cache_v1` (the engine config changed, so the Metal shader cache must rebuild once). Change the line that currently reads:

```cpp
      NSString *markerFile = [cacheDir stringByAppendingPathComponent:@".audio_cache_v1"];
```

to:

```cpp
      NSString *markerFile = [cacheDir stringByAppendingPathComponent:@".vision_cache_v1"];
```

And immediately after the existing audio-executor cache-dir block (the `if (engine_settings_or->GetAudioExecutorSettings()...` block, currently lines 104-106), add the matching vision-executor block:

```cpp
      // Also set cache dir for the vision executor (CPU-based vision encoder).
      if (engine_settings_or->GetVisionExecutorSettings().has_value()) {
        engine_settings_or->GetMutableVisionExecutorSettings()->SetCacheDir(cacheDirStr);
      }
```

- [ ] **Step 3: Enable vision modality on the session config**

In `quack/AI/LiteRTBridge.mm`, in `initialize`, find the line `session_config.SetAudioModalityEnabled(true);` and add a vision line right after it:

```cpp
    auto session_config = SessionConfig::CreateDefault();
    session_config.SetAudioModalityEnabled(true);
    session_config.SetVisionModalityEnabled(true);
```

Update the adjacent log line `"ConversationConfig created successfully (audio enabled)"` to `"ConversationConfig created successfully (audio + vision enabled)"`.

- [ ] **Step 4: Implement `inferWithImage`**

In `quack/AI/LiteRTBridge.mm`, add this method immediately after `LiteRTBridge::inferWithAudio` ends (after line 259):

```cpp
std::string LiteRTBridge::inferWithImage(const std::string &imageFilePath,
                                         const std::string &textPrompt) {
  if (!impl_ || !impl_->is_ready || !impl_->conversation) {
    return "";
  }

  try {
    // Build multimodal message with image file path and text instruction.
    json content = json::array();
    content.push_back({{"type", "image"}, {"path", imageFilePath}});
    content.push_back({{"type", "text"}, {"text", textPrompt}});

    json message = {
      {"role", "user"},
      {"content", content}
    };

    std::cout << "Sending image message to LiteRT-LM (image: "
              << imageFilePath << ")" << std::endl;

    auto result_or = impl_->conversation->SendMessage(message);
    if (!result_or.ok()) {
      std::cerr << "SendMessage (image) failed: "
                << result_or.status().message() << std::endl;
      return "";
    }

    const json& response = *result_or;
    std::string output;
    if (response.contains("content")) {
      if (response["content"].is_string()) {
        output = response["content"].get<std::string>();
      } else if (response["content"].is_array()) {
        for (const auto& item : response["content"]) {
          if (item.contains("text")) {
            output += item["text"].get<std::string>();
          }
        }
      } else {
        output = response["content"].dump();
      }
    } else {
      output = response.dump();
    }

    std::cout << "LiteRT-LM image response received (" << output.size()
              << " chars)" << std::endl;
    return output;
  } catch (const std::exception &e) {
    std::cerr << "Image inference exception: " << e.what() << std::endl;
    return "";
  }
}
```

- [ ] **Step 5: Build**

Build the project (`mcp__xcode__BuildProject` or `xcodebuild`).
Expected: BUILD SUCCEEDED. If `SetVisionModalityEnabled` or `GetVisionExecutorSettings` is unresolved, confirm `runtime/engine/engine_settings.h` is on the header search path (it already is — `SetAudioModalityEnabled` resolves from the same header).

- [ ] **Step 6: Commit**

```bash
git add quack/AI/LiteRTBridge.h quack/AI/LiteRTBridge.mm
git commit -m "feat: add image inference to LiteRT-LM bridge (quack-app-oe3)"
```

---

### Task 2: Obj-C++ wrapper — add `inferWithImagePath:prompt:`

**Files:**
- Modify: `quack/AI/LiteRTBridgeSwift.h`
- Modify: `quack/AI/LiteRTBridgeSwift.mm`

- [ ] **Step 1: Declare the wrapper method**

In `quack/AI/LiteRTBridgeSwift.h`, add this declaration immediately after the `inferWithAudioPath:prompt:` declaration (after line 47, before the streaming-audio declaration):

```objc
/// Performs blocking inference with image file input (multimodal).
/// - Parameter imagePath: Absolute path to a JPEG/PNG image file on disk.
/// - Parameter prompt: Text instruction.
/// - Returns: Complete model output string, or nil on failure.
- (NSString *_Nullable)inferWithImagePath:(NSString *)imagePath prompt:(NSString *)prompt;
```

- [ ] **Step 2: Implement the wrapper method**

In `quack/AI/LiteRTBridgeSwift.mm`, add this method immediately after `inferWithAudioPath:prompt:` ends (after line 107):

```objc
- (NSString *)inferWithImagePath:(NSString *)imagePath prompt:(NSString *)prompt {
    LiteRTBridge *bridge = static_cast<LiteRTBridge *>(self.bridgePtr);
    if (!bridge || !self.isReady) {
        return nil;
    }

    try {
        std::string result = bridge->inferWithImage(
            imagePath.UTF8String, prompt.UTF8String);
        if (result.empty()) return nil;
        return [NSString stringWithUTF8String:result.c_str()];
    } catch (const std::exception& e) {
        NSLog(@"Image inference failed: %s", e.what());
        return nil;
    }
}
```

- [ ] **Step 3: Build**

Build the project. Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add quack/AI/LiteRTBridgeSwift.h quack/AI/LiteRTBridgeSwift.mm
git commit -m "feat: expose image inference in Obj-C bridge wrapper (quack-app-oe3)"
```

---

### Task 3: Repository — add `inferImage`

**Files:**
- Modify: `quack/AI/LiteRTRepository.swift`

- [ ] **Step 1: Add `inferImage` to the repository**

In `quack/AI/LiteRTRepository.swift`, add this method immediately after `inferAudio(audioData:prompt:)` ends (after line 232, inside the `actor LiteRTRepository`):

```swift
    /// Multimodal image inference with a custom prompt. Writes the image bytes
    /// to a temp JPEG, sends the path through the bridge, and cleans up.
    func inferImage(imageData: Data, prompt: String) async throws -> String {
        guard let bridge = bridge, isInitialized else {
            throw RepositoryError.notInitialized
        }
        let tempDir = NSTemporaryDirectory()
        let fileName = "quack_image_\(UUID().uuidString).jpg"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)
        try imageData.write(to: URL(fileURLWithPath: filePath))
        defer { try? FileManager.default.removeItem(atPath: filePath) }
        guard let output = bridge.inferWithImagePath(filePath, prompt: prompt) else {
            throw RepositoryError.inferenceFailed("No output from image inference")
        }
        return output
    }
```

- [ ] **Step 2: Build**

Build the project. Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add quack/AI/LiteRTRepository.swift
git commit -m "feat: add image inference to LiteRTRepository (quack-app-oe3)"
```

---

### Task 4: QuackGemma — add `recognizeObject` and `objectMatches`

**Files:**
- Modify: `quack/AI/QuackGemma.swift`

- [ ] **Step 1: Add the vision use case**

In `quack/AI/QuackGemma.swift`, add the following inside the `QuackGemma` class, immediately after the `scorePronunciation` method ends (after line 85, before the `pronunciationScore` static method).

```swift
    struct VisionResult {
        /// What Gemma said the photo contains (raw, trimmed).
        let recognized: String
        /// Whether `recognized` matches the target vocab word.
        let matched: Bool
    }

    /// Asks Gemma to name the main object in a photo, then checks that name
    /// against the target vocab item. Uses open-ended naming rather than a
    /// yes/no question — handing a small model the expected answer biases it
    /// toward agreement (same reason scorePronunciation hides the target).
    func recognizeObject(image: Data, target: VocabItem) async throws -> VisionResult {
        try await ensureReady()
        let prompt = """
        Look at this photo. What is the main object in it? \
        Answer with just one or two words in English, all lowercase, no \
        punctuation, no description, no sentence.
        If you cannot tell, respond with exactly: none
        Respond on a single line.
        """
        let raw = try await repo.inferImage(imageData: image, prompt: prompt)
        let recognized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let matched = Self.objectMatches(recognized: recognized, target: target.en)
        print("[QuackGemma] recognizeObject target=\(target.en) raw='\(recognized)' matched=\(matched)")
        return VisionResult(recognized: recognized, matched: matched)
    }

    /// Decides whether Gemma's recognized object name matches the target
    /// English word. Lenient on purpose — kids' framing tolerates "a cat" or
    /// "grapes" for "grape". Returns false when the model signaled "none".
    static func objectMatches(recognized rawRecognized: String, target rawTarget: String) -> Bool {
        let recognized = normalize(rawRecognized)
        let target = normalize(rawTarget)
        if recognized.isEmpty || recognized == "none" || recognized.contains("none") {
            return false
        }
        guard !target.isEmpty else { return false }
        // normalize() strips to a–z and drops spaces, so "a cat" -> "acat";
        // containment in either direction catches articles, plurals, and
        // compound answers ("red apple").
        if recognized.contains(target) || target.contains(recognized) {
            return true
        }
        // Fuzzy fallback tolerates a near-miss spelling of the same word.
        let distance = levenshtein(recognized, target)
        let maxLen = max(recognized.count, target.count)
        guard maxLen > 0 else { return false }
        let similarity = 1.0 - Double(distance) / Double(maxLen)
        return similarity >= 0.8
    }
```

Note: `normalize` and `levenshtein` are existing `private static` helpers in the same type — `objectMatches` can call them directly.

- [ ] **Step 2: Build**

Build the project. Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add quack/AI/QuackGemma.swift
git commit -m "feat: add Gemma object recognition use case (quack-app-oe3)"
```

---

### Task 5: Create the `CameraCapture` component

**Files:**
- Create: `quack/AI/CameraCapture.swift`

- [ ] **Step 1: Write the camera capture component and SwiftUI preview**

Create `quack/AI/CameraCapture.swift` with this exact content:

```swift
import AVFoundation
import SwiftUI
import UIKit

/// Single-shot still-image camera for the Camera Mission. Owns an
/// AVCaptureSession, exposes a SwiftUI live preview, and captures one
/// downscaled JPEG on demand. Analogous to MicRecorder for audio.
@MainActor
final class CameraCapture: NSObject {
    enum CaptureError: LocalizedError {
        case permissionDenied
        case unavailable
        case captureFailed(String)

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Camera access was denied. Enable it in Settings to play Scan it."
            case .unavailable:
                return "No camera is available on this device."
            case .captureFailed(let detail):
                return "Could not take the photo: \(detail)"
            }
        }
    }

    /// The session backing the live preview. Read-only to callers.
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var configured = false
    private var captureContinuation: CheckedContinuation<Data, Error>?

    /// True when this device actually has a usable camera (false in Simulator).
    var isAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    /// Requests camera permission, returning the final granted state.
    func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    /// Wires up the back camera and photo output. Safe to call repeatedly.
    func configure() throws {
        guard !configured else { return }
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)
        else {
            throw CaptureError.unavailable
        }
        session.beginConfiguration()
        session.sessionPreset = .photo
        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            session.commitConfiguration()
            throw CaptureError.captureFailed(error.localizedDescription)
        }
        guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            throw CaptureError.unavailable
        }
        session.addInput(input)
        session.addOutput(photoOutput)
        session.commitConfiguration()
        configured = true
    }

    /// Starts the capture session on a background queue (startRunning blocks).
    func start() {
        guard configured else { return }
        let session = self.session
        Task.detached { if !session.isRunning { session.startRunning() } }
    }

    /// Stops the capture session on a background queue.
    func stop() {
        let session = self.session
        Task.detached { if session.isRunning { session.stopRunning() } }
    }

    /// Captures one still photo and returns it as a downscaled JPEG.
    func capturePhoto() async throws -> Data {
        guard configured else { throw CaptureError.unavailable }
        return try await withCheckedThrowingContinuation { continuation in
            self.captureContinuation = continuation
            self.photoOutput.capturePhoto(
                with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    /// Downscales a UIImage so its longest side is at most `maxDimension`,
    /// then JPEG-encodes it. Full-resolution photos waste vision-encoder time.
    fileprivate static func downscaledJPEG(_ image: UIImage, maxDimension: CGFloat) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

extension CameraCapture: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            guard let continuation = self.captureContinuation else { return }
            self.captureContinuation = nil
            if let error {
                continuation.resume(
                    throwing: CaptureError.captureFailed(error.localizedDescription))
                return
            }
            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data),
                  let jpeg = Self.downscaledJPEG(image, maxDimension: 768)
            else {
                continuation.resume(
                    throwing: CaptureError.captureFailed("Could not encode photo"))
                return
            }
            continuation.resume(returning: jpeg)
        }
    }
}

/// SwiftUI live-camera preview backed by an AVCaptureVideoPreviewLayer.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
```

- [ ] **Step 2: Build**

Build the project. Expected: BUILD SUCCEEDED. (The new file joins the target automatically via the synchronized file group.)

- [ ] **Step 3: Commit**

```bash
git add quack/AI/CameraCapture.swift
git commit -m "feat: add CameraCapture component with SwiftUI preview (quack-app-oe3)"
```

---

### Task 6: Rewrite `CameraMissionView`

**Files:**
- Modify: `quack/CameraMissionView.swift`

This task replaces the faked scan-detection logic with real capture + Gemma verification and wires the "Hear it" button. It is a near-total rewrite of the view struct; the `CameraCornerBrackets` helper and `#Preview` at the bottom of the file are unchanged.

- [ ] **Step 1: Replace the `CameraMissionView` struct**

In `quack/CameraMissionView.swift`, replace the entire `struct CameraMissionView: View { ... }` block (lines 3-187 — everything from `struct CameraMissionView` down to its closing brace, but NOT the `private struct CameraCornerBrackets` or the `#Preview` that follow) with:

```swift
struct CameraMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase: CameraPhase = .scan
    @State private var camera = CameraCapture()
    @State private var cameraReady = false
    @State private var errorMessage: String?
    @State private var tryAgainMessage: String?
    @State private var checkTask: Task<Void, Never>?
    @State private var waveAnimating = false

    enum CameraPhase { case scan, checking, word, listen }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Scan it", onBack: { dismiss() })

                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Camera mission", flank: false, size: 11)
                    Text("Find the \(vocab.en.lowercased())")
                        .font(.display(24, weight: .heavy))
                        .foregroundStyle(Color.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                switch phase {
                case .scan, .checking: scanPhaseView
                case .word:            wordPhaseView
                case .listen:          listenPhaseView
                }

                Spacer()

                if phase == .scan || phase == .checking {
                    CTAButton(
                        label: phase == .checking ? "Looking..." : "I found it!",
                        variant: .ink,
                        disabled: !cameraReady || phase == .checking,
                        action: { captureAndCheck() }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                } else if phase == .word {
                    CTAButton(label: "Got it", variant: .ink, action: advanceToListen)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
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

    // MARK: Scan phase
    private var scanPhaseView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.ink)
                .grain(opacity: 0.12)

            if camera.isAvailable {
                CameraPreview(session: camera.session)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                // Simulator / no-camera fallback so the build still runs.
                VStack(spacing: 8) {
                    QuackIcon(name: .camera, size: 36, color: .white)
                    Text("Camera unavailable here")
                        .font(.bodyText(12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            CameraCornerBrackets()

            if phase == .checking {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.ink.opacity(0.45))
                VStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Looking...")
                        .font(.bodyText(13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .overlay(alignment: .bottom) {
            if let message = errorMessage ?? tryAgainMessage {
                Text(message)
                    .font(.bodyText(12, weight: .bold))
                    .foregroundStyle(Color.quackOrange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .cardShadow()
                    .padding(.horizontal, 36)
                    .padding(.bottom, 20)
                    .transition(.opacity)
            }
        }
    }

    // MARK: Word phase
    private var wordPhaseView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.paper)
                .cardShadow()

            VStack(spacing: 12) {
                Mascot(state: .speaking, size: 80)

                Text(vocab.hanzi)
                    .font(.display(48, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text(vocab.pinyin)
                    .font(.bodyText(16, weight: .bold))
                    .foregroundStyle(Color.inkMuted)

                Button { SpeechSpeaker.shared.speak(vocab.hanzi) } label: {
                    HStack(spacing: 8) {
                        QuackIcon(name: .speaker, size: 20, color: .white)
                        Text("Hear it")
                            .font(.bodyText(13, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.ink)
                    .clipShape(Capsule())
                }
                .buttonStyle(TapPress())
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: Listen phase
    private var listenPhaseView: some View {
        VStack(spacing: 28) {
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    WaveBar(index: i, animating: waveAnimating)
                }
            }
            .frame(height: 60)

            Button { onComplete(vocab.id) } label: {
                Circle()
                    .fill(Color.quackOrange)
                    .frame(width: 80, height: 80)
                    .overlay(QuackIcon(name: .mic, size: 36, color: .white, strokeWidth: 2.2))
                    .popShadow()
            }
            .buttonStyle(TapPress())

            Text("Tap mic when done")
                .font(.bodyText(13, weight: .bold))
                .foregroundStyle(Color.inkMuted)
        }
        .padding(.top, 48)
        .onAppear { waveAnimating = true }
    }

    // MARK: Actions

    private func prepareCamera() async {
        guard camera.isAvailable else { return }
        let granted = await camera.requestPermission()
        guard granted else {
            errorMessage = "Quack needs the camera. Enable it in Settings."
            return
        }
        do {
            try camera.configure()
            camera.start()
            cameraReady = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func captureAndCheck() {
        errorMessage = nil
        tryAgainMessage = nil
        phase = .checking
        checkTask?.cancel()
        checkTask = Task {
            do {
                let image = try await camera.capturePhoto()
                let result = try await QuackGemma.shared.recognizeObject(
                    image: image, target: vocab
                )
                guard !Task.isCancelled else { return }
                if result.matched {
                    camera.stop()
                    withAnimation { phase = .word }
                } else {
                    let seen = result.recognized.isEmpty ? "something else" : result.recognized
                    tryAgainMessage = "Hmm, I see \(seen). Point at the \(vocab.en.lowercased())!"
                    withAnimation { phase = .scan }
                }
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                withAnimation { phase = .scan }
            }
        }
    }

    private func advanceToListen() {
        SpeechSpeaker.shared.stop()
        withAnimation { phase = .listen }
    }
}
```

- [ ] **Step 2: Verify the `CameraCornerBrackets` helper and `#Preview` are intact**

Confirm the file still ends with the unchanged `private struct CameraCornerBrackets: View { ... }` and `#Preview { ... }` blocks. They are not modified by this task.

- [ ] **Step 3: Build**

Build the project. Expected: BUILD SUCCEEDED.

If `QuackIcon(name: .camera, ...)` fails to compile (no `.camera` icon case), replace that line in the no-camera fallback with `QuackIcon(name: .speaker, size: 36, color: .white)` — the fallback icon is cosmetic and only shows in the Simulator.

- [ ] **Step 4: Commit**

```bash
git add quack/CameraMissionView.swift
git commit -m "feat: wire Camera Mission to Gemma vision + TTS (quack-app-oe3)"
```

---

### Task 7: On-device verification and issue close

**Files:** none (verification + tracking).

- [ ] **Step 1: Build and run on a physical iOS device**

Camera hardware and the device-arm64 LiteRT-LM static lib mean this must run on a real device, not the Simulator.

- [ ] **Step 2: Walk the acceptance criteria**

Open a Camera Mission and confirm each:

1. Camera permission prompt appears on first run; granting it shows a live preview.
2. Point the camera at the **correct** object, tap "I found it!" → spinner "Looking..." → mission advances to the word card.
3. Point at a **wrong** object, tap "I found it!" → returns to scan with a "Hmm, I see ..." try-again message.
4. On the word card, tap "Hear it" → the target word is spoken in Mandarin.
5. Deny camera permission (Settings → Quack → Camera off, relaunch) → a friendly "Quack needs the camera" message shows, no crash.

If any check fails, debug with the systematic-debugging skill before closing the issue. Console logs `[QuackGemma] recognizeObject ...` show the raw model output and match decision.

- [ ] **Step 3: Close the issue and push**

```bash
bd close quack-app-oe3 --reason="Camera Mission wired to Gemma vision; manual on-device acceptance pass"
git pull --rebase
bd dolt push
git push
git status   # must show "up to date with origin"
```

---

## Self-Review

**Spec coverage:**
- Image inference plumbing (bridge → wrapper → repo → QuackGemma) → Tasks 1-4. ✓
- `CameraCapture` + `CameraPreview` → Task 5. ✓
- Scan-phase rewrite with real capture, `.checking` wait state, try-again → Task 6. ✓
- "Hear it" button wired to TTS → Task 6, `wordPhaseView`. ✓
- Permission denial handled → Task 6, `prepareCamera`. ✓
- Gemma-failure handling → Task 6, `captureAndCheck` catch. ✓
- `.listen` phase untouched → Task 6 keeps `listenPhaseView` and its `onComplete` call. ✓
- `NSCameraUsageDescription` already present → noted, no task. ✓
- Vision-modality enablement (the spec's "verify during implementation") → resolved: `SetVisionModalityEnabled` + `vision_backend: Backend::CPU`, Task 1. ✓
- Open-ended naming prompt, not yes/no → Task 4. ✓

**Type consistency:** `VisionResult`/`recognizeObject`/`objectMatches` (Task 4) are used verbatim in Task 6. `CameraCapture`/`CameraPreview`/`capturePhoto`/`isAvailable`/`requestPermission`/`configure`/`start`/`stop`/`session` (Task 5) are used verbatim in Task 6. `inferImage` (Task 3) ↔ `recognizeObject` (Task 4). `inferWithImagePath:prompt:` (Task 2) ↔ `inferImage` (Task 3). `inferWithImage` (Task 1) ↔ Task 2. Consistent.

**Placeholder scan:** No TBD/TODO; every code step shows complete code; the one conditional (`QuackIcon` `.camera` case) has an explicit concrete fallback.
