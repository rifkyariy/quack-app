import SwiftUI

private struct MatchRound {
    let target: VocabItem
    let choices: [VocabItem]
    var answeredCorrectly: Bool? = nil  // nil=unanswered, true=correct, false=wrong
}

struct MatchMissionView: View {
    let target: VocabItem
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rounds: [MatchRound]
    @State private var roundIndex = 0
    @State private var selectedId: String? = nil
    @State private var shake = false

    init(target: VocabItem, onComplete: @escaping (String) -> Void) {
        self.target = target
        self.onComplete = onComplete

        var pool = VOCAB.filter { $0.id != target.id }.shuffled()
        func threeDistractors() -> [VocabItem] {
            if pool.count < 3 { pool = VOCAB.filter { $0.id != target.id }.shuffled() }
            defer { pool = Array(pool.dropFirst(3)) }
            return Array(pool.prefix(3))
        }

        let others = Array(pool.prefix(2)); pool = Array(pool.dropFirst(2))
        let built: [MatchRound] = ([target] + others).map { t in
            MatchRound(target: t, choices: ([t] + threeDistractors()).shuffled())
        }
        _rounds = State(initialValue: built)
    }

    private var round: MatchRound { rounds[min(roundIndex, rounds.count - 1)] }
    private var revealed: Bool { round.answeredCorrectly != nil }
    private var correctCount: Int { rounds.filter { $0.answeredCorrectly == true }.count }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                promptCard
                    .offset(x: shake ? -8 : 0)
                    .animation(shake ? .default.repeatCount(5, autoreverses: true).speed(8) : .default, value: shake)
                choiceGrid
                Spacer()
                bottomCTA
            }
        }
        .animation(.easeOut(duration: 0.22), value: roundIndex)
        .animation(.easeOut(duration: 0.22), value: revealed)
    }

    // MARK: - Header
    private var header: some View {
        ZStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.inkMuted)
                        .frame(width: 36, height: 36)
                        .background(Color.inkFaint)
                        .clipShape(Circle())
                }
                .buttonStyle(TapPress())
                Spacer()
                // Score badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.quackYellow)
                    Text("\(correctCount)/\(rounds.count)")
                        .font(.display(14, weight: .heavy))
                        .foregroundStyle(Color.ink)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.quackYellow.opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            // Round progress dots
            HStack(spacing: 6) {
                ForEach(rounds.indices, id: \.self) { i in
                    Capsule()
                        .fill(dotColor(for: i))
                        .frame(width: i == roundIndex ? 20 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: roundIndex)
                        .animation(.easeOut(duration: 0.2), value: rounds[i].answeredCorrectly as Bool?)
                }
            }
        }
        .padding(.top, 16).padding(.bottom, 8)
    }

    private func dotColor(for i: Int) -> Color {
        if i == roundIndex { return .quackOrange }
        if let ok = rounds[i].answeredCorrectly { return ok ? .mintDeep : .rose }
        return .inkFaint
    }

    // MARK: - Prompt card
    private var promptCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.ink)
                .grain(opacity: 0.1)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(revealBorderColor, lineWidth: revealed ? 3 : 0)
                        .animation(.easeOut(duration: 0.3), value: revealed)
                )

            VStack(spacing: 6) {
                Text(round.target.hanzi)
                    .font(.display(60, weight: .heavy))
                    .foregroundStyle(.white)
                Text(round.target.pinyin)
                    .font(.bodyText(16, weight: .bold))
                    .foregroundStyle(.white.opacity(revealed ? 0.85 : 0.35))
                    .animation(.easeOut(duration: 0.3), value: revealed)

                // Sound button
                Button {
                    SpeechSpeaker.shared.speak(round.target.hanzi)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Hear it")
                            .font(.bodyText(12, weight: .heavy))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(TapPress())
                .padding(.top, 4)

                if !revealed {
                    Text("Match the English word")
                        .font(.bodyText(11)).foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 2)
                }
            }
            .padding(24)

            // Result overlay
            if revealed {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: round.answeredCorrectly == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(round.answeredCorrectly == true ? Color.mintDeep : Color.quackOrange)
                            .padding(14)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(.horizontal, 20).padding(.top, 8)
    }

    private var revealBorderColor: Color {
        guard revealed else { return .clear }
        return round.answeredCorrectly == true ? .mintDeep : .quackOrange
    }

    // MARK: - Choice grid
    private var choiceGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            ForEach(round.choices) { choice in
                choiceCell(choice)
            }
        }
        .padding(.horizontal, 20).padding(.top, 14)
    }

    private func choiceCell(_ choice: VocabItem) -> some View {
        let isSelected = selectedId == choice.id
        let isCorrect = choice.id == round.target.id
        let cellState: CellState = revealed
            ? (isCorrect ? .correct : (isSelected ? .wrong : .dim))
            : (isSelected ? .selected : .idle)

        return Button {
            guard !revealed else { return }
            selectedId = choice.id
            var updated = rounds
            updated[roundIndex].answeredCorrectly = isCorrect
            rounds = updated
            if !isCorrect { triggerShake() }
            UIImpactFeedbackGenerator(style: isCorrect ? .medium : .rigid).impactOccurred()
        } label: {
            VStack(spacing: 10) {
                ObjectArt(vocab: choice, size: 64)
                VStack(spacing: 2) {
                    Text(choice.en.capitalized)
                        .font(.bodyText(13, weight: .heavy))
                        .foregroundStyle(cellState.textColor)
                    Text(choice.pinyin)
                        .font(.bodyText(10))
                        .foregroundStyle(cellState.textColor.opacity(0.6))
                        .opacity(revealed ? 1 : 0)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cellState.bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(cellState.border, lineWidth: cellState.borderWidth)
                    )
            )
            .overlay(alignment: .topTrailing) {
                if revealed && (isCorrect || isSelected) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isCorrect ? Color.mintDeep : Color.quackOrange)
                        .padding(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isSelected && !revealed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .disabled(revealed)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: revealed)
    }

    // MARK: - CTA
    @ViewBuilder
    private var bottomCTA: some View {
        if revealed {
            VStack(spacing: 8) {
                if round.answeredCorrectly == false {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color.quackYellow)
                            .font(.system(size: 13))
                        Text("The answer was \"\(round.target.en.capitalized)\"")
                            .font(.bodyText(12, weight: .bold))
                            .foregroundStyle(Color.ink)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.quackYellow.opacity(0.15))
                    .clipShape(Capsule())
                }

                CTAButton(
                    label: roundIndex < rounds.count - 1 ? "Next round" : "Finish",
                    variant: round.answeredCorrectly == true ? .orange : .ink
                ) {
                    advanceOrFinish()
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
            .transition(.opacity.combined(with: .offset(y: 12)))
        }
    }

    // MARK: - Logic
    private func advanceOrFinish() {
        if roundIndex < rounds.count - 1 {
            selectedId = nil
            roundIndex += 1
        } else {
            // Only complete if the target's round was answered correctly
            let targetRound = rounds.first { $0.target.id == target.id }
            if targetRound?.answeredCorrectly == true {
                onComplete(target.id)
            } else {
                // Reset the game — player must try again
                var reset = rounds.map { r in
                    MatchRound(target: r.target, choices: r.choices.shuffled())
                }
                rounds = reset
                roundIndex = 0
                selectedId = nil
            }
        }
    }

    private func triggerShake() {
        shake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shake = false }
    }
}

// MARK: - Cell state helper
private enum CellState {
    case idle, selected, correct, wrong, dim

    var bg: Color {
        switch self {
        case .idle:     return Color.paper
        case .selected: return Color.quackOrange.opacity(0.1)
        case .correct:  return Color.mint.opacity(0.2)
        case .wrong:    return Color.quackOrange.opacity(0.08)
        case .dim:      return Color.inkFaint.opacity(0.3)
        }
    }
    var border: Color {
        switch self {
        case .idle:     return Color.inkFaint
        case .selected: return Color.quackOrange
        case .correct:  return Color.mintDeep
        case .wrong:    return Color.quackOrange
        case .dim:      return Color.inkFaint.opacity(0.3)
        }
    }
    var borderWidth: CGFloat { self == .idle || self == .dim ? 1 : 2.5 }
    var textColor: Color {
        switch self {
        case .correct: return Color.mintDeep
        case .wrong:   return Color.quackOrange
        case .dim:     return Color.inkMuted.opacity(0.5)
        default:       return Color.ink
        }
    }
}

#Preview {
    MatchMissionView(target: VOCAB[0], onComplete: { _ in })
        .environment(AppState())
}
