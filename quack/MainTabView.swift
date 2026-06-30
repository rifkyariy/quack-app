import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var activeTab: TabItem = .home
    @State private var fullScreen: FullScreenState? = nil
    @AppStorage("quack.hasSeenTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false
    @State private var showDemoScan = false

    enum FullScreenState: Identifiable {
        case mission(MissionType, VocabItem)
        case complete(VocabItem)
        var id: String {
            switch self {
            case .mission(let t, let v): "m-\(t.rawValue)-\(v.id)"
            case .complete(let v):       "c-\(v.id)-\(UUID())"
            }
        }
    }

    var body: some View {
        ZStack {
            switch activeTab {
            case .home:
                NavigationStack {
                    HomeView(onMission: launchMission, activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)
            case .missions:
                NavigationStack {
                    MissionsHubView(onStartMission: launchMission, activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)
            case .library:
                NavigationStack {
                    LibraryView(activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)
            case .parent:
                NavigationStack {
                    ParentView(activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)
            }
        }
        .animation(.easeOut(duration: 0.22), value: activeTab)
        .simultaneousGesture(
            DragGesture(minimumDistance: 55)
                .onEnded { v in
                    let dx = v.translation.width
                    let dy = v.translation.height
                    // Require 2.5× horizontal bias — avoids firing during vertical scrolls
                    guard abs(dx) > abs(dy) * 2.5 else { return }
                    let tabs = TabItem.allCases
                    guard let idx = tabs.firstIndex(of: activeTab) else { return }
                    withAnimation(.easeOut(duration: 0.22)) {
                        if dx < 0, idx < tabs.count - 1 { activeTab = tabs[idx + 1] }
                        else if dx > 0, idx > 0          { activeTab = tabs[idx - 1] }
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
        )
        .onAppear {
            // Lock portrait immediately if the tutorial is about to show, to avoid
            // a brief window where rotation is allowed before the cover appears.
            OrientationLock.set(hasSeenTutorial ? .allButUpsideDown : .portrait)
            if !hasSeenTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showTutorial = true
                }
            }
        }
        .onChange(of: showTutorial) { _, isShowing in
            if isShowing { OrientationLock.set(.portrait) }
        }
        .onChange(of: showDemoScan) { _, isShowing in
            if isShowing {
                OrientationLock.set(.portrait)
            } else if !showTutorial {
                OrientationLock.set(.allButUpsideDown)
            }
        }
        .fullScreenCover(isPresented: $showTutorial) {
            TutorialView {
                showTutorial = false
                hasSeenTutorial = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showDemoScan = true
                }
            }
            .environment(appState)
        }
        .fullScreenCover(isPresented: $showDemoScan) {
            SnapPhotoView(demoMode: true)
                .environment(appState)
        }
        .fullScreenCover(item: $fullScreen) { state in
            coverView(for: state)
                .environment(appState)
        }
    }

    private func launchMission(_ type: MissionType, _ vocab: VocabItem) {
        fullScreen = .mission(type, vocab)
    }

    private func missionComplete(_ vocabId: String, missionType: String = "") {
        appState.addLearned(vocabId)
        if !missionType.isEmpty { appState.recordMission(missionType) }
        appState.rotateToNextMission()
        let earned = VOCAB.first { $0.id == vocabId } ?? VOCAB[0]
        fullScreen = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            fullScreen = .complete(earned)
        }
    }

    @ViewBuilder
    private func coverView(for state: FullScreenState) -> some View {
        switch state {
        case .mission(let type, let vocab):
            switch type {
            case .camera: CameraMissionView(vocab: vocab, onComplete: { missionComplete($0, missionType: type.rawValue) })
            case .speak:  SpeakMissionView(vocab: vocab,  onComplete: { missionComplete($0, missionType: type.rawValue) })
            case .match:  MatchMissionView(target: vocab, onComplete: { missionComplete($0, missionType: type.rawValue) })
            case .story:  StoryMissionView(vocab: vocab,  onComplete: { missionComplete($0, missionType: type.rawValue) })
            }
        case .complete(let earned):
            CompleteView(earned: earned, onDone: { fullScreen = nil })
        }
    }
}

// MARK: - Tutorial (first-time How Quack works)
private struct TutorialView: View {
    let onComplete: () -> Void
    @State private var appeared = false

    private let steps: [(symbol: String, title: String, body: String, color: Color)] = [
        ("gamecontroller.fill", "Choose a Mission",     "Pick a fun topic to explore",                  .cobalt),
        ("camera.fill",         "Scan an Object",       "Use your camera to scan anything around you",   .quackOrange),
        ("plus.circle.fill",    "Get the Translation",  "See the Chinese word and how to say it",        .quackOrange),
        ("mic.fill",            "Practice & Pronounce", "Learn the tone and perfect your pronunciation", .cobalt),
        ("star.fill",           "Collect Stickers",     "Earn stickers and unlock new rewards!",         .quackYellow),
    ]

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            FloatingShapes()

            VStack(spacing: 0) {
                Spacer().frame(height: 52)

                VStack(spacing: 8) {
                    Text("How Quack works")
                        .font(.display(28, weight: .black))
                        .foregroundStyle(Color.ink)
                    Text("Learn, play, and grow in 5 fun steps!")
                        .font(.bodyText(14))
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.05), value: appeared)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(steps.indices, id: \.self) { i in
                            let s = steps[i]
                            HStack(alignment: .top, spacing: 16) {
                                VStack(spacing: 0) {
                                    ZStack {
                                        Circle().fill(s.color.opacity(0.12)).frame(width: 52, height: 52)
                                        Image(systemName: s.symbol)
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(s.color)
                                    }
                                    if i < steps.count - 1 {
                                        Rectangle().fill(Color.inkFaint).frame(width: 2, height: 24)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.title)
                                        .font(.display(16, weight: .heavy))
                                        .foregroundStyle(Color.ink)
                                    Text(s.body)
                                        .font(.bodyText(13))
                                        .foregroundStyle(Color.inkMuted)
                                }
                                .padding(.top, 14)
                                Spacer()
                            }
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.35).delay(0.1 + Double(i) * 0.07), value: appeared)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 16)
                }

                VStack(spacing: 8) {
                    CTAButton(label: "Let's try it!", variant: .orange, action: onComplete)
                        .padding(.horizontal, 24)
                    Text("We'll do a quick demo scan together")
                        .font(.bodyText(12))
                        .foregroundStyle(Color.inkMuted)
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.45), value: appeared)
                .padding(.bottom, 40)
            }
        }
        .onAppear { appeared = true }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
