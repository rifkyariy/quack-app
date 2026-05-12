import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    var onMission: (String) -> Void
    @Binding var activeTab: TabItem

    @State private var showProfile = false

    private var todayWord: VocabItem? {
        VOCAB.first { $0.id == appState.todayMission.target }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    greetingHeader
                    dailyRingCard
                    missionHeroCard
                    statCards
                    recentStickers
                    trainingGrid
                    Spacer().frame(height: 120)
                }
            }
            .background(Color.cream)

            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showProfile) {
            ProfilePlaceholder()
        }
    }

    // MARK: - Greeting header
    private var greetingHeader: some View {
        HStack(spacing: 12) {
            Button { showProfile = true } label: {
                Text(String((appState.name.isEmpty ? "A" : appState.name).prefix(1)).uppercased())
                    .font(.display(22, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.quackOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .cardShadow()
            }
            .buttonStyle(TapPress())

            VStack(alignment: .leading, spacing: 2) {
                Text("WELCOME BACK")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(11 * 0.12)
                    .foregroundStyle(Color.inkMuted)
                Text("Hey, \(appState.name)")
                    .font(.display(22, weight: .heavy))
                    .foregroundStyle(Color.ink)
            }

            Spacer()

            HStack(spacing: 6) {
                QuackIcon(name: .fire, size: 16, color: .quackOrangeDeep, strokeWidth: 1.8)
                Text("\(appState.streak)")
                    .font(.display(16, weight: .heavy))
                    .foregroundStyle(Color.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .quackCard()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Daily ring card
    private var dailyRingCard: some View {
        HStack(spacing: 14) {
            DailyRing(value: appState.dailyProgress, max: appState.dailyGoal)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(appState.dailyProgress) / \(appState.dailyGoal) stars today")
                    .font(.display(18, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text(appState.dailyProgress >= appState.dailyGoal
                     ? "Goal smashed! Keep going for bonus stickers."
                     : "Finish your mission to hit today's goal.")
                    .font(.bodyText(12))
                    .foregroundStyle(Color.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .quackCard()
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    // MARK: - Today's mission hero card
    private var missionHeroCard: some View {
        Button { onMission("camera") } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.quackOrange)
                    .grain()
                    .popShadow()
                    .frame(minHeight: 220)

                Sparkles(count: 6, opacity: 0.6, animate: true)

                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: "Today's mission", color: .quackYellow, flank: false)
                        .padding(.top, 22)
                        .padding(.horizontal, 22)

                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.todayMission.title)
                                .font(.display(26, weight: .heavy))
                                .foregroundStyle(.white)
                            if let word = todayWord {
                                (Text("Q is listening. Say ")
                                    .font(.bodyText(14))
                                    .foregroundStyle(.white.opacity(0.9))
                                + Text(word.hanzi)
                                    .font(.display(18, weight: .heavy))
                                    .foregroundStyle(.white)
                                + Text(" (\(word.pinyin)) — earn 3 stars.")
                                    .font(.bodyText(14))
                                    .foregroundStyle(.white.opacity(0.9)))
                            }
                        }
                        Spacer()
                        Mascot(state: .idle, size: 70)
                            .padding(.top, -4)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 22)

                    HStack {
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(.white.opacity(0.18))
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        QuackIcon(name: .star, size: 14, color: .white.opacity(0.45), strokeWidth: 1.6)
                                    )
                            }
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Text("Start mission")
                                .font(.bodyText(14, weight: .heavy))
                            QuackIcon(name: .chevron, size: 16, color: .quackOrange, strokeWidth: 2.2)
                        }
                        .foregroundStyle(Color.quackOrange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .cardShadow()
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
                }
            }
        }
        .buttonStyle(TapPress())
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    // MARK: - Stat cards
    private var statCards: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Streak", color: .ink, flank: false, size: 11)
                Text("\(appState.streak)")
                    .font(.display(38, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text("days in a row")
                    .font(.bodyText(12))
                    .foregroundStyle(Color.ink.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .quackCard(tone: .mint)

            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Stickers", color: .white.opacity(0.85), flank: false, size: 11)
                Text("\(appState.learned.count)")
                    .font(.display(38, weight: .heavy))
                    .foregroundStyle(.white)
                Text("of \(VOCAB.count) collected")
                    .font(.bodyText(12))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .quackCard(tone: .cobalt)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    // MARK: - Recent stickers
    @ViewBuilder
    private var recentStickers: some View {
        let recent = Array(appState.learned.suffix(4).reversed().compactMap { id in
            VOCAB.first { $0.id == id }
        })
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Recent stickers")
                        .font(.display(18, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Button("See all") { activeTab = .library }
                        .font(.bodyText(13, weight: .heavy))
                        .foregroundStyle(Color.quackOrange)
                        .buttonStyle(TapPress())
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(recent) { item in
                        StickerTile(item: item, size: .sm)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Training type grid
    private var trainingGrid: some View {
        let types: [(id: String, label: String, sub: String, tone: Tone, icon: QuackIconName)] = [
            ("camera", "Camera scan", "Point at it", .orange, .camera),
            ("speak",  "Say it back", "Mic check",   .cobalt, .mic),
            ("match",  "Match cards", "Word ↔ pic",  .rose,   .star),
            ("story",  "Q's story",   "Listen & learn", .mint, .book),
        ]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Pick your training")
                .font(.display(18, weight: .heavy))
                .foregroundStyle(Color.ink)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(types, id: \.id) { t in
                    Button { onMission(t.id) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            QuackIcon(name: t.icon, size: 22, color: t.tone.fg, strokeWidth: 2)

                            Spacer()

                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.label)
                                    .font(.display(16, weight: .heavy))
                                    .foregroundStyle(t.tone.fg)
                                Text(t.sub)
                                    .font(.bodyText(11, weight: .bold))
                                    .foregroundStyle(t.tone.fg.opacity(0.8))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 110)
                        .quackCard(tone: t.tone)
                    }
                    .buttonStyle(TapPress())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}

// Placeholder for profile sheet (Phase 3)
struct ProfilePlaceholder: View {
    var body: some View {
        VStack { Text("Profile — Phase 3").font(.display(20)) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.cream)
    }
}

#Preview("HomeView") {
    @Previewable @State var tab = TabItem.home
    let state = AppState()
    state.streak = 4
    state.dailyProgress = 1
    return HomeView(onMission: { _ in }, activeTab: $tab)
        .environment(state)
}
