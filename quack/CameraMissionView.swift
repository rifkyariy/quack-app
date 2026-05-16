import SwiftUI

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

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }

    enum CameraPhase { case scan, checking, word, listen }

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
                CameraPreview(previewLayer: camera.previewLayer)
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
