import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    // Level system (mirrors HomeView)
    private var xp: Int { appState.learned.count * 10 + appState.streak * 5 }
    private var levelNum: Int {
        switch xp { case 0..<30: 1; case 30..<80: 2; case 80..<160: 3; case 160..<280: 4; default: 5 }
    }
    private static let levelNames = ["", "Mandarin Seedling", "Mandarin Sprout", "Mandarin Explorer", "Word Collector", "Mandarin Champion"]
    private static let levelColors: [Color] = [.clear, .mintDeep, .cobalt, .quackOrange, .quackOrangeDeep, .quackYellow]
    private var levelName: String { Self.levelNames[levelNum] }
    private var levelColor: Color { Self.levelColors[levelNum] }
    private var xpBase: Int { [0,30,80,160,280][levelNum-1] }
    private var xpNext: Int { [30,80,160,280,999][levelNum-1] }
    private var xpProgress: CGFloat { CGFloat(xp - xpBase) / CGFloat(max(xpNext - xpBase, 1)) }

    // Achievements
    private struct Ach { let symbol: String; let name: String; let unlocked: Bool; let color: Color }
    private var achievements: [Ach] { [
        Ach(symbol: "star.fill",          name: "First Word",    unlocked: !appState.learned.isEmpty,       color: .quackYellow),
        Ach(symbol: "flame.fill",         name: "3-Day Streak",  unlocked: appState.streak >= 3,            color: .quackOrange),
        Ach(symbol: "bolt.fill",          name: "Week Streak",   unlocked: appState.streak >= 7,            color: .quackOrangeDeep),
        Ach(symbol: "checkmark.seal.fill",name: "10 Words",      unlocked: appState.learned.count >= 10,   color: .cobalt),
        Ach(symbol: "crown.fill",         name: "20 Words",      unlocked: appState.learned.count >= 20,   color: .quackYellow),
        Ach(symbol: "leaf.fill",          name: "Category Pro",  unlocked: categoryComplete,                color: .mintDeep),
    ] }
    private var categoryComplete: Bool {
        CATEGORIES.contains { cat in
            let words = VOCAB.filter { $0.cat == cat.id }
            return !words.isEmpty && words.allSatisfy { appState.learned.contains($0.id) }
        }
    }

    // 14-day streak calendar
    private var calendarDays: [(date: Date, active: Bool)] {
        let cal = Calendar.current
        return (0..<14).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            return (date, appState.weekActivity[AppState.dateKey(date)] != nil)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    agentCard
                    streakCalendar
                    achievementsSection
                    recentStickersSection
                    Spacer().frame(height: 32)
                }
                .padding(.top, 12)
            }
            .background(Color.cream.ignoresSafeArea())
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Agent card
    private var agentCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28).fill(levelColor).grain(opacity: 0.08)
            Sparkles(count: 5, color: .white, opacity: 0.45, animate: true)

            HStack(spacing: 20) {
                // Agent image
                ZStack(alignment: .bottomTrailing) {
                    Image(appState.codename)
                        .resizable().scaledToFit()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.paper.opacity(0.5), lineWidth: 2))
                        .cardShadow()
                    Text("Lv.\(levelNum)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(levelColor)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.paper)
                        .clipShape(Capsule())
                        .offset(x: 4, y: 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.name)
                        .font(.display(24, weight: .heavy)).foregroundStyle(Color.paper)
                    Text(levelName)
                        .font(.bodyText(13, weight: .bold)).foregroundStyle(Color.paper.opacity(0.8))
                    // XP bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.paper.opacity(0.2)).frame(height: 8)
                            Capsule().fill(Color.paper)
                                .frame(width: geo.size.width * xpProgress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("\(xp) / \(xpNext) XP")
                        .font(.bodyText(10)).foregroundStyle(Color.paper.opacity(0.7))
                }
            }
            .padding(24)
        }
        .padding(.horizontal, 20).popShadow()
    }

    // MARK: - Streak calendar
    private var streakCalendar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(Color.quackOrange)
                Text("Activity — last 14 days")
                    .font(.display(14, weight: .heavy)).foregroundStyle(Color.ink)
                Spacer()
                Text("\(appState.streak) day streak")
                    .font(.bodyText(11, weight: .bold)).foregroundStyle(Color.quackOrange)
            }
            HStack(spacing: 4) {
                ForEach(calendarDays, id: \.date) { day in
                    let isToday = Calendar.current.isDateInToday(day.date)
                    VStack(spacing: 3) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(day.active ? Color.quackOrange : Color.inkFaint.opacity(0.5))
                                .frame(height: 34)
                            if isToday {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.quackOrange, lineWidth: 2)
                                    .frame(height: 34)
                            }
                            if day.active {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.paper)
                            }
                        }
                        Text(dayLabel(day.date))
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(day.active ? Color.ink : Color.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16).quackCard().padding(.horizontal, 20)
    }

    private func dayLabel(_ date: Date) -> String {
        let short = ["S","M","T","W","T","F","S"]
        let wd = Calendar.current.component(.weekday, from: date) - 1
        return short[wd]
    }

    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "medal.fill").foregroundStyle(Color.quackYellow)
                Text("Achievements")
                    .font(.display(14, weight: .heavy)).foregroundStyle(Color.ink)
                Spacer()
                Text("\(achievements.filter(\.unlocked).count)/\(achievements.count)")
                    .font(.bodyText(11)).foregroundStyle(Color.inkMuted)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
                ForEach(achievements, id: \.name) { ach in
                    VStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(ach.unlocked ? ach.color.opacity(0.15) : Color.inkFaint)
                                .frame(width: 52, height: 52)
                            Image(systemName: ach.symbol)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(ach.unlocked ? ach.color : Color.inkMuted.opacity(0.3))
                        }
                        Text(ach.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(ach.unlocked ? Color.ink : Color.inkMuted)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(ach.unlocked ? 1 : 0.45)
                }
            }
        }
        .padding(16).quackCard().padding(.horizontal, 20)
    }

    // MARK: - Recent stickers
    private var recentStickersSection: some View {
        let recent = Array(appState.learned.suffix(6).reversed().compactMap { id in VOCAB.first { $0.id == id } })
        if recent.isEmpty { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent stickers")
                    .font(.display(14, weight: .heavy)).foregroundStyle(Color.ink)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(recent) { item in
                        StickerTile(item: item, size: .sm)
                    }
                }
            }
            .padding(16).quackCard().padding(.horizontal, 20)
        )
    }
}

#Preview {
    let state = AppState()
    state.learned = ["apple", "cat", "dog", "rice", "mom"]
    state.streak = 5
    return ProfileView()
        .environment(state)
}
