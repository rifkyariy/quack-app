import SwiftUI

struct ParentView: View {
    @Environment(AppState.self) private var appState
    @Binding var activeTab: TabItem

    @State private var showingSnap = false
    @State private var showResetConfirm = false
    @State private var showAllVocab = false
    @State private var showAdjustLimit = false
    @State private var selectedDayWords: [VocabItem] = []
    @State private var selectedDayLabel = ""
    @State private var showDaySheet = false
    @State private var showWeekAll = false
    @State private var showDevPanel = false
    @State private var showSummary = false

    var body: some View {
        MainTabChrome(active: $activeTab) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroHeader
                    VStack(spacing: 16) {
                        quickStatsRow
                            .padding(.top, 20)
                        weekChartCard
                        snapCard
                        vocabCard
                        screenSettingsCard
                        resetSection
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(Color.cream)
        }
        .fullScreenCover(isPresented: $showingSnap) { SnapPhotoView() }
        .alert("Reset Progress?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { appState.resetProgress() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will erase all learned words, streaks, and screen time.")
        }
        .sheet(isPresented: $showAdjustLimit) {
            ScreenTimeLimitSheet(currentSeconds: appState.screenTimeLimitSeconds) { s in
                appState.screenTimeLimitSeconds = s
                showAdjustLimit = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAllVocab) { allVocabSheet }
        .sheet(isPresented: $showDaySheet) { dayDetailSheet }
        .sheet(isPresented: $showDevPanel) { DevPanelView() }
        .sheet(isPresented: $showSummary) { ComprehensiveSummaryView() }
    }

    // MARK: - Hero header
    private var heroHeader: some View {
        ZStack(alignment: .bottom) {
            Color.quackOrange.ignoresSafeArea(edges: .top)
            GrainOverlay(opacity: 0.07)
            Sparkles(count: 5, color: .white, opacity: 0.4, animate: true)

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    // Child agent
                    Image(appState.codename)
                        .resizable().scaledToFit()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.paper.opacity(0.5), lineWidth: 2))
                        .cardShadow()

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Parent HQ")
                            .font(.bodyText(10, weight: .heavy))
                            .foregroundStyle(Color.paper.opacity(0.7))
                            .tracking(1)
                        Text(appState.name)
                            .font(.display(22, weight: .heavy))
                            .foregroundStyle(Color.paper)
                    }

                    Spacer()

                    // Streak
                    VStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.quackYellow)
                        Text("\(appState.streak)")
                            .font(.display(18, weight: .heavy))
                            .foregroundStyle(Color.paper)
                        Text("streak")
                            .font(.bodyText(9, weight: .bold))
                            .foregroundStyle(Color.paper.opacity(0.7))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Quick stats (2 x 2 grid)
    private var quickStatsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            quickStat(icon: "star.fill",            value: "\(appState.dailyProgress)/\(appState.dailyGoal)", label: "Stars today",  bg: Color.quackYellow.opacity(0.15), fg: Color.quackOrangeDeep)
            quickStat(icon: "checkmark.circle.fill", value: "\(appState.learned.count)",                      label: "Words learned", bg: Color.mint.opacity(0.15),        fg: Color.mintDeep)
            quickStat(icon: "clock.fill",            value: "\(appState.screenTimeSeconds / 60)m",            label: "Screen time",   bg: Color.cobalt.opacity(0.12),       fg: Color.cobalt)
            quickStat(icon: "calendar.badge.checkmark", value: "\(totalActiveThisWeek)",                      label: "Active days",   bg: Color.quackOrange.opacity(0.12),  fg: Color.quackOrange)
        }
    }

    private var totalActiveThisWeek: Int {
        let cal = Calendar.current
        return (0..<7).filter { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            return appState.weekActivity[AppState.dateKey(date)] != nil
        }.count
    }

    private func quickStat(icon: String, value: String, label: String, bg: Color, fg: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(bg).frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(fg)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.display(18, weight: .heavy))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(label)
                    .font(.bodyText(11))
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .cardShadow()
    }

    // MARK: - Week chart
    private let dummyCounts = [3, 1, 4, 0, 2, 3, 0]
    private var useDummy: Bool { appState.weekActivity.isEmpty }

    private var last7Days: [(label: String, key: String, words: [VocabItem])] {
        let cal = Calendar.current
        let short = ["Su","M","T","W","T","F","Sa"]
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let key = AppState.dateKey(date)
            let ids = appState.weekActivity[key] ?? []
            let words = ids.compactMap { id in VOCAB.first { $0.id == id } }
            let wd = cal.component(.weekday, from: date) - 1
            let label = cal.isDateInToday(date) ? "Today" : short[wd]
            return (label, key, words)
        }
    }

    private var weekChartCard: some View {
        let days = last7Days
        let counts = days.indices.map { i in useDummy ? dummyCounts[i] : days[i].words.count }
        let maxVal = max(CGFloat(counts.max() ?? 1), 1)
        let maxH: CGFloat = 80
        let weekTotal = counts.reduce(0, +)

        return VStack(spacing: 12) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This week")
                        .font(.display(16, weight: .heavy)).foregroundStyle(Color.ink)
                    if useDummy {
                        Text("Sample — start a mission!")
                            .font(.bodyText(10)).foregroundStyle(Color.inkMuted)
                    }
                }
                Spacer()
                if weekTotal > 0 {
                    Text("\(weekTotal) words")
                        .font(.bodyText(11, weight: .heavy))
                        .foregroundStyle(Color.quackOrange)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.quackOrange.opacity(0.1))
                        .clipShape(Capsule())
                }
                Button {
                    showSummary = true
                } label: {
                    HStack(spacing: 3) {
                        Text("Summary")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.bodyText(12, weight: .heavy))
                    .foregroundStyle(Color.quackOrange)
                }
                .buttonStyle(.plain)
                .padding(.leading, 6)
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(days.indices, id: \.self) { i in
                    let count = counts[i]
                    let isToday = days[i].label == "Today"
                    let isActive = count > 0
                    Button {
                        guard isActive && !useDummy else { return }
                        selectedDayWords = days[i].words
                        selectedDayLabel = days[i].label
                        showDaySheet = true
                    } label: {
                        VStack(spacing: 4) {
                            if isActive {
                                Text("\(count)")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(isToday ? Color.paper : Color.cobalt)
                                    .padding(.horizontal, 4).padding(.vertical, 1.5)
                                    .background(isToday ? Color.quackOrange : Color.cobalt.opacity(0.15))
                                    .clipShape(Capsule())
                            } else {
                                Color.clear.frame(height: 16)
                            }
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.inkFaint.opacity(0.5))
                                    .frame(height: maxH)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isToday ? Color.quackOrange : (isActive ? Color.cobalt.opacity(0.5) : Color.clear))
                                    .frame(height: isActive ? max(8, maxH * CGFloat(count) / maxVal) : 0)
                                    .animation(.spring(response: 0.45, dampingFraction: 0.7), value: count)
                            }
                            .frame(height: maxH)
                            Text(isToday ? "•" : String(days[i].label.prefix(1)))
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(isToday ? Color.quackOrange : (isActive ? Color.ink : Color.inkMuted))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isActive || useDummy)
                }
            }
            .frame(height: maxH + 38, alignment: .bottom)

            if !useDummy && days.contains(where: { !$0.words.isEmpty }) {
                Label("Tap a bar to see words", systemImage: "hand.tap.fill")
                    .font(.bodyText(9))
                    .foregroundStyle(Color.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .cardShadow()
        .sheet(isPresented: $showWeekAll) { weekAllSheet }
    }

    // MARK: - Snap card
    private var snapCard: some View {
        Button { showingSnap = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.quackOrange).frame(width: 50, height: 50)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.paper)
                }
                .cardShadow()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Snap a photo")
                        .font(.display(15, weight: .heavy)).foregroundStyle(Color.ink)
                    Text("Q names what's in it in Mandarin")
                        .font(.bodyText(12)).foregroundStyle(Color.inkMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkMuted)
            }
            .padding(14)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Vocab card
    private var recentLearnedVocab: [VocabItem] {
        appState.learned.suffix(5).reversed().compactMap { id in VOCAB.first { $0.id == id } }
    }

    private var vocabCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recently learned")
                    .font(.display(15, weight: .heavy)).foregroundStyle(Color.ink)
                Spacer()
                if !appState.learned.isEmpty {
                    Button("See all") { showAllVocab = true }
                        .font(.bodyText(12, weight: .heavy))
                        .foregroundStyle(Color.quackOrange)
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            if recentLearnedVocab.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed").foregroundStyle(Color.inkMuted)
                    Text("No words yet — start a mission!")
                        .font(.bodyText(13)).foregroundStyle(Color.inkMuted)
                }
                .padding(14)
            } else {
                ForEach(Array(recentLearnedVocab.enumerated()), id: \.element.id) { idx, item in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(item.tone.bg)
                                .frame(width: 42, height: 42)
                            Text(item.hanzi)
                                .font(.display(15, weight: .heavy))
                                .foregroundStyle(item.tone.fg)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.en.capitalized)
                                .font(.bodyText(14, weight: .bold)).foregroundStyle(Color.ink)
                            Text(item.pinyin)
                                .font(.bodyText(11)).foregroundStyle(Color.inkMuted)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16)).foregroundStyle(Color.mintDeep)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                    if idx < recentLearnedVocab.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .cardShadow()
    }

    // MARK: - Screen time + daily goal settings card
    private var screenSettingsCard: some View {
        VStack(spacing: 0) {
            // Section title
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkMuted)
                Text("Settings")
                    .font(.display(15, weight: .heavy)).foregroundStyle(Color.ink)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

            Divider().padding(.horizontal, 14)

            // Screen time row
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.cobalt.opacity(0.12)).frame(width: 38, height: 38)
                    Image(systemName: "clock.fill")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.cobalt)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Screen time")
                        .font(.bodyText(13, weight: .bold)).foregroundStyle(Color.ink)
                    let usedMin = appState.screenTimeSeconds / 60
                    let limitMin = appState.screenTimeLimitSeconds / 60
                    let isOver = appState.screenTimeSeconds >= appState.screenTimeLimitSeconds
                    Text("\(usedMin) min used · limit \(limitMin) min")
                        .font(.bodyText(11)).foregroundStyle(isOver ? Color.quackOrange : Color.inkMuted)
                        .lineLimit(1)
                }
                Spacer()
                Button("Adjust") { showAdjustLimit = true }
                    .font(.bodyText(12, weight: .heavy))
                    .foregroundStyle(Color.quackOrange)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            // Progress bar
            let pct = min(1.0, Double(appState.screenTimeSeconds) / Double(max(1, appState.screenTimeLimitSeconds)))
            let isOver = pct >= 1.0
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.inkFaint).frame(height: 6)
                    Capsule()
                        .fill(isOver ? Color.quackOrange : Color.cobalt)
                        .frame(width: geo.size.width * pct, height: 6)
                        .animation(.easeOut(duration: 0.4), value: pct)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 14)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 14)

            // Daily goal row
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.quackYellow.opacity(0.2)).frame(width: 38, height: 38)
                    Image(systemName: "star.fill")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.quackOrangeDeep)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Daily goal")
                        .font(.bodyText(13, weight: .bold)).foregroundStyle(Color.ink)
                    Text("Stars to earn each day")
                        .font(.bodyText(11)).foregroundStyle(Color.inkMuted)
                }
                Spacer()
                HStack(spacing: 14) {
                    Button {
                        if appState.dailyGoal > 1 { appState.dailyGoal -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24)).foregroundStyle(appState.dailyGoal > 1 ? Color.cobalt : Color.inkFaint)
                    }
                    .buttonStyle(TapPress()).disabled(appState.dailyGoal <= 1)

                    Text("\(appState.dailyGoal)")
                        .font(.display(20, weight: .black)).foregroundStyle(Color.ink)
                        .frame(minWidth: 24)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appState.dailyGoal)

                    Button {
                        if appState.dailyGoal < 10 { appState.dailyGoal += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24)).foregroundStyle(appState.dailyGoal < 10 ? Color.cobalt : Color.inkFaint)
                    }
                    .buttonStyle(TapPress()).disabled(appState.dailyGoal >= 10)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .cardShadow()
    }

    // MARK: - Reset + dev section
    private var resetSection: some View {
        VStack(spacing: 10) {
            Button {
                showResetConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash").font(.system(size: 13))
                    Text("Reset child's progress")
                        .font(.bodyText(13, weight: .bold))
                }
                .foregroundStyle(Color.rose)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.rose.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rose.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(TapPress())

            Button { showDevPanel = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "terminal").font(.system(size: 12))
                    Text("Developer Access")
                }
                .font(.bodyText(12))
                .foregroundStyle(Color.inkMuted)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Sheets
    private var allVocabSheet: some View {
        NavigationStack {
            List {
                ForEach(VOCAB) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(item.tone.bg).frame(width: 40, height: 40)
                            Text(item.hanzi).font(.display(15, weight: .heavy)).foregroundStyle(item.tone.fg)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.en.capitalized).font(.bodyText(14, weight: .bold)).foregroundStyle(Color.ink)
                            Text(item.pinyin).font(.bodyText(12)).foregroundStyle(Color.inkMuted)
                        }
                        Spacer()
                        if appState.learned.contains(item.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16)).foregroundStyle(Color.mintDeep)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("All Vocabulary").navigationBarTitleDisplayMode(.inline)
        }
    }

    private var weekAllSheet: some View {
        NavigationStack {
            List {
                ForEach(last7Days.reversed(), id: \.key) { day in
                    Section(day.label) {
                        if day.words.isEmpty {
                            Text("No words learned").font(.bodyText(13)).foregroundStyle(Color.inkMuted)
                        } else {
                            ForEach(day.words) { item in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(item.tone.bg).frame(width: 36, height: 36)
                                        Text(item.hanzi).font(.display(13, weight: .heavy)).foregroundStyle(item.tone.fg)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.en.capitalized).font(.bodyText(13, weight: .bold)).foregroundStyle(Color.ink)
                                        Text(item.pinyin).font(.bodyText(11)).foregroundStyle(Color.inkMuted)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("This Week").navigationBarTitleDisplayMode(.inline)
        }
    }

    private var dayDetailSheet: some View {
        NavigationStack {
            List(selectedDayWords) { item in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(item.tone.bg).frame(width: 40, height: 40)
                        Text(item.hanzi).font(.display(15, weight: .heavy)).foregroundStyle(item.tone.fg)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.en.capitalized).font(.bodyText(14, weight: .bold)).foregroundStyle(Color.ink)
                        Text(item.pinyin).font(.bodyText(12)).foregroundStyle(Color.inkMuted)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("\(selectedDayLabel) · \(selectedDayWords.count) words")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}



// MARK: - Developer Panel
private struct DevPanelView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @AppStorage("quack.hasOnboarded")    private var hasOnboarded = false
    @AppStorage("quack.hasSeenTutorial") private var hasSeenTutorial = false
    @State private var confirmReset = false

    var body: some View {
        @Bindable var state = appState
        NavigationStack {
            Form {
                Section("Scenarios") {
                    scenario("arrow.counterclockwise", "Show Onboarding")    { hasOnboarded = false; dismiss() }
                    scenario("graduationcap.fill",     "Show Tutorial")       { hasSeenTutorial = false; dismiss() }
                    scenario("wand.and.stars",         "Seed Demo Data")      { appState.seedDemoData() }
                    scenario("clock.badge.exclamationmark", "Fire Screen Alert") { appState.screenTimeLimitReached = true; dismiss() }
                    scenario("arrow.clockwise",        "Rotate Mission")      { appState.rotateToNextMission() }
                }

                Section("Flags") {
                    Toggle("Onboarding done",     isOn: $hasOnboarded)
                    Toggle("Tutorial seen",       isOn: $hasSeenTutorial)
                    Toggle("Screen limit hit",    isOn: $state.screenTimeLimitReached)
                }

                Section("Adjustments") {
                    Stepper("Streak: \(appState.streak)",        value: $state.streak,        in: 0...999)
                    Stepper("Daily goal: \(appState.dailyGoal)", value: $state.dailyGoal,     in: 1...20)
                    Stepper("Progress: \(appState.dailyProgress)", value: $state.dailyProgress, in: 0...99)
                    LabeledContent("Screen limit", value: "\(appState.screenTimeLimitSeconds / 60) min")
                }

                Section("State") {
                    LabeledContent("Name",    value: appState.name)
                    LabeledContent("Age",     value: "\(appState.age)")
                    LabeledContent("Codename",value: appState.codename)
                    LabeledContent("XP",      value: "\(appState.learned.count * 10 + appState.streak * 5)")
                    LabeledContent("Words",   value: "\(appState.learned.count)/\(VOCAB.count)")
                    LabeledContent("Mission", value: appState.todayMission.target)
                }

                Section {
                    Button("Reset progress", role: .destructive) { confirmReset = true }
                    Button("Factory reset", role: .destructive) {
                        hasOnboarded = false; hasSeenTutorial = false
                        appState.resetProgress(); dismiss()
                    }
                } header: { Text("Danger Zone") }
            }
            .navigationTitle("Developer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("Reset Progress?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) { appState.resetProgress() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Erases words, streaks, activity, and screen time.") }
        }
    }

    private func scenario(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Label(title, systemImage: icon)
        }
        .foregroundStyle(Color.primary)
    }
}


// MARK: - Comprehensive Summary
private struct ComprehensiveSummaryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    // MARK: Level
    private var xp: Int { appState.learned.count * 10 + appState.streak * 5 }
    private var levelNum: Int {
        switch xp { case 0..<30:1; case 30..<80:2; case 80..<160:3; case 160..<280:4; default:5 }
    }
    private static let levelNames = ["","Mandarin Seedling","Mandarin Sprout","Mandarin Explorer","Word Collector","Mandarin Champion"]
    private static let levelColors: [Color] = [.clear,.mintDeep,.cobalt,.quackOrange,.quackOrangeDeep,.quackYellow]
    private var levelName: String { Self.levelNames[levelNum] }
    private var levelColor: Color { Self.levelColors[levelNum] }
    private var xpProgress: CGFloat {
        let bases = [0,30,80,160,280]; let nexts = [30,80,160,280,9999]
        return CGFloat(xp - bases[levelNum-1]) / CGFloat(max(nexts[levelNum-1] - bases[levelNum-1], 1))
    }

    // MARK: Data
    private var days28: [(date: Date, count: Int)] {
        (0..<28).reversed().map { offset in
            let d = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            return (d, appState.weekActivity[AppState.dateKey(d)]?.count ?? 0)
        }
    }
    private var days14: [(label: String, count: Int, isToday: Bool)] {
        let cal = Calendar.current; let s = ["Su","M","T","W","T","F","Sa"]
        return (0..<14).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: Date())!
            return (s[cal.component(.weekday, from: d)-1],
                    appState.weekActivity[AppState.dateKey(d)]?.count ?? 0,
                    offset == 0)
        }
    }
    private var categoryMastery: [(cat: Category, learned: Int, total: Int)] {
        CATEGORIES.map { cat in
            (cat,
             VOCAB.filter { $0.cat==cat.id && appState.learned.contains($0.id) }.count,
             VOCAB.filter { $0.cat==cat.id }.count)
        }
    }
    private var missionOrder: [(name: String, icon: String, count: Int, color: Color)] {
        [("Scan it","camera.fill",appState.missionStats["camera"] ?? 0,.quackOrange),
         ("Say it","mic.fill",appState.missionStats["speak"] ?? 0,.cobalt),
         ("Match it","flag.fill",appState.missionStats["match"] ?? 0,.rose),
         ("Story time","books.vertical.fill",appState.missionStats["story"] ?? 0,.mint)
        ].sorted { $0.count > $1.count }
    }
    private func sumHours(_ hours: [Int]) -> Int { hours.reduce(0) { $0 + (appState.hourActivity[$1] ?? 0) } }
    private var hourBuckets: [(label: String, icon: String, count: Int)] {[
        ("Morning",   "sunrise.fill",    sumHours(Array(6...11))),
        ("Afternoon", "sun.max.fill",    sumHours(Array(12...17))),
        ("Evening",   "sunset.fill",     sumHours(Array(18...21))),
        ("Night",     "moon.stars.fill", sumHours(Array(22...23)+Array(0...5)))
    ]}
    private var weekTotal: Int { days14.suffix(7).map(\.count).reduce(0,+) }
    private var weekVsPrev: Int { weekTotal - days14.prefix(7).map(\.count).reduce(0,+) }
    private var bestDay: Int { days28.map(\.count).max() ?? 0 }
    private var totalActive28: Int { days28.filter { $0.count > 0 }.count }
    private var dailyAvg: Double { Double(weekTotal) / 7.0 }
    private var weekdayTotals: [(name: String, total: Int)] {
        let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        var t = Array(repeating: 0, count: 7)
        for (date, count) in days28 { t[Calendar.current.component(.weekday, from: date)-1] += count }
        return names.indices.map { (names[$0], t[$0]) }
    }
    private var bestWeekday: String { weekdayTotals.max(by: { $0.total < $1.total })?.name ?? "—" }
    private var wordsToReview: [VocabItem] {
        Array(appState.learned.prefix(5).compactMap { id in VOCAB.first { $0.id == id } })
    }

    // MARK: Achievements
    private struct Ach { let symbol: String; let name: String; let unlocked: Bool; let color: Color }
    private var achievements: [Ach] {[
        Ach(symbol:"star.fill",          name:"First Word",  unlocked:!appState.learned.isEmpty,                                  color:.quackYellow),
        Ach(symbol:"flame.fill",         name:"On Fire",     unlocked:appState.streak >= 3,                                       color:.quackOrange),
        Ach(symbol:"bolt.fill",          name:"7-Day",       unlocked:appState.streak >= 7,                                       color:.quackOrangeDeep),
        Ach(symbol:"checkmark.seal.fill",name:"10 Words",    unlocked:appState.learned.count >= 10,                               color:.cobalt),
        Ach(symbol:"crown.fill",         name:"Champion",    unlocked:appState.learned.count >= 20,                               color:.quackYellow),
        Ach(symbol:"leaf.fill",          name:"Cat. Pro",    unlocked:categoryMastery.contains { $0.learned == $0.total && $0.total > 0 }, color:.mintDeep),
        Ach(symbol:"moon.stars.fill",    name:"Night Owl",   unlocked:sumHours(Array(0...5)+Array(22...23)) > 0,                  color:.cobalt),
        Ach(symbol:"sunrise.fill",       name:"Early Bird",  unlocked:sumHours(Array(6...8)) > 0,                                 color:.quackYellow),
        Ach(symbol:"camera.fill",        name:"Scanner",     unlocked:(appState.missionStats["camera"] ?? 0) > 0,                 color:.quackOrange),
    ]}

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileCard
                    statsGrid
                    achievementsSection
                    heatmapSection
                    curveSection
                    categorySection
                    bestDaySection
                    missionSection
                    timeSection
                    reviewSection
                    if dailyAvg >= 0.1 { milestonesSection }
                    Spacer().frame(height: 32)
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
            }
            .background(Color.cream)
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Layout helpers

    /// Section card with consistent padding and no GeometryReader at top level.
    private func card<C: View>(title: String, icon: String, color: Color = .quackOrange, @ViewBuilder content: @escaping () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.display(15, weight: .heavy))
                    .foregroundStyle(Color.ink)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .cardShadow()
    }

    // MARK: 1. Profile card
    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                Image(appState.codename)
                    .resizable().scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(levelColor.opacity(0.6), lineWidth: 2))
                Text("Lv.\(levelNum)")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.paper)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(levelColor)
                    .clipShape(Capsule())
                    .offset(x: 4, y: 4)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(appState.name)
                    .font(.display(20, weight: .heavy))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                Text(levelName)
                    .font(.bodyText(12, weight: .bold))
                    .foregroundStyle(levelColor)
                    .lineLimit(1)
                // XP bar — no GeometryReader, use overlay trick
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.inkFaint).frame(height: 7)
                    GeometryReader { g in
                        Capsule()
                            .fill(LinearGradient(colors: [levelColor.opacity(0.7), levelColor],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, g.size.width * xpProgress), height: 7)
                            .animation(.easeOut(duration: 0.8), value: xpProgress)
                    }
                    .frame(height: 7)
                }
                .frame(height: 7)
                Text("\(xp) XP · \(max(0, [30,80,160,280,9999][levelNum-1] - xp)) to next")
                    .font(.bodyText(10))
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .cardShadow()
    }

    // MARK: 2. Stats 2×2 — avoids HStack overflow
    private var statsGrid: some View {
        let up = weekVsPrev >= 0
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                   GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statTile("book.fill",       "\(weekTotal)",             "Words this week", .cobalt)
            statTile("flame.fill",      "\(appState.streak)",       "Day streak",       .orange)
            statTile("trophy.fill",     "\(bestDay)",               "Best single day",  .yellow)
            statTile(up ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                     (up ? "+" : "")+"\(weekVsPrev)",
                     "vs last week", up ? .mint : .rose)
        }
    }

    private func statTile(_ icon: String, _ value: String, _ label: String, _ color: Tone) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(color.bg).frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color.fg)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.display(18, weight: .heavy))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(label)
                    .font(.bodyText(11))
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .cardShadow()
    }

    // MARK: 3. Achievements
    private var achievementsSection: some View {
        card(title: "Achievements", icon: "medal.fill", color: .quackYellow) {
            Text("\(achievements.filter(\.unlocked).count) of \(achievements.count) unlocked")
                .font(.bodyText(11))
                .foregroundStyle(Color.inkMuted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                      spacing: 14) {
                ForEach(achievements, id: \.name) { a in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(a.unlocked ? a.color.opacity(0.15) : Color.inkFaint)
                                .frame(width: 50, height: 50)
                            Image(systemName: a.symbol)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(a.unlocked ? a.color : Color.inkMuted.opacity(0.3))
                            if !a.unlocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.inkMuted.opacity(0.4))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    .padding(5)
                            }
                        }
                        Text(a.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(a.unlocked ? Color.ink : Color.inkMuted)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(a.unlocked ? 1 : 0.45)
                }
            }
        }
    }

    // MARK: 4. Heatmap
    private var heatmapSection: some View {
        card(title: "28-Day Activity", icon: "calendar", color: .cobalt) {
            let maxC = max(days28.map(\.count).max() ?? 1, 1)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7),
                      spacing: 3) {
                ForEach(days28.indices, id: \.self) { i in
                    let d = days28[i]
                    let isToday = Calendar.current.isDateInToday(d.date)
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(d.count > 0
                                  ? Color.quackOrange.opacity(0.18 + 0.82 * CGFloat(d.count) / CGFloat(maxC))
                                  : Color.inkFaint.opacity(0.35))
                            .frame(height: 26)
                        if isToday {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.quackOrange, lineWidth: 1.5)
                        }
                        if d.count > 0 {
                            Text("\(d.count)")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(Color.paper.opacity(0.9))
                        }
                    }
                }
            }
            HStack(spacing: 6) {
                Text("Less").font(.bodyText(9)).foregroundStyle(Color.inkMuted)
                ForEach([0.15, 0.4, 0.7, 1.0] as [Double], id: \.self) { v in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.quackOrange.opacity(v))
                        .frame(width: 14, height: 10)
                }
                Text("More").font(.bodyText(9)).foregroundStyle(Color.inkMuted)
                Spacer()
                Text("\(totalActive28) days active")
                    .font(.bodyText(10, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    // MARK: 5. Learning curve
    private var curveSection: some View {
        card(title: "Learning Curve", icon: "chart.line.uptrend.xyaxis", color: .cobalt) {
            let up = weekVsPrev >= 0
            HStack(spacing: 4) {
                Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 11, weight: .bold))
                Text((up ? "+" : "")+"\(weekVsPrev) vs last week")
                    .font(.bodyText(11, weight: .bold))
            }
            .foregroundStyle(up ? Color.mintDeep : Color.quackOrange)
            .frame(maxWidth: .infinity, alignment: .leading)

            let maxVal = max(CGFloat(days14.map(\.count).max() ?? 1), 1)
            let maxH: CGFloat = 72
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(days14.indices, id: \.self) { i in
                    let d = days14[i]
                    VStack(spacing: 3) {
                        if d.count > 0 {
                            Text("\(d.count)")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(d.isToday ? Color.quackOrange : Color.cobalt.opacity(0.8))
                        } else {
                            Color.clear.frame(height: 12)
                        }
                        RoundedRectangle(cornerRadius: 4)
                            .fill(d.isToday ? Color.quackOrange : Color.cobalt.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .frame(height: d.count > 0 ? max(4, maxH * CGFloat(d.count) / maxVal) : 4)
                        Text(d.label)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(d.isToday ? Color.quackOrange : Color.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: maxH + 28, alignment: .bottom)
        }
    }

    // MARK: 6. Category mastery (progress bars — reliable, no rings overflow)
    private var categorySection: some View {
        card(title: "Category Mastery", icon: "circle.hexagongrid.fill", color: .cobalt) {
            ForEach(categoryMastery, id: \.cat.id) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.cat.label)
                            .font(.bodyText(13, weight: .bold))
                            .foregroundStyle(Color.ink)
                        Spacer()
                        Text("\(item.learned)/\(item.total)")
                            .font(.bodyText(11, weight: .bold))
                            .foregroundStyle(Color.inkMuted)
                    }
                    // Progress bar via overlay instead of GeometryReader to avoid height issues
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.inkFaint).frame(height: 8)
                        GeometryReader { g in
                            Capsule()
                                .fill(item.cat.tone.fg)
                                .frame(width: max(0, g.size.width * CGFloat(item.learned) / CGFloat(max(item.total,1))),
                                       height: 8)
                                .animation(.easeOut(duration: 0.6), value: item.learned)
                        }
                        .frame(height: 8)
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    // MARK: 7. Best day
    private var bestDaySection: some View {
        card(title: "Best Day of Week", icon: "calendar.badge.clock", color: .quackOrange) {
            Text("\(bestWeekday) is the best day!")
                .font(.bodyText(12, weight: .heavy))
                .foregroundStyle(Color.quackOrange)
            let maxWD = max(weekdayTotals.map(\.total).max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(weekdayTotals, id: \.name) { wd in
                    let isBest = wd.name == bestWeekday
                    VStack(spacing: 3) {
                        if wd.total > 0 {
                            Text("\(wd.total)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(isBest ? Color.quackOrange : Color.cobalt.opacity(0.7))
                        } else {
                            Color.clear.frame(height: 12)
                        }
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.inkFaint.opacity(0.4))
                                .frame(height: 52)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isBest ? Color.quackOrange : Color.cobalt.opacity(0.3))
                                .frame(height: wd.total > 0 ? max(4, 52 * CGFloat(wd.total) / CGFloat(maxWD)) : 4)
                        }
                        .frame(height: 52)
                        Text(String(wd.name.prefix(2)))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isBest ? Color.quackOrange : Color.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 72, alignment: .bottom)
        }
    }

    // MARK: 8. Mission performance
    private var missionSection: some View {
        card(title: "Mission Performance", icon: "gamecontroller.fill", color: .cobalt) {
            if missionOrder.allSatisfy({ $0.count == 0 }) {
                Label("Complete missions to see stats.", systemImage: "info.circle")
                    .font(.bodyText(12))
                    .foregroundStyle(Color.inkMuted)
            } else {
                let maxM = max(missionOrder.map(\.count).max() ?? 1, 1)
                ForEach(missionOrder, id: \.name) { m in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(m.color.opacity(0.12)).frame(width: 36, height: 36)
                            Image(systemName: m.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(m.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(m.name)
                                    .font(.bodyText(13, weight: .bold))
                                    .foregroundStyle(Color.ink)
                                Spacer()
                                Text("\(m.count)×")
                                    .font(.bodyText(11, weight: .heavy))
                                    .foregroundStyle(m.color)
                            }
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.inkFaint).frame(height: 6)
                                GeometryReader { g in
                                    Capsule().fill(m.color)
                                        .frame(width: max(0, g.size.width * CGFloat(m.count) / CGFloat(maxM)), height: 6)
                                }
                                .frame(height: 6)
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
    }

    // MARK: 9. Time of day (2×2 grid — no single-row overflow)
    private var timeSection: some View {
        card(title: "Time of Day", icon: "clock.fill", color: .cobalt) {
            let maxT = max(hourBuckets.map(\.count).max() ?? 1, 1)
            let peak = hourBuckets.allSatisfy({ $0.count == 0 })
                ? nil : hourBuckets.max(by: { $0.count < $1.count })?.label

            if let p = peak {
                Text("\(p) is the peak time")
                    .font(.bodyText(11, weight: .bold))
                    .foregroundStyle(Color.cobalt)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(hourBuckets, id: \.label) { b in
                    let isPeak = b.label == peak
                    VStack(spacing: 8) {
                        Image(systemName: b.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isPeak ? Color.cobalt : Color.inkMuted)
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.inkFaint.opacity(0.35))
                                .frame(height: 40)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isPeak ? Color.cobalt : Color.cobalt.opacity(0.2))
                                .frame(height: max(4, 40 * CGFloat(b.count) / CGFloat(maxT)))
                                .animation(.easeOut(duration: 0.6), value: b.count)
                        }
                        .frame(height: 40)
                        Text(b.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isPeak ? Color.cobalt : Color.inkMuted)
                            .lineLimit(1)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(isPeak ? Color.cobalt.opacity(0.07) : Color.inkFaint.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if hourBuckets.allSatisfy({ $0.count == 0 }) {
                Text("Learn more words to see your peak time!")
                    .font(.bodyText(11))
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    // MARK: 10. Words to review
    private var reviewSection: some View {
        card(title: "Review These Words", icon: "arrow.clockwise.circle.fill", color: .quackOrange) {
            if wordsToReview.isEmpty {
                Label("Learn some words to get review suggestions.", systemImage: "info.circle")
                    .font(.bodyText(12))
                    .foregroundStyle(Color.inkMuted)
            } else {
                Text("Oldest learned — good to revisit")
                    .font(.bodyText(11))
                    .foregroundStyle(Color.inkMuted)
                ForEach(wordsToReview) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.tone.bg)
                                .frame(width: 38, height: 38)
                            Text(item.hanzi)
                                .font(.display(13, weight: .heavy))
                                .foregroundStyle(item.tone.fg)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.en.capitalized)
                                .font(.bodyText(13, weight: .bold))
                                .foregroundStyle(Color.ink)
                                .lineLimit(1)
                            Text(item.pinyin)
                                .font(.bodyText(11))
                                .foregroundStyle(Color.inkMuted)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.quackOrange)
                    }
                }
            }
        }
    }

    // MARK: 11. Milestones
    private var milestonesSection: some View {
        card(title: "Projected Milestones", icon: "flag.checkered.2.crossed", color: .quackOrange) {
            ForEach(categoryMastery, id: \.cat.id) { item in
                let remaining = item.total - item.learned
                if remaining > 0 {
                    let days = Int(ceil(Double(remaining) / max(dailyAvg, 0.1)))
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(item.cat.tone.bg).frame(width: 30, height: 30)
                            Image(systemName: "flag.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(item.cat.tone.fg)
                        }
                        Text(item.cat.label)
                            .font(.bodyText(13, weight: .bold))
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("~\(days)d")
                                .font(.display(13, weight: .heavy))
                                .foregroundStyle(item.cat.tone.fg)
                                .lineLimit(1)
                            Text("\(remaining) left")
                                .font(.bodyText(9))
                                .foregroundStyle(Color.inkMuted)
                        }
                    }
                }
            }
        }
    }
}


// MARK: - Screen Time Limit Sheet
private struct ScreenTimeLimitSheet: View {
    let currentSeconds: Int
    let onSave: (Int) -> Void

    @State private var sliderMinutes: Double

    private let presets = [15, 30, 60, 120]  // 15m, 30m, 1h, 2h
    private let presetLabels = ["15m", "30m", "1h", "2h"]
    @State private var showCustomPicker = false

    init(currentSeconds: Int, onSave: @escaping (Int) -> Void) {
        self.currentSeconds = currentSeconds
        self.onSave = onSave
        _sliderMinutes = State(initialValue: Double(max(15, min(120, currentSeconds / 60))))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle + title
            VStack(spacing: 16) {
                Text("Daily Screen Time Limit")
                    .font(.display(17, weight: .heavy))
                    .foregroundStyle(Color.ink)

                // Big time display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(sliderMinutes))")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(Color.quackOrange)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: sliderMinutes)
                    Text("min")
                        .font(.display(22, weight: .heavy))
                        .foregroundStyle(Color.inkMuted)
                }

                // Preset buttons
                HStack(spacing: 8) {
                    ForEach(Array(zip(presets, presetLabels)), id: \.0) { preset, label in
                        let active = Int(sliderMinutes) == preset
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                sliderMinutes = Double(preset)
                                showCustomPicker = false
                            }
                        } label: {
                            Text(label)
                                .font(.bodyText(13, weight: .heavy))
                                .foregroundStyle(active ? Color.paper : Color.inkMuted)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(active ? Color.quackOrange : Color.inkFaint)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(TapPress())
                        .animation(.easeOut(duration: 0.18), value: active)
                    }
                    // Custom
                    Button {
                        withAnimation { showCustomPicker.toggle() }
                    } label: {
                        Text("Custom")
                            .font(.bodyText(13, weight: .heavy))
                            .foregroundStyle(showCustomPicker ? Color.paper : Color.inkMuted)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(showCustomPicker ? Color.cobalt : Color.inkFaint)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(TapPress())
                }

                // Custom slider — only shown when Custom is selected
                if showCustomPicker {
                    VStack(spacing: 6) {
                        Slider(value: $sliderMinutes, in: 15...120, step: 5)
                            .tint(Color.cobalt)
                        HStack {
                            Text("15 min").font(.bodyText(10)).foregroundStyle(Color.inkMuted)
                            Spacer()
                            Text("2 hrs").font(.bodyText(10)).foregroundStyle(Color.inkMuted)
                        }
                    }
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .offset(y: -6)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Save
            CTAButton(label: "Save limit", variant: .orange) {
                onSave(Int(sliderMinutes) * 60)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.cream)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var tab = TabItem.parent
    let state = AppState()
    state.streak = 5
    state.dailyProgress = 2
    state.learned = ["apple", "cat", "dog"]
    return ParentView(activeTab: $tab)
        .environment(state)
}
