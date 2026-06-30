import SwiftUI

struct SnapPhotoView: View {
    var demoMode: Bool = false
    @Environment(\.dismiss) private var dismiss

    enum Phase { case compose, analyzing, result, error }

    @State private var phase: Phase = .compose
    @State private var camera = CameraCapture()
    @State private var cameraReady = false
    @State private var capturedImage: UIImage? = nil
    @State private var scanResult: QuackGemma.ScanResult? = nil
    @State private var errorMsg = ""
    @State private var dotScale = [false, false, false]
    @State private var cardIn = false
    @State private var isSaved = false
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    BackBtn(dark: true) { dismiss() }
                    Spacer()
                    if demoMode {
                        Text("Tutorial")
                            .font(.bodyText(12, weight: .bold))
                            .foregroundStyle(Color.quackOrange)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.quackOrange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 8)

                switch phase {
                case .compose:   composeView
                case .analyzing: analyzingView
                case .result:    resultView
                case .error:     errorView
                }

                Spacer()

                if phase == .compose {
                    CTAButton(label: "Scan it!", variant: .orange, disabled: !cameraReady) {
                        captureAndScan()
                    }
                    .padding(.horizontal, 24).padding(.bottom, 32)
                } else if phase == .result {
                    HStack(spacing: 12) {
                        CTAButton(label: demoMode ? "Done!" : "Scan again", variant: .ghost) {
                            if demoMode { dismiss() } else { reset() }
                        }
                        CTAButton(label: "Hear it!", variant: .orange) {
                            if let r = scanResult { SpeechSpeaker.shared.speak(r.hanzi) }
                        }
                    }
                    .padding(.horizontal, 24).padding(.bottom, 32)
                }
            }
        }
        .task { await prepareCamera() }
        .onDisappear { camera.stop(); SpeechSpeaker.shared.stop() }
    }

    // MARK: - Compose
    private var composeView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: demoMode ? "Demo · Point at anything nearby" : "Point at anything", flank: false, size: 11)
                Text(demoMode ? "What's around you?" : "What do you see?")
                    .font(.display(24, weight: .heavy)).foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24)

            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(Color.ink).grain(opacity: 0.12)
                if camera.isAvailable {
                    CameraPreview(previewLayer: camera.previewLayer, camera: camera)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    VStack(spacing: 8) {
                        QuackIcon(name: .camera, size: 36, color: .white)
                        Text("Camera unavailable").font(.bodyText(12, weight: .bold)).foregroundStyle(.white.opacity(0.8))
                    }
                }
                SnapCornerBrackets()
                if camera.isAvailable, camera.canFlip {
                    Button { try? camera.flipCamera() } label: {
                        Circle().fill(Color.ink.opacity(0.55)).frame(width: 44, height: 44)
                            .overlay(Image(systemName: "camera.rotate").font(.system(size: 18, weight: .bold)).foregroundStyle(.white))
                    }
                    .buttonStyle(TapPress())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(16)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 300).padding(.horizontal, 24)
        }
        .padding(.top, 8)
    }

    // MARK: - Analyzing
    private var analyzingView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Color.ink).grain(opacity: 0.12)
            VStack(spacing: 20) {
                Mascot(state: .speaking, size: 80)
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle().fill(Color.quackOrange).frame(width: 12, height: 12)
                            .scaleEffect(dotScale[i] ? 1.4 : 0.8)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.18), value: dotScale[i])
                    }
                }
                Text("Agent Q is thinking...").font(.display(16, weight: .heavy)).foregroundStyle(Color.cream)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300).padding(.horizontal, 24).padding(.top, 8)
        .onAppear { for i in 0..<3 { dotScale[i] = true } }
    }

    // MARK: - Result: collectible card
    private var resultView: some View {
        ScrollView(showsIndicators: false) {
            if let result = scanResult {
                CollectibleCard(result: result, image: capturedImage)
                    .scaleEffect(cardIn ? 1 : 0.88)
                    .opacity(cardIn ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: cardIn)
                    .onAppear { cardIn = true }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                // Save to collection
                if isSaved {
                    Label("Saved to your collection!", systemImage: "checkmark.circle.fill")
                        .font(.bodyText(13, weight: .bold))
                        .foregroundStyle(Color.mintDeep)
                } else {
                    Button {
                        let c = SavedCollectible.make(from: result, image: capturedImage)
                        appState.collectibles.append(c)
                        isSaved = true
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        Label("Save to Collection", systemImage: "square.and.arrow.down")
                            .font(.bodyText(13, weight: .heavy))
                            .foregroundStyle(Color.quackOrange)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Color.quackOrange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(TapPress())
                }

                if demoMode {
                    Text("You just completed your first scan!")
                        .font(.bodyText(14, weight: .bold))
                        .foregroundStyle(Color.quackOrange)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Error
    private var errorView: some View {
        VStack(spacing: 20) {
            Mascot(state: .idle, size: 100)
            Text(errorMsg)
                .font(.bodyText(14, weight: .bold)).foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            CTAButton(label: "Try again", variant: .orange) { reset() }
                .padding(.horizontal, 24)
        }
        .padding(.top, 40)
    }

    // MARK: - Actions
    private func prepareCamera() async {
        guard camera.isAvailable else { return }
        guard await camera.requestPermission() else { return }
        do {
            try camera.configure()
            camera.start()
            cameraReady = true
        } catch {
            errorMsg = error.localizedDescription
            phase = .error
        }
    }

    private func captureAndScan() {
        withAnimation { phase = .analyzing }
        Task {
            do {
                let jpeg = try await camera.capturePhoto()
                capturedImage = UIImage(data: jpeg)
                camera.stop()
                let result = try await QuackGemma.shared.freeScanner(image: jpeg)
                withAnimation { scanResult = result; phase = .result }
            } catch {
                errorMsg = error.localizedDescription
                withAnimation { phase = .error }
            }
        }
    }

    private func reset() {
        cardIn = false; capturedImage = nil; scanResult = nil; isSaved = false; phase = .compose
        Task { await prepareCamera() }
    }
}

// MARK: - Collectible card (Quack Collectible trading card style)
struct CollectibleCard: View {
    let result: QuackGemma.ScanResult
    let image: UIImage?

    private var rarity: Rarity { Rarity.make(for: result.en) }
    private var cardNumber: String {
        var h: UInt64 = 5381
        for c in result.en.utf8 { h = h &* 31 &+ UInt64(c) }
        return "#Q\(String(format: "%03d", Int(h % 999) + 1))"
    }

    // Interactive tilt
    @GestureState private var tilt: CGSize = .zero
    // Shimmer
    @State private var shimmerX: CGFloat = -0.4

    var body: some View {
        cardContent
            // 3D tilt from drag — both axes, springs back on release
            .rotation3DEffect(.degrees(-Double(tilt.height) / 12), axis: (1, 0, 0), perspective: 0.4)
            .rotation3DEffect(.degrees( Double(tilt.width)  / 12), axis: (0, 1, 0), perspective: 0.4)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($tilt) { v, s, _ in s = v.translation }
            )
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.6), value: tilt)
    }

    private var cardContent: some View {
        VStack(spacing: 0) {
            // Header — rarity-colored
            HStack(spacing: 8) {
                Image("icon-agent-q")
                    .resizable().scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
                Text("QUACK COLLECTIBLE")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(rarity.accentColor)
                    .frame(maxWidth: .infinity)
                // Rarity badge
                Text(rarity.displayName)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(rarity == .common ? Color.ink : rarity.accentColor)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(rarity.accentColor.opacity(rarity == .common ? 0 : 0.15))
                    .overlay(Capsule().stroke(rarity.accentColor.opacity(0.5), lineWidth: 1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(rarity.headerBg)

            // Sub-header: name + EXP
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(result.en.uppercased())
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    Text("TYPE: \(result.itemClass)")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("EXP")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(Color.inkMuted)
                    Text("\(rarity.exp)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(rarity.accentColor)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.cream)

            // Illustration
            ZStack {
                rarity.accentColor.opacity(0.12)

                if let img = image {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipped()
                } else {
                    Color.inkFaint.frame(height: 200)
                }

                // Moving shimmer on the illustration
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.28), .clear],
                    startPoint: UnitPoint(x: shimmerX, y: 0),
                    endPoint: UnitPoint(x: shimmerX + 0.35, y: 1)
                )
                .allowsHitTesting(false)

                // Chips
                VStack {
                    Spacer()
                    HStack {
                        Text(result.itemClass)
                            .font(.system(size: 8, weight: .black)).tracking(1)
                            .foregroundStyle(Color.paper)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.ink.opacity(0.75))
                            .clipShape(Capsule())
                        Spacer()
                        Text("MANDARIN")
                            .font(.system(size: 8, weight: .black)).tracking(1)
                            .foregroundStyle(Color.paper)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.quackOrange)
                            .clipShape(Capsule())
                    }
                    .padding(10)
                }
            }
            .frame(height: 200)

            // Chinese info
            VStack(spacing: 4) {
                Text(result.hanzi)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.ink)
                HStack(spacing: 8) {
                    Text(result.pinyin)
                        .font(.bodyText(15, weight: .bold)).foregroundStyle(Color.inkMuted)
                    Text("·")
                        .foregroundStyle(Color.inkFaint)
                    Text(result.en.capitalized)
                        .font(.bodyText(14, weight: .bold)).foregroundStyle(Color.ink)
                }
            }
            .padding(.vertical, 14).padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(Color.paper)

            // Fun fact
            if !result.funFact.isEmpty {
                Text(result.funFact)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.creamDeep)
            }

            // Footer: stars + card number
            HStack(spacing: 0) {
                // Stars for rarity
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        Image(systemName: i < rarity.stars ? "star.fill" : "star")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(i < rarity.stars ? rarity.accentColor : Color.inkFaint)
                    }
                }
                Text("  \(cardNumber)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.inkMuted)
                Spacer()
                Image("icon-agent-q")
                    .resizable().scaledToFit().frame(width: 14, height: 14).clipShape(Circle())
                Text("  Quack Collectible")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.cream)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [rarity.accentColor, rarity.accentColor.opacity(0.4), rarity.accentColor],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: rarity == .legendary ? 3.5 : 2.5
                )
        )
        .shadow(color: rarity.accentColor.opacity(rarity == .common ? 0.1 : 0.3), radius: 16, x: 0, y: 6)
        .shadow(color: Color.ink.opacity(0.08), radius: 3, x: 0, y: 2)
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                shimmerX = 1.4
            }
        }
    }
}


// MARK: - Corner brackets
private struct SnapCornerBrackets: View {
    var body: some View {
        GeometryReader { _ in
            Canvas { ctx, size in
                let br: CGFloat = 24; let lw: CGFloat = 3; let pad: CGFloat = 16
                let corners: [(CGPoint, CGFloat, CGFloat)] = [
                    (CGPoint(x: pad, y: pad), 1, 1),
                    (CGPoint(x: size.width - pad, y: pad), -1, 1),
                    (CGPoint(x: pad, y: size.height - pad), 1, -1),
                    (CGPoint(x: size.width - pad, y: size.height - pad), -1, -1),
                ]
                for (origin, dx, dy) in corners {
                    var p = Path()
                    p.move(to: CGPoint(x: origin.x + dx * br, y: origin.y))
                    p.addLine(to: origin)
                    p.addLine(to: CGPoint(x: origin.x, y: origin.y + dy * br))
                    ctx.stroke(p, with: .color(.quackOrange), style: StrokeStyle(lineWidth: lw, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    SnapPhotoView()
        .environment(AppState())
}
