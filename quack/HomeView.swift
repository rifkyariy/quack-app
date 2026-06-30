import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    var onMission: (MissionType, VocabItem) -> Void
    @Binding var activeTab: TabItem

    @State private var showProfile = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }

    private var todayWord: VocabItem? {
        VOCAB.first { $0.id == appState.todayMission.target }
    }

    var body: some View {
        MainTabChrome(active: $activeTab) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    greetingHeader
                    if isLandscape {
                        HStack(alignment: .top, spacing: 0) {
                            missionHeroCard
                                .frame(maxWidth: .infinity)
                            VStack(spacing: 0) {
                                dailyRingCard
                                statCards
                                recentStickers
                                trainingGrid
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        dailyRingCard
                        missionHeroCard
                        statCards
                        recentStickers
                        trainingGrid
                    }
                    Spacer().frame(height: 120)
                }
            }
            .background(Color.cream)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }

    // MARK: - Level helpers
    private var xp: Int { appState.learned.count * 10 + appState.streak * 5 }
    private var levelNum: Int {
        switch xp { case 0..<30: 1; case 30..<80: 2; case 80..<160: 3; case 160..<280: 4; default: 5 }
    }
    private static let levelNames = ["", "Seedling", "Sprout", "Explorer", "Collector", "Champion"]
    private var levelName: String { Self.levelNames[levelNum] }

    // MARK: - Greeting header
    private var greetingHeader: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button { showProfile = true } label: {
                    ZStack(alignment: .bottomTrailing) {
                        Image(appState.codename)
                            .resizable().scaledToFit()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .cardShadow()
                        Text("Lv.\(levelNum)")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Color.paper)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.quackOrange)
                            .clipShape(Capsule())
                            .offset(x: 4, y: 4)
                    }
                }
                .buttonStyle(TapPress())

                VStack(alignment: .leading, spacing: 1) {
                    Text(levelName)
                        .font(.bodyText(10, weight: .heavy))
                        .foregroundStyle(Color.quackOrange)
                        .tracking(0.5)
                    Text("Hey, \(appState.name)!")
                        .font(.display(22, weight: .heavy))
                        .foregroundStyle(Color.ink)
                }

                Spacer()

                // Streak badge
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.quackOrange)
                        .symbolEffect(.pulse, isActive: appState.streak > 0)
                    Text("\(appState.streak)")
                        .font(.display(16, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("streak")
                        .font(.bodyText(9)).foregroundStyle(Color.inkMuted)
                }
                .padding(.horizontal, 10).padding(.vertical, 8).quackCard()
            }

            // XP bar
            GeometryReader { geo in
                let xpBase = [0, 30, 80, 160, 280][max(0, levelNum - 1)]
                let xpNext = [30, 80, 160, 280, 999][max(0, levelNum - 1)]
                let pct = CGFloat(xp - xpBase) / CGFloat(max(xpNext - xpBase, 1))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.inkFaint).frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(colors: [Color.quackYellow, Color.quackOrange],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(1, pct), height: 6)
                        .animation(.easeOut(duration: 0.6), value: xp)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Daily ring card (hidden when goal is already met)
    @ViewBuilder private var dailyRingCard: some View {
        if appState.dailyProgress < appState.dailyGoal {
            HStack(spacing: 14) {
                DailyRing(value: appState.dailyProgress, max: appState.dailyGoal)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(appState.dailyProgress) / \(appState.dailyGoal) stars today")
                        .font(.display(18, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("Finish your mission to hit today's goal.")
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
    }

    // MARK: - Today's mission hero card
    @ViewBuilder private var missionHeroCard: some View {
        if appState.dailyProgress >= appState.dailyGoal {
            goalCompleteCard
        } else {
            missionActiveCard
        }
    }

    private var goalCompleteCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.mint)
                .grain()
                .popShadow()
                .frame(maxWidth: .infinity, minHeight: 200)

            Confetti(count: 20)
            Sparkles(count: 6, color: .white, opacity: 0.5, animate: true)

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: "Goal reached!", color: .mintDeep, flank: false)
                    .padding(.top, 22).padding(.horizontal, 22)

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("You've done great today!")
                            .font(.display(24, weight: .heavy))
                            .foregroundStyle(Color.ink)
                        Text("Check your achievements and see how far you've come.")
                            .font(.bodyText(13))
                            .foregroundStyle(Color.ink.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Mascot(state: .celebrating, size: 70)
                        .padding(.top, -4)
                }
                .padding(.top, 8).padding(.horizontal, 22)

                Button {
                    activeTab = .parent
                } label: {
                    HStack(spacing: 6) {
                        Text("Go to Parent Summary")
                            .font(.bodyText(14, weight: .heavy))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Color.mintDeep)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.paper.opacity(0.85))
                    .clipShape(Capsule())
                    .cardShadow()
                }
                .buttonStyle(TapPress())
                .padding(.horizontal, 22).padding(.top, 14).padding(.bottom, 22)
            }
        }
        .padding(.horizontal, 24).padding(.top, 14)
    }

    private var missionActiveCard: some View {
        Button { if let word = todayWord { onMission(.camera, word) } } label: {
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick your training")
                .font(.display(18, weight: .heavy))
                .foregroundStyle(Color.ink)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(MissionType.allCases) { type in
                    Button {
                        let word = todayWord ?? VOCAB[0]
                        onMission(type, word)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            QuackIcon(name: type.icon, size: 22, color: type.tone.fg, strokeWidth: 2)
                            Spacer()
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.title)
                                    .font(.display(16, weight: .heavy))
                                    .foregroundStyle(type.tone.fg)
                                Text(type.subtitle)
                                    .font(.bodyText(11, weight: .bold))
                                    .foregroundStyle(type.tone.fg.opacity(0.8))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 110)
                        .quackCard(tone: type.tone)
                    }
                    .buttonStyle(TapPress())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}


#Preview("HomeView") {
    @Previewable @State var tab = TabItem.home
    let state = AppState()
    state.streak = 4
    state.dailyProgress = 1
    return HomeView(onMission: { _, _ in }, activeTab: $tab)
        .environment(state)
}
