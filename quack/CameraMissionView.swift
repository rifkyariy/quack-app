import SwiftUI

struct CameraMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase: CameraPhase = .scan
    @State private var scanProgress: CGFloat = 0
    @State private var showDetection = false
    @State private var waveAnimating = false

    enum CameraPhase { case scan, word, listen }

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
                case .scan:   scanPhaseView
                case .word:   wordPhaseView
                case .listen: listenPhaseView
                }

                Spacer()

                if phase != .listen {
                    CTAButton(
                        label: phase == .scan ? "I found it!" : "Got it",
                        variant: .ink,
                        disabled: phase == .scan && !showDetection,
                        action: advancePhase
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private func advancePhase() {
        withAnimation(.easeOut(duration: 0.3)) {
            switch phase {
            case .scan:   phase = .word
            case .word:   phase = .listen
            case .listen: break
            }
        }
    }

    // MARK: Scan phase
    private var scanPhaseView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.ink)
                .grain(opacity: 0.12)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.quackOrange.opacity(0), .quackOrange, .quackOrange.opacity(0)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: scanProgress * 100 - 50)

            CameraCornerBrackets()

            if showDetection {
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Text(vocab.hanzi)
                                .font(.display(14, weight: .heavy))
                                .foregroundStyle(Color.ink)
                            Text(vocab.pinyin)
                                .font(.bodyText(11))
                                .foregroundStyle(Color.inkMuted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .cardShadow()
                        Spacer()
                    }
                    .padding(14)
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .topLeading)))

                ObjectArt(vocab: vocab, size: 90)
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: true)) {
                scanProgress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) { showDetection = true }
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

                Button {} label: {
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
