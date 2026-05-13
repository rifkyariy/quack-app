import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var activeTab: TabItem = .home
    @State private var activeMission: ActiveMission? = nil
    @State private var showComplete = false
    @State private var earnedVocabId: String? = nil

    struct ActiveMission: Identifiable {
        let id = UUID()
        let type: MissionType
        let vocab: VocabItem
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
                    LibraryPlaceholder(activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)

            case .parent:
                NavigationStack {
                    ParentPlaceholder(activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)
            }
        }
        .animation(.easeOut(duration: 0.22), value: activeTab)
        .fullScreenCover(item: $activeMission) { mission in
            missionView(for: mission)
                .environment(appState)
        }
        .fullScreenCover(isPresented: $showComplete) {
            if let id = earnedVocabId, let earned = VOCAB.first(where: { $0.id == id }) {
                CompleteView(earned: earned, onDone: { showComplete = false })
                    .environment(appState)
            }
        }
    }

    private func launchMission(_ type: MissionType, _ vocab: VocabItem) {
        activeMission = ActiveMission(type: type, vocab: vocab)
    }

    private func missionComplete(_ vocabId: String) {
        appState.addLearned(vocabId)
        earnedVocabId = vocabId
        activeMission = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showComplete = true
        }
    }

    @ViewBuilder
    private func missionView(for mission: ActiveMission) -> some View {
        switch mission.type {
        case .camera:
            CameraMissionView(vocab: mission.vocab, onComplete: missionComplete)
        case .speak:
            SpeakMissionView(vocab: mission.vocab, onComplete: missionComplete)
        case .match:
            MatchMissionView(target: mission.vocab, onComplete: missionComplete)
        case .story:
            StoryMissionView(vocab: mission.vocab, onComplete: missionComplete)
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Phase 3 placeholders
struct LibraryPlaceholder: View {
    @Binding var activeTab: TabItem
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                Text("Sticker Book").font(.display(24))
                Text("Coming in Phase 3").font(.bodyText(14)).foregroundStyle(Color.inkMuted)
                Spacer()
            }
            .background(Color.cream)
            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct ParentPlaceholder: View {
    @Binding var activeTab: TabItem
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                Text("Parent Dashboard").font(.display(24))
                Text("Coming in Phase 3").font(.bodyText(14)).foregroundStyle(Color.inkMuted)
                Spacer()
            }
            .background(Color.cream)
            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
