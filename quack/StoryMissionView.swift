import SwiftUI
import AVFoundation

// MARK: - Story Mission View
struct StoryMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    enum Phase { case loading, page1, page2, missionBriefing, doingMission, victory }

    @State private var phase: Phase = .loading
    @State private var story: AdventureStory? = nil
    @State private var missionSuccess = false
    @State private var pageIn = false

    var body: some View {
        ZStack {
            // Warm book background
            Color(red: 0.99, green: 0.97, blue: 0.93).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                phaseContent
                Spacer(minLength: 0)
                bottomCTA
            }
        }
        .animation(.easeOut(duration: 0.35), value: phase)
        .task { await loadStory() }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
                    .frame(width: 34, height: 34)
                    .background(Color.inkFaint.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(TapPress())
            Spacer()
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    let step = phaseStep
                    Circle()
                        .fill(i <= step ? Color.mint : Color.inkFaint)
                        .frame(width: i == step ? 10 : 7, height: i == step ? 10 : 7)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: phase)
                }
            }
            Spacer()
            // Story type badge
            if let s = story, phase == .missionBriefing || phase == .doingMission {
                HStack(spacing: 4) {
                    Image(systemName: s.missionType.sfSymbol)
                        .font(.system(size: 10, weight: .bold))
                    Text(s.missionType.displayName)
                        .font(.bodyText(10, weight: .heavy))
                }
                .foregroundStyle(Color.mint)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.mint.opacity(0.15))
                .clipShape(Capsule())
            } else {
                Color.clear.frame(width: 70, height: 34)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16).padding(.bottom, 8)
    }

    private var phaseStep: Int {
        switch phase {
        case .loading: return 0
        case .page1: return 1
        case .page2: return 2
        case .missionBriefing: return 3
        case .doingMission: return 3
        case .victory: return 4
        }
    }

    // MARK: - Phase content
    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case .loading:
            loadingView
        case .page1:
            if let s = story { storyPage(text: s.setting, page: 0) }
        case .page2:
            if let s = story { storyPage(text: s.challenge, page: 1) }
        case .missionBriefing:
            if let s = story { missionBriefingView(story: s) }
        case .doingMission:
            if let s = story {
                switch s.missionType {
                case .scan:   inlineScanView
                case .match:  inlineMatchView
                case .speak:  inlineSpeakView
                }
            }
        case .victory:
            if let s = story { victoryView(story: s) }
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 20) {
            Mascot(state: .speaking, size: 100)
            Text("Agent Q is writing your adventure...")
                .font(.display(18, weight: .heavy)).foregroundStyle(Color.ink)
            ProgressView().tint(Color.mint)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    // MARK: - Story page
    private func storyPage(text: String, page: Int) -> some View {
        VStack(spacing: 16) {
            // Illustration area — placeholder for future artwork
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(vocab.tone.bg)
                    .grain(opacity: 0.08)
                Sparkles(count: 4, opacity: 0.35, animate: true)
                VStack(spacing: 8) {
                    Text(vocab.emoji)
                        .font(.system(size: 52))
                    Text(vocab.hanzi)
                        .font(.display(40, weight: .heavy))
                        .foregroundStyle(vocab.tone.fg)
                }
                // "Chapter" label
                Text("Chapter \(page + 1)")
                    .font(.bodyText(10, weight: .heavy))
                    .foregroundStyle(vocab.tone.fg.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(14)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .popShadow()

            // Story narration card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.mintDeep)
                    Text("Parent reads aloud")
                        .font(.bodyText(10, weight: .heavy))
                        .foregroundStyle(Color.mintDeep)
                }
                Text(text)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundStyle(Color.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // Hear it button
                Button {
                    SpeechSpeaker.shared.speak(text)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Read aloud")
                            .font(.bodyText(12, weight: .heavy))
                    }
                    .foregroundStyle(Color.mintDeep)
                }
                .buttonStyle(TapPress())
            }
            .padding(18)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .cardShadow()
        }
        .padding(.horizontal, 20)
        .offset(y: pageIn ? 0 : 20)
        .opacity(pageIn ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { pageIn = true } }
        .onDisappear { pageIn = false }
    }

    // MARK: - Mission briefing
    private func missionBriefingView(story: AdventureStory) -> some View {
        VStack(spacing: 20) {
            // Mission banner
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.mint)
                    .grain(opacity: 0.08)
                Sparkles(count: 5, color: .white, opacity: 0.5, animate: true)
                VStack(spacing: 10) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color.paper)
                    Text("YOUR MISSION")
                        .font(.system(size: 11, weight: .black))
                        .tracking(3)
                        .foregroundStyle(Color.paper.opacity(0.85))
                    Text(story.missionType.displayName)
                        .font(.display(28, weight: .heavy))
                        .foregroundStyle(Color.paper)
                    HStack(spacing: 8) {
                        Image(systemName: story.missionType.sfSymbol)
                        Text(story.missionType.displayName)
                            .font(.bodyText(14, weight: .heavy))
                    }
                    .foregroundStyle(Color.paper.opacity(0.8))
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
                .padding(.vertical, 28)
            }
            .frame(maxWidth: .infinity)
            .popShadow()

            // Word to learn
            VStack(spacing: 8) {
                Text("Learn this word:")
                    .font(.bodyText(12)).foregroundStyle(Color.inkMuted)
                HStack(spacing: 12) {
                    Text(vocab.hanzi)
                        .font(.display(40, weight: .heavy)).foregroundStyle(Color.ink)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vocab.pinyin)
                            .font(.bodyText(15, weight: .bold)).foregroundStyle(Color.inkMuted)
                        Text(vocab.en.capitalized)
                            .font(.bodyText(14, weight: .bold)).foregroundStyle(Color.ink)
                    }
                    Button {
                        SpeechSpeaker.shared.speak(vocab.hanzi)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.mint)
                    }
                    .buttonStyle(TapPress())
                }

                // Parent hint
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11)).foregroundStyle(Color.cobalt)
                    Text(story.missionHint)
                        .font(.bodyText(11)).foregroundStyle(Color.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Color.cobalt.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(18)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .cardShadow()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Victory
    private func victoryView(story: AdventureStory) -> some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.quackYellow)
                    .grain(opacity: 0.08)
                Confetti(count: 20)
                VStack(spacing: 10) {
                    Mascot(state: .celebrating, size: 110)
                    Text("Adventure Complete!")
                        .font(.display(22, weight: .heavy))
                        .foregroundStyle(Color.ink)
                }
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity)
            .popShadow()

            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 11)).foregroundStyle(Color.quackOrange)
                    Text("The story ends...")
                        .font(.bodyText(10, weight: .heavy)).foregroundStyle(Color.quackOrange)
                }
                Text(story.victory)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(Color.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                Divider().padding(.vertical, 4)
                HStack(spacing: 8) {
                    Text(vocab.hanzi).font(.display(28, weight: .heavy)).foregroundStyle(Color.ink)
                    Text("=").font(.bodyText(14)).foregroundStyle(Color.inkMuted)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(vocab.pinyin).font(.bodyText(13, weight: .bold)).foregroundStyle(Color.inkMuted)
                        Text(vocab.en.capitalized).font(.bodyText(14, weight: .heavy)).foregroundStyle(Color.ink)
                    }
                }
            }
            .padding(18)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .cardShadow()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Bottom CTA
    @ViewBuilder
    private var bottomCTA: some View {
        switch phase {
        case .loading:
            EmptyView()
        case .page1:
            CTAButton(label: "Continue the story", variant: .ghost, action: advance)
                .padding(.horizontal, 20).padding(.bottom, 32)
        case .page2:
            CTAButton(label: "Start my mission!", variant: .orange, action: advance)
                .padding(.horizontal, 20).padding(.bottom, 32)
        case .missionBriefing:
            CTAButton(label: "I am ready!", variant: .orange, action: advance)
                .padding(.horizontal, 20).padding(.bottom, 32)
        case .doingMission:
            EmptyView()  // CTA is inside each inline mission
        case .victory:
            CTAButton(label: "Collect reward!", variant: .ink) {
                appState.lastMissionStars = 3
                onComplete(vocab.id)
            }
            .padding(.horizontal, 20).padding(.bottom, 32)
        }
    }

    private func advance() {
        switch phase {
        case .page1:    withAnimation { phase = .page2 }
        case .page2:    withAnimation { phase = .missionBriefing }
        case .missionBriefing: withAnimation { phase = .doingMission }
        default: break
        }
    }

    // MARK: - Load story
    private func loadStory() async {
        do {
            let s = try await QuackGemma.shared.generateAdventureStory(
                target: vocab, childName: appState.name, gender: appState.gender
            )
            await MainActor.run { story = s; withAnimation { phase = .page1 } }
        } catch {
            await MainActor.run {
                story = AdventureStory.offline(target: vocab, name: appState.name, gender: appState.gender)
                withAnimation { phase = .page1 }
            }
        }
    }

    // MARK: - Inline scan mission
    @State private var scanCamera = CameraCapture()
    @State private var scanReady = false
    @State private var scanPhase: InlineScanPhase = .idle
    @State private var scanDots = [false, false, false]
    @State private var scanError: String? = nil
    enum InlineScanPhase { case idle, checking, success, failed }

    private var inlineScanView: some View {
        VStack(spacing: 14) {
            // Camera
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color.ink).grain(opacity: 0.1)
                if scanCamera.isAvailable {
                    CameraPreview(previewLayer: scanCamera.previewLayer, camera: scanCamera)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                // Corner brackets
                Canvas { ctx, size in
                    let br: CGFloat = 20; let lw: CGFloat = 2.5; let pad: CGFloat = 12
                    for (origin, dx, dy) in [
                        (CGPoint(x: pad, y: pad), 1.0, 1.0),
                        (CGPoint(x: size.width-pad, y: pad), -1.0, 1.0),
                        (CGPoint(x: pad, y: size.height-pad), 1.0, -1.0),
                        (CGPoint(x: size.width-pad, y: size.height-pad), -1.0, -1.0)
                    ] {
                        var p = Path()
                        p.move(to: CGPoint(x: origin.x + dx * br, y: origin.y))
                        p.addLine(to: origin)
                        p.addLine(to: CGPoint(x: origin.x, y: origin.y + dy * br))
                        ctx.stroke(p, with: .color(.mint), style: StrokeStyle(lineWidth: lw, lineCap: .round))
                    }
                }
                .allowsHitTesting(false)

                if scanPhase == .checking {
                    RoundedRectangle(cornerRadius: 18).fill(Color.ink.opacity(0.5))
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle().fill(Color.mint).frame(width: 10, height: 10)
                                    .scaleEffect(scanDots[i] ? 1.4 : 0.8)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i)*0.18), value: scanDots[i])
                            }
                        }
                        Text("Q is looking...").font(.display(14, weight: .heavy)).foregroundStyle(Color.mint)
                    }
                }
                if let err = scanError {
                    VStack {
                        Spacer()
                        Text(err).font(.bodyText(11, weight: .bold)).foregroundStyle(Color.quackOrange)
                            .padding(10).background(Color.paper).clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(12)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 220)

            // Hint
            HStack(spacing: 6) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 12)).foregroundStyle(Color.mint)
                Text("Point at a real \(vocab.en.lowercased()) and tap the button!")
                    .font(.bodyText(12)).foregroundStyle(Color.inkMuted)
            }

            // Buttons
            HStack(spacing: 10) {
                CTAButton(label: "I found it!", variant: .orange, disabled: !scanReady || scanPhase == .checking) {
                    doScan()
                }
                Button("Skip") {
                    withAnimation { phase = .victory }
                }
                .font(.bodyText(13, weight: .heavy))
                .foregroundStyle(Color.inkMuted)
                .buttonStyle(TapPress())
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
        .task { await prepScan() }
        .onDisappear { scanCamera.stop() }
    }

    private func prepScan() async {
        guard scanCamera.isAvailable else { return }
        guard await scanCamera.requestPermission() else { return }
        try? scanCamera.configure(); scanCamera.start(); scanReady = true
    }

    private func doScan() {
        scanError = nil; scanPhase = .checking
        for i in 0..<3 { scanDots[i] = true }
        Task {
            do {
                let jpeg = try await scanCamera.capturePhoto()
                let result = try await QuackGemma.shared.recognizeObject(image: jpeg, target: vocab)
                await MainActor.run {
                    scanPhase = result.matched ? .success : .failed
                    if result.matched {
                        scanCamera.stop()
                        withAnimation { phase = .victory }
                    } else {
                        let seen = result.recognized.isEmpty ? "something else" : result.recognized
                        scanError = "I see \(seen) — find the \(vocab.en.lowercased())!"
                        scanPhase = .idle
                    }
                }
            } catch {
                await MainActor.run { scanError = error.localizedDescription; scanPhase = .idle }
            }
        }
    }

    // MARK: - Inline match mission
    @State private var matchChoices: [VocabItem] = []
    @State private var matchSelected: String? = nil
    @State private var matchRevealed = false

    private var inlineMatchView: some View {
        VStack(spacing: 14) {
            // Prompt
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color.ink).grain(opacity: 0.1)
                VStack(spacing: 4) {
                    Text(vocab.hanzi).font(.display(52, weight: .heavy)).foregroundStyle(Color.paper)
                    Text("Which one is this?").font(.bodyText(13)).foregroundStyle(Color.paper.opacity(0.6))
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, minHeight: 110)

            // 3 choices
            let choices = matchChoices.isEmpty ? makeMatchChoices() : matchChoices
            ForEach(choices) { choice in
                let isCorrect = choice.id == vocab.id
                let isSelected = matchSelected == choice.id
                Button {
                    guard !matchRevealed else { return }
                    matchSelected = choice.id
                    withAnimation { matchRevealed = true }
                    UIImpactFeedbackGenerator(style: isCorrect ? .medium : .rigid).impactOccurred()
                    if isCorrect {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { phase = .victory }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        ObjectArt(vocab: choice, size: 46)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(choice.en.capitalized).font(.bodyText(14, weight: .heavy)).foregroundStyle(Color.ink)
                            Text(choice.pinyin).font(.bodyText(11)).foregroundStyle(Color.inkMuted)
                        }
                        Spacer()
                        if matchRevealed && isSelected {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(isCorrect ? Color.mintDeep : Color.quackOrange)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(matchRevealed && isSelected ? (isCorrect ? Color.mint.opacity(0.2) : Color.rose.opacity(0.15)) : Color.paper)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(matchRevealed && isSelected ? (isCorrect ? Color.mintDeep : Color.quackOrange) : Color.inkFaint, lineWidth: 1.5))
                    )
                    .cardShadow()
                }
                .buttonStyle(TapPress())
                .disabled(matchRevealed)
            }

            if matchRevealed && matchSelected != vocab.id {
                CTAButton(label: "Try again", variant: .ghost) {
                    matchSelected = nil; matchRevealed = false
                    matchChoices = makeMatchChoices()
                }
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 20)
        .onAppear { matchChoices = makeMatchChoices() }
    }

    private func makeMatchChoices() -> [VocabItem] {
        let others = VOCAB.filter { $0.id != vocab.id }.shuffled().prefix(2)
        return ([vocab] + others).shuffled()
    }

    // MARK: - Inline speak mission
    @State private var speakRecorder = MicRecorder()
    @State private var speakPhase: SpeakInlinePhase = .idle
    @State private var speakScore = 0
    enum SpeakInlinePhase { case idle, recording, scoring, done }

    private var inlineSpeakView: some View {
        VStack(spacing: 20) {
            // Word display
            VStack(spacing: 6) {
                Text(vocab.hanzi).font(.display(60, weight: .heavy)).foregroundStyle(Color.ink)
                Text(vocab.pinyin).font(.bodyText(18, weight: .bold)).foregroundStyle(Color.inkMuted)
                Text(vocab.en.capitalized).font(.bodyText(14, weight: .bold)).foregroundStyle(Color.inkMuted)
                Button {
                    SpeechSpeaker.shared.speak(vocab.hanzi)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 13, weight: .semibold))
                        Text("Hear it first").font(.bodyText(12, weight: .heavy))
                    }
                    .foregroundStyle(Color.cobalt)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Color.cobalt.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(TapPress())
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .cardShadow()

            // Mic / score
            if speakPhase == .done {
                VStack(spacing: 8) {
                    Text(speakScore >= 50 ? "Great job!" : "Keep trying!")
                        .font(.display(18, weight: .heavy))
                        .foregroundStyle(speakScore >= 50 ? Color.mintDeep : Color.quackOrange)
                    Text("\(speakScore)%")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(speakScore >= 50 ? Color.mintDeep : Color.quackOrange)
                    if speakScore >= 50 {
                        CTAButton(label: "Continue!", variant: .orange) {
                            appState.lastMissionStars = speakScore >= 70 ? 3 : 2
                            withAnimation { phase = .victory }
                        }
                    } else {
                        CTAButton(label: "Try again", variant: .ghost) {
                            speakPhase = .idle; speakScore = 0
                        }
                    }
                }
                .padding(.horizontal, 20)
            } else {
                Button {
                    speakPhase == .idle ? startSpeak() : stopSpeak()
                } label: {
                    ZStack {
                        Circle().fill(speakPhase == .recording ? Color.quackOrange : Color.cobalt)
                            .frame(width: 80, height: 80)
                        Image(systemName: speakPhase == .recording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Color.paper)
                    }
                    .cardShadow()
                    .scaleEffect(speakPhase == .recording ? 1.08 : 1)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speakPhase == .recording)
                }
                .buttonStyle(TapPress())
                .disabled(speakPhase == .scoring)

                Text(speakPhase == .recording ? "Tap to stop" : speakPhase == .scoring ? "Scoring..." : "Tap to say it!")
                    .font(.bodyText(13, weight: .bold)).foregroundStyle(Color.inkMuted)

                Button("Skip this time") {
                    appState.lastMissionStars = 1
                    withAnimation { phase = .victory }
                }
                .font(.bodyText(12)).foregroundStyle(Color.inkMuted)
                .buttonStyle(TapPress())
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 20)
    }

    private func startSpeak() {
        speakPhase = .recording
        try? speakRecorder.start()
    }

    private func stopSpeak() {
        speakPhase = .scoring
        let pcm = (try? speakRecorder.stop()) ?? Data()
        Task {
            do {
                let result = try await QuackGemma.shared.scorePronunciation(audio: pcm, target: vocab)
                await MainActor.run { speakScore = result.score; speakPhase = .done }
            } catch {
                await MainActor.run { speakScore = 0; speakPhase = .idle }
            }
        }
    }
}

#Preview {
    StoryMissionView(vocab: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
