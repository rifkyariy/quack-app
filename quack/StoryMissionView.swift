import SwiftUI

private struct StoryPage {
    let vocab: VocabItem
    let text: String
}

struct StoryMissionView: View {
    let vocab: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase: StoryPhase = .reading(page: 0)
    @State private var quizSelected: String? = nil
    @State private var quizRevealed = false
    @State private var quizChoicesCache: [VocabItem]? = nil

    enum StoryPhase: Equatable {
        case reading(page: Int)
        case quiz
    }

    private var pages: [StoryPage] {
        let related = VOCAB.filter { $0.cat == vocab.cat && $0.id != vocab.id }
        var items = [vocab] + Array(related.prefix(2))
        if items.count < 3 {
            items += VOCAB.filter { !items.map(\.id).contains($0.id) }.prefix(3 - items.count)
        }
        return [
            StoryPage(vocab: items[0], text: "Q found a \(items[0].en.lowercased())! In Mandarin, it's '\(items[0].hanzi)' — say \(items[0].pinyin)."),
            StoryPage(vocab: items[min(1, items.count-1)], text: "Look — a \(items[min(1,items.count-1)].en.lowercased())! '\(items[min(1,items.count-1)].hanzi)' (\(items[min(1,items.count-1)].pinyin)). Can you say it?"),
            StoryPage(vocab: items[min(2, items.count-1)], text: "Amazing work! You're becoming a Mandarin agent. Remember '\(vocab.hanzi)' (\(vocab.pinyin)) — \(vocab.en.lowercased())."),
        ]
    }

    private func makeQuizChoices() -> [VocabItem] {
        let pool = VOCAB.filter { $0.id != vocab.id }.shuffled()
        return ([vocab] + pool.prefix(2)).shuffled()
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Story time", accent: .mint, onBack: { dismiss() })

                switch phase {
                case .reading(let page): readingView(page: page)
                case .quiz:              quizView
                }

                Spacer()

                ctaButton
            }
        }
        .animation(.easeOut(duration: 0.3), value: phase)
    }

    // MARK: Reading
    private func readingView(page: Int) -> some View {
        let storyPage = pages[min(page, pages.count - 1)]
        return VStack(spacing: 12) {
            // Progress bars
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= page ? Color.mint : Color.inkFaint)
                        .frame(height: 4)
                        .animation(.easeOut(duration: 0.3), value: page)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            // Story card
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(storyPage.vocab.tone.bg)
                    .grain()
                    .popShadow()

                Sparkles(count: 4, opacity: 0.4)

                VStack(spacing: 16) {
                    ObjectArt(vocab: storyPage.vocab, size: 100)
                    Text(storyPage.vocab.hanzi)
                        .font(.display(36, weight: .heavy))
                        .foregroundStyle(storyPage.vocab.tone.fg)
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding(.horizontal, 24)

            // Narration card
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.paper)
                    .cardShadow()

                HStack(spacing: 12) {
                    Mascot(state: .speaking, size: 48)
                    Text(storyPage.text)
                        .font(.bodyText(14))
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button {} label: {
                        QuackIcon(name: .speaker, size: 22, color: .quackOrange, strokeWidth: 2)
                    }
                    .buttonStyle(TapPress())
                }
                .padding(14)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Quiz
    private var quizView: some View {
        let choices = quizChoicesCache ?? makeQuizChoices()
        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: "Quick quiz", flank: false, size: 11)
                Text("Which one is '\(vocab.hanzi)'?")
                    .font(.display(22, weight: .heavy))
                    .foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)

            VStack(spacing: 10) {
                ForEach(choices) { choice in
                    Button {
                        guard !quizRevealed else { return }
                        quizSelected = choice.id
                        withAnimation(.easeOut(duration: 0.3)) { quizRevealed = true }
                    } label: {
                        HStack(spacing: 14) {
                            ObjectArt(vocab: choice, size: 52)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(choice.en)
                                    .font(.display(16, weight: .heavy))
                                    .foregroundStyle(Color.ink)
                                Text(choice.pinyin)
                                    .font(.bodyText(12))
                                    .foregroundStyle(Color.inkMuted)
                            }
                            Spacer()
                            if quizRevealed && quizSelected == choice.id {
                                Circle()
                                    .fill(choice.id == vocab.id ? Color.mintDeep : Color.quackOrange)
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        QuackIcon(
                                            name: choice.id == vocab.id ? .check : .close,
                                            size: 14, color: .white, strokeWidth: 2
                                        )
                                    )
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(quizRevealed && quizSelected == choice.id
                                      ? (choice.id == vocab.id ? Color.mint.opacity(0.3) : Color.rose.opacity(0.3))
                                      : Color.paper)
                        )
                        .cardShadow()
                    }
                    .buttonStyle(TapPress())
                    .disabled(quizRevealed)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            if quizChoicesCache == nil { quizChoicesCache = makeQuizChoices() }
        }
    }

    // MARK: CTA
    @ViewBuilder
    private var ctaButton: some View {
        switch phase {
        case .reading(let page):
            CTAButton(
                label: page < pages.count - 1 ? "Next page" : "Take the quiz",
                variant: page < pages.count - 1 ? .ghost : .orange,
                action: {
                    if page < pages.count - 1 {
                        withAnimation { phase = .reading(page: page + 1) }
                    } else {
                        withAnimation { phase = .quiz }
                    }
                }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 32)

        case .quiz:
            if quizRevealed {
                CTAButton(label: "Finish", variant: .ink, action: { onComplete(vocab.id) })
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .transition(.opacity.combined(with: .offset(y: 12)))
            }
        }
    }
}

#Preview {
    StoryMissionView(vocab: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
