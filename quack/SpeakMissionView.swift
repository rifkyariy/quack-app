import SwiftUI

struct SpeakMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var wordIndex = 0
    @State private var phase: SpeakPhase = .idle
    @State private var score = 0
    @State private var heard: String = ""
    @State private var lastRecording: Data?
    @State private var waveAnimating = false
    @State private var errorMessage: String?
    @State private var recorder = MicRecorder()
    @State private var player = PCMPlayer()
    @State private var scoringTask: Task<Void, Never>?
    @State private var autoStopTask: Task<Void, Never>?

    private let maxRecordingSeconds: UInt64 = 4

    enum SpeakPhase { case idle, recording, scoring, result }

    private var words: [VocabItem] {
        var result = [vocab]
        let rest = VOCAB.filter { $0.cat == vocab.cat && $0.id != vocab.id }
        result += rest.prefix(2)
        if result.count < 3 {
            result += VOCAB.filter { $0.id != vocab.id && !result.map(\.id).contains($0.id) }.prefix(3 - result.count)
        }
        return Array(result.prefix(3))
    }

    private var current: VocabItem { words[min(wordIndex, words.count - 1)] }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Say it", accent: .cobalt, onBack: { dismiss() })

                // Word hero card
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

                // Mic card
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.paper)
                        .cardShadow()

                    micCardContent
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

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
        }
        .animation(.easeOut(duration: 0.25), value: phase)
        .onAppear { waveAnimating = true }
    }

    @ViewBuilder
    private var micCardContent: some View {
        switch phase {
        case .idle:
            VStack(spacing: 10) {
                Text(errorMessage ?? "Say it aloud")
                    .font(.bodyText(14, weight: .bold))
                    .foregroundStyle(errorMessage == nil ? Color.inkMuted : Color.quackOrange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                HStack(spacing: 18) {
                    Button { SpeechSpeaker.shared.speak(current.hanzi) } label: {
                        Circle()
                            .fill(Color.paper)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle().stroke(Color.cobalt.opacity(0.4), lineWidth: 2)
                            )
                            .overlay(QuackIcon(name: .speaker, size: 22, color: .cobalt, strokeWidth: 2.2))
                            .popShadow()
                    }
                    .buttonStyle(TapPress())
                    Button { Task { await startRecording() } } label: {
                        Circle()
                            .fill(Color.cobalt)
                            .frame(width: 64, height: 64)
                            .overlay(QuackIcon(name: .mic, size: 28, color: .white, strokeWidth: 2.2))
                            .popShadow()
                    }
                    .buttonStyle(TapPress())
                }
                Text("Hear it · Tap mic to try")
                    .font(.bodyText(11))
                    .foregroundStyle(Color.inkMuted.opacity(0.7))
            }
            .padding(20)

        case .recording:
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { i in
                        WaveBar(index: i, animating: waveAnimating, color: .cobalt)
                    }
                }
                .frame(height: 50)
                Button { stopRecording() } label: {
                    Pill(text: "Tap to stop", color: .cobalt, pulseDot: true)
                }
                .buttonStyle(TapPress())
            }
            .padding(20)

        case .scoring:
            VStack(spacing: 8) {
                ProgressView().tint(Color.cobalt)
                Text("Checking...")
                    .font(.bodyText(13))
                    .foregroundStyle(Color.inkMuted)
            }
            .padding(20)

        case .result:
            VStack(spacing: 8) {
                Text("\(score)%")
                    .font(.display(36, weight: .heavy))
                    .foregroundStyle(score >= 70 ? Color.mintDeep : Color.quackOrange)
                Text(score >= 70 ? "Great job!" : "Nice try!")
                    .font(.bodyText(14, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
                if !heard.isEmpty {
                    Text("Q heard: \(heard)")
                        .font(.bodyText(12))
                        .foregroundStyle(Color.inkMuted.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                HStack(spacing: 14) {
                    Button { SpeechSpeaker.shared.speak(current.hanzi) } label: {
                        Pill(text: "Hear it", color: .cobalt)
                    }
                    .buttonStyle(TapPress())
                    if let lastRecording {
                        Button { try? player.play(pcm: lastRecording) } label: {
                            Pill(text: "Hear you", color: .quackOrange)
                        }
                        .buttonStyle(TapPress())
                    }
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
    }

    private func startRecording() async {
        errorMessage = nil
        let granted = await recorder.requestPermission()
        guard granted else {
            errorMessage = "Quack needs the microphone. Enable it in Settings."
            return
        }
        do {
            try recorder.start()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        phase = .recording
        autoStopTask?.cancel()
        let target = current
        autoStopTask = Task { [maxRecordingSeconds] in
            try? await Task.sleep(nanoseconds: maxRecordingSeconds * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if phase == .recording {
                    finishRecording(target: target)
                }
            }
        }
    }

    private func stopRecording() {
        autoStopTask?.cancel()
        autoStopTask = nil
        finishRecording(target: current)
    }

    private func finishRecording(target: VocabItem) {
        let audio: Data
        do {
            audio = try recorder.stop()
        } catch {
            errorMessage = error.localizedDescription
            phase = .idle
            return
        }
        lastRecording = audio
        phase = .scoring
        scoringTask?.cancel()
        scoringTask = Task {
            do {
                let result = try await QuackGemma.shared.scorePronunciation(
                    audio: audio,
                    target: target
                )
                await MainActor.run {
                    score = result.score
                    heard = result.heard
                    withAnimation { phase = .result }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    phase = .idle
                }
            }
        }
    }

    private func retryWord() {
        scoringTask?.cancel()
        autoStopTask?.cancel()
        player.stop()
        SpeechSpeaker.shared.stop()
        errorMessage = nil
        heard = ""
        lastRecording = nil
        phase = .idle
        score = 0
    }

    private func nextWord() {
        scoringTask?.cancel()
        autoStopTask?.cancel()
        player.stop()
        SpeechSpeaker.shared.stop()
        errorMessage = nil
        if wordIndex < words.count - 1 {
            wordIndex += 1
            phase = .idle
            score = 0
            heard = ""
            lastRecording = nil
        } else {
            onComplete(current.id)
        }
    }
}

#Preview {
    SpeakMissionView(vocab: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
