import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var activeTab: TabItem = .home
    @State private var fullScreen: FullScreenState? = nil

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
        .fullScreenCover(item: $fullScreen) { state in
            coverView(for: state)
                .environment(appState)
        }
    }

    private func launchMission(_ type: MissionType, _ vocab: VocabItem) {
        fullScreen = .mission(type, vocab)
    }

    private func missionComplete(_ vocabId: String) {
        appState.addLearned(vocabId)
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
            case .camera: CameraMissionView(vocab: vocab, onComplete: missionComplete)
            case .speak:  SpeakMissionView(vocab: vocab, onComplete: missionComplete)
            case .match:  MatchMissionView(target: vocab, onComplete: missionComplete)
            case .story:  StoryMissionView(vocab: vocab, onComplete: missionComplete)
            }
        case .complete(let earned):
            CompleteView(earned: earned, onDone: { fullScreen = nil })
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}


#Preview {
    MainTabView()
        .environment(AppState())
}
