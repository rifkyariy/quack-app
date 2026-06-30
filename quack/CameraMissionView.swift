import SwiftUI

struct CameraMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var phase: CameraPhase = .scan
    @State private var camera = CameraCapture()
    @State private var cameraReady = false
    @State private var errorMessage: String?
    @State private var tryAgainMessage: String?
    @State private var checkTask: Task<Void, Never>?

    // Captured image (stored on match, shown through word + listen phases)
    @State private var capturedImage: UIImage? = nil

    // Listen / pronunciation
    @State private var recorder = MicRecorder()
    @State private var listenPhase: ListenPhase = .idle
    @State private var pronounceScore = 0
    @State private var syllableOK = false
    @State private var toneOK = false
    @State private var toneHint = ""
    @State private var heardPinyin = ""  // raw transcription from Gemma

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }

    enum CameraPhase { case scan, checking, word, listen }
    enum ListenPhase  { case idle, recording, scoring, result }

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
            if listenPhase == .recording { _ = try? recorder.stop() }
        }
    }

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

    // MARK: Scan phase
    private var scanPhaseView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.ink)
                .grain(opacity: 0.12)

            if camera.isAvailable {
                CameraPreview(previewLayer: camera.previewLayer, camera: camera)
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

            if camera.isAvailable, camera.canFlip, phase == .scan {
                Button { flipCamera() } label: {
                    Circle()
                        .fill(Color.ink.opacity(0.55))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
                .buttonStyle(TapPress())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)
            }

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

    // MARK: Word phase — captured image + word info
    private var wordPhaseView: some View {
        VStack(spacing: 14) {
            // Captured object photo
            if let img = capturedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.mintDeep.opacity(0.4), lineWidth: 2)
                    )
                    .cardShadow()
            }

            // Word card
            VStack(spacing: 10) {
                Text(vocab.hanzi)
                    .font(.display(52, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text(vocab.pinyin)
                    .font(.bodyText(17, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
                Text(vocab.en.capitalized)
                    .font(.bodyText(14, weight: .bold))
                    .foregroundStyle(Color.inkMuted)

                hearItButton
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .cardShadow()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: Listen phase
    private var listenPhaseView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // Compact photo + word bar
                HStack(spacing: 12) {
                    if let img = capturedImage {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vocab.hanzi)
                            .font(.display(22, weight: .heavy)).foregroundStyle(Color.ink)
                        Text("\(vocab.pinyin)  ·  \(vocab.en.capitalized)")
                            .font(.bodyText(12)).foregroundStyle(Color.inkMuted)
                    }
                    Spacer()
                    hearItButton
                }
                .padding(14)
                .background(Color.paper)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .cardShadow()

                // Phase content
                switch listenPhase {
                case .idle, .recording:
                    micPanel

                case .scoring:
                    VStack(spacing: 12) {
                        ProgressView().tint(Color.quackOrange).scaleEffect(1.3)
                        Text("Grading your pronunciation...")
                            .font(.bodyText(13)).foregroundStyle(Color.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .cardShadow()

                case .result:
                    pronunciationResult
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    // MARK: Mic panel (shared design)
    private var micPanel: some View {
        VStack(spacing: 20) {
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    WaveBar(index: i, animating: listenPhase == .recording)
                }
            }
            .frame(height: 44)

            Button {
                listenPhase == .idle ? startRecording() : stopRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(listenPhase == .recording ? Color.quackOrange : Color.ink)
                        .frame(width: 80, height: 80)
                    Image(systemName: listenPhase == .recording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color.paper)
                }
                .popShadow()
                .scaleEffect(listenPhase == .recording ? 1.06 : 1)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                           value: listenPhase == .recording)
            }
            .buttonStyle(TapPress())

            Text(listenPhase == .recording ? "Tap to stop recording" : "Tap mic and say it!")
                .font(.bodyText(13, weight: .bold)).foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .cardShadow()
    }

    // MARK: Pronunciation result
    private var pronunciationResult: some View {
        VStack(spacing: 0) {
            // Score header
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Color.inkFaint, lineWidth: 7).frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: CGFloat(pronounceScore) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 72, height: 72)
                        .animation(.easeOut(duration: 0.7), value: pronounceScore)
                    Text("\(pronounceScore)%")
                        .font(.display(18, weight: .heavy)).foregroundStyle(scoreColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(scoreHeadline)
                        .font(.display(16, weight: .heavy)).foregroundStyle(scoreColor)
                    HStack(spacing: 12) {
                        scorePill("Word", ok: syllableOK)
                        scorePill("Tone", ok: toneOK)
                    }
                }
                Spacer()
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            // What you said vs correct
            VStack(alignment: .leading, spacing: 8) {
                Label("What Q heard", systemImage: "ear.fill")
                    .font(.bodyText(11, weight: .heavy))
                    .foregroundStyle(Color.inkMuted)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("You said")
                            .font(.bodyText(10)).foregroundStyle(Color.inkMuted)
                        Text(heardPinyin.isEmpty ? "—" : heardPinyin)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(syllableOK ? Color.mintDeep : Color.quackOrange)
                    }
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12)).foregroundStyle(Color.inkFaint)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Correct")
                            .font(.bodyText(10)).foregroundStyle(Color.inkMuted)
                        Text(vocab.pinyin)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.mintDeep)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().padding(.horizontal, 16)

            // Advice tip
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13)).foregroundStyle(Color.quackYellow)
                    .padding(.top, 1)
                Text(pronunciationAdvice)
                    .font(.bodyText(13))
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.quackYellow.opacity(0.08))

            Divider()

            // Actions
            HStack(spacing: 10) {
                if pronounceScore < 70 {
                    CTAButton(label: "Try again", variant: .ghost) {
                        listenPhase = .idle
                    }
                }
                CTAButton(
                    label: "Complete mission",
                    variant: pronounceScore >= 70 ? .orange : .ink
                ) {
                    appState.lastMissionStars = pronounceScore >= 70 ? 3 : pronounceScore >= 50 ? 2 : 1
                    onComplete(vocab.id)
                }
            }
            .padding(14)
        }
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .cardShadow()
    }

    // MARK: Shared subviews
    private var hearItButton: some View {
        Button { SpeechSpeaker.shared.speak(vocab.hanzi) } label: {
            HStack(spacing: 5) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Hear it")
                    .font(.bodyText(12, weight: .heavy))
            }
            .foregroundStyle(Color.cobalt)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.cobalt.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(TapPress())
    }

    private var scoreColor: Color {
        pronounceScore >= 70 ? Color.mintDeep : pronounceScore >= 50 ? Color.quackOrange : Color.rose
    }

    private var scoreHeadline: String {
        if pronounceScore >= 90 { return "Perfect!" }
        if pronounceScore >= 70 { return "Great job!" }
        if pronounceScore >= 50 { return "Good try!" }
        return "Keep practising!"
    }

    // Computed pronunciation advice from result data — no extra LLM call needed
    private var pronunciationAdvice: String {
        if pronounceScore >= 90 {
            return "Excellent! Your pronunciation of \(vocab.pinyin) is spot on. \(vocab.hanzi) sounds natural!"
        }
        if pronounceScore >= 70 {
            if !toneOK { return toneHint.isEmpty
                ? "The syllables are right — focus on the tone now. Listen again and try to match the melody of the voice."
                : toneHint }
            return "Really solid! Repeat it a few more times to build muscle memory for \(vocab.pinyin)."
        }
        if !syllableOK {
            let parts = vocab.pinyin.split(separator: " ").map(String.init)
            if parts.count > 1 {
                return "Try breaking it down: say \"\(parts.joined(separator: "\" then \""))\" separately, then combine them."
            }
            return "Slow down and focus on the exact sounds: \(vocab.pinyin). Tap Hear it and repeat each sound."
        }
        if !toneOK {
            return toneHint.isEmpty
                ? "You got the sounds right! Now focus on the tone — Mandarin tones change the meaning completely."
                : toneHint
        }
        return "Listen carefully one more time, then try again. You're getting closer!"
    }

    private func scorePill(_ label: String, ok: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(ok ? Color.mintDeep : Color.quackOrange)
                .font(.system(size: 14))
            Text(label)
                .font(.bodyText(12, weight: .bold)).foregroundStyle(Color.ink)
        }
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
                    capturedImage = UIImage(data: image)
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

    private func flipCamera() {
        do {
            try camera.flipCamera()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func advanceToListen() {
        SpeechSpeaker.shared.stop()
        listenPhase = .idle
        withAnimation { phase = .listen }
    }

    private func startRecording() {
        listenPhase = .recording
        try? recorder.start()
    }

    private func stopRecording() {
        listenPhase = .scoring
        let pcm = (try? recorder.stop()) ?? Data()
        Task {
            do {
                let result = try await QuackGemma.shared.scorePronunciation(audio: pcm, target: vocab)
                await MainActor.run {
                    pronounceScore = result.score
                    syllableOK    = result.syllableOK
                    toneOK        = result.toneOK
                    toneHint      = result.toneHint
                    heardPinyin   = result.heard
                    withAnimation { listenPhase = .result }
                }
            } catch {
                await MainActor.run { listenPhase = .idle }
            }
        }
    }
}

// MARK: - Camera corner brackets
private struct CameraCornerBrackets: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let br: CGFloat = 24
                let lw: CGFloat = 3
                let pad: CGFloat = 16
                let corners: [(CGPoint, CGFloat, CGFloat)] = [
                    (CGPoint(x: pad, y: pad),                             1,  1),
                    (CGPoint(x: size.width - pad, y: pad),               -1,  1),
                    (CGPoint(x: pad, y: size.height - pad),               1, -1),
                    (CGPoint(x: size.width - pad, y: size.height - pad), -1, -1),
                ]
                for (origin, dx, dy) in corners {
                    var p = Path()
                    p.move(to: CGPoint(x: origin.x + dx * br, y: origin.y))
                    p.addLine(to: origin)
                    p.addLine(to: CGPoint(x: origin.x, y: origin.y + dy * br))
                    ctx.stroke(p, with: .color(.quackOrange),
                               style: StrokeStyle(lineWidth: lw, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    CameraMissionView(vocab: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
