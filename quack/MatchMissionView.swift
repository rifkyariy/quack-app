import SwiftUI

private struct MatchRound {
    let target: VocabItem
    let choices: [VocabItem]   // always 4, target is one of them
}

struct MatchMissionView: View {
    let target: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var roundIndex = 0
    @State private var selected: String? = nil
    @State private var revealed = false

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }

    private let rounds: [MatchRound]

    init(target: VocabItem, onComplete: @escaping (String) -> Void) {
        self.target = target
        self.onComplete = onComplete

        var pool = VOCAB.filter { $0.id != target.id }.shuffled()
        func nextThree() -> [VocabItem] {
            if pool.count < 3 { pool = VOCAB.filter { $0.id != target.id }.shuffled() }
            let r = Array(pool.prefix(3))
            pool = Array(pool.dropFirst(3))
            return r
        }

        let others = Array(pool.prefix(2))
        pool = Array(pool.dropFirst(2))

        var built: [MatchRound] = []
        for t in ([target] + others) {
            let distractors = nextThree()
            built.append(MatchRound(target: t, choices: ([t] + distractors).shuffled()))
        }
        self.rounds = built
    }

    private var round: MatchRound { rounds[min(roundIndex, rounds.count - 1)] }

    private var promptCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.ink)
                .grain(opacity: 0.1)

            VStack(spacing: 4) {
                Text(round.target.hanzi)
                    .font(.display(56, weight: .heavy))
                    .foregroundStyle(.white)
                Text(revealed ? round.target.pinyin : "Match the character")
                    .font(.bodyText(15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.65))
                    .animation(.easeOut, value: revealed)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var choiceGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(round.choices) { choice in
                MatchChoiceCell(
                    vocab: choice,
                    isTarget: choice.id == round.target.id,
                    isSelected: selected == choice.id,
                    revealed: revealed
                ) {
                    guard !revealed else { return }
                    selected = choice.id
                    withAnimation(.easeOut(duration: 0.3)) { revealed = true }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    @ViewBuilder
    private var matchCTA: some View {
        if revealed {
            CTAButton(
                label: roundIndex < rounds.count - 1 ? "Next" : "Finish",
                variant: .ink,
                action: {
                    if roundIndex < rounds.count - 1 {
                        roundIndex += 1
                        selected = nil
                        withAnimation { revealed = false }
                    } else {
                        onComplete(target.id)
                    }
                }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .transition(.opacity.combined(with: .offset(y: 12)))
        }
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                MissionHeader(title: "Match it", accent: .rose, onBack: { dismiss() })

                if isLandscape {
                    HStack(spacing: 0) {
                        promptCard
                            .frame(maxWidth: .infinity)
                        VStack(spacing: 0) {
                            choiceGrid
                            Spacer()
                            matchCTA
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    promptCard
                    choiceGrid
                    Spacer()
                    matchCTA
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: revealed)
    }
}

private struct MatchChoiceCell: View {
    let vocab: VocabItem
    let isTarget: Bool
    let isSelected: Bool
    let revealed: Bool
    let onTap: () -> Void

    private var borderColor: Color {
        guard revealed && isSelected else { return .clear }
        return isTarget ? .mintDeep : .quackOrange
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(vocab.tone.bg.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 3)
                    )

                VStack(spacing: 8) {
                    ObjectArt(vocab: vocab, size: 72)
                    Text(vocab.en)
                        .font(.bodyText(12, weight: .bold))
                        .foregroundStyle(Color.ink)
                }
                .padding(14)
                .frame(maxWidth: .infinity)

                if revealed && isSelected {
                    Circle()
                        .fill(isTarget ? Color.mintDeep : Color.quackOrange)
                        .frame(width: 26, height: 26)
                        .overlay(
                            QuackIcon(
                                name: isTarget ? .check : .close,
                                size: 14, color: .white, strokeWidth: 2
                            )
                        )
                        .padding(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(TapPress())
        .disabled(revealed)
    }
}

#Preview {
    MatchMissionView(target: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
