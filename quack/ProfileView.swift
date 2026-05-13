import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var level: Int {
        min(5, max(1, appState.age - 3))
    }

    private var learnedItems: [VocabItem] {
        appState.learned.compactMap { id in VOCAB.first { $0.id == id } }
    }

    private var lockedItems: [VocabItem] {
        VOCAB.filter { !appState.learned.contains($0.id) }
    }

    private var recentSix: [(item: VocabItem, locked: Bool)] {
        let earned = Array(learnedItems.suffix(6))
        let needed = max(0, 6 - earned.count)
        let pads = Array(lockedItems.prefix(needed))
        return earned.map { (item: $0, locked: false) } + pads.map { (item: $0, locked: true) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                agentCard
                statRow
                recentStickers
                CTAButton(label: "See full sticker book", variant: .ghost) {}
                    .padding(.horizontal, 20)
                Spacer().frame(height: 32)
            }
            .padding(.top, 16)
        }
        .background(Color.cream.ignoresSafeArea())
    }

    // MARK: Agent Card
    private var agentCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.quackOrange)
            GrainOverlay(opacity: 0.09)
            Sparkles(count: 4, color: .white, opacity: 0.55, animate: true)

            VStack(spacing: 8) {
                Mascot(state: .idle, size: 120)
                Eyebrow(text: "Agent File", color: .white.opacity(0.85), flank: true, size: 11)
                Text(appState.name)
                    .font(.display(34, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Age \(appState.age) · Level \(level)")
                    .font(.bodyText(14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.vertical, 28)
        }
        .padding(.horizontal, 20)
        .popShadow()
    }

    // MARK: Stat Row
    private var statRow: some View {
        HStack(spacing: 10) {
            statCard("Streak", "\(appState.streak)", "days", tone: .mint)
            statCard("Words", "\(appState.learned.count)", "learned", tone: .cobalt)
            statCard("Today", "\(appState.dailyProgress)", "done", tone: .orange)
        }
        .padding(.horizontal, 20)
    }

    private func statCard(_ eyebrow: String, _ value: String, _ sub: String, tone: Tone) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: eyebrow, color: tone.fg == .white ? .white.opacity(0.8) : .ink.opacity(0.6), flank: false, size: 10)
            Text(value)
                .font(.display(32, weight: .heavy))
                .foregroundStyle(tone.fg)
            Text(sub)
                .font(.bodyText(11))
                .foregroundStyle(tone.fg.opacity(0.75))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 100)
        .quackCard(tone: tone)
    }

    // MARK: Recent Stickers
    private var recentStickers: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent stickers")
                .font(.display(18, weight: .heavy))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 20)

            let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(Array(recentSix.enumerated()), id: \.offset) { _, entry in
                    StickerTile(item: entry.item, locked: entry.locked, size: .sm, justEarned: false)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    let state = AppState()
    state.learned = ["apple", "cat", "dog", "rice", "mom"]
    return ProfileView()
        .environment(state)
}
