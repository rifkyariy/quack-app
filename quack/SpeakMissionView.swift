import SwiftUI

struct SpeakMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var wordIndex = 0
    @State private var phase: SpeakPhase = .idle
    @State private var score = 0
    @State private var waveAnimating = false

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
            VStack(spacing: 12) {
                Text("Say it aloud")
                    .font(.bodyText(14, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
                Button { startRecording() } label: {
                    Circle()
                        .fill(Color.cobalt)
                        .frame(width: 64, height: 64)
                        .overlay(QuackIcon(name: .mic, size: 28, color: .white, strokeWidth: 2.2))
                        .popShadow()
                }
                .buttonStyle(TapPress())
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
                Pill(text: "Q is listening", color: .cobalt, pulseDot: true)
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
            VStack(spacing: 6) {
                Text("\(score)%")
                    .font(.display(36, weight: .heavy))
                    .foregroundStyle(score >= 70 ? Color.mintDeep : Color.quackOrange)
                Text(score >= 70 ? "Great job!" : "Nice try!")
                    .font(.bodyText(14, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
            }
            .padding(20)
        }
    }

    private func startRecording() {
        phase = .recording
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            phase = .scoring
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                score = Int.random(in: 72...97)
                withAnimation { phase = .result }
            }
        }
    }

    private func retryWord() {
        phase = .idle
        score = 0
    }

    private func nextWord() {
        if wordIndex < words.count - 1 {
            wordIndex += 1
            phase = .idle
            score = 0
        } else {
            onComplete(current.id)
        }
    }
}

#Preview {
    SpeakMissionView(vocab: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
