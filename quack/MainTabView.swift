import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var activeTab: TabItem = .home
    @State private var missionType: String? = nil

    var body: some View {
        ZStack {
            switch activeTab {
            case .home:
                NavigationStack {
                    HomeView(onMission: { type in missionType = type }, activeTab: $activeTab)
                        .navigationBarHidden(true)
                }
                .transition(.screenIn)

            case .missions:
                NavigationStack {
                    MissionsPlaceholder(activeTab: $activeTab)
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
        .sheet(item: $missionType) { type in
            MissionPlaceholder(type: type, onDismiss: { missionType = nil })
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Phase 2 / 3 placeholders
struct MissionsPlaceholder: View {
    @Binding var activeTab: TabItem
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                Text("Missions Hub").font(.display(24))
                Text("Coming in Phase 2").font(.bodyText(14)).foregroundStyle(Color.inkMuted)
                Spacer()
            }
            .background(Color.cream)
            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

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

struct MissionPlaceholder: View {
    let type: String
    let onDismiss: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("Mission: \(type)").font(.display(24))
            Text("Coming in Phase 2").font(.bodyText(14)).foregroundStyle(Color.inkMuted)
            CTAButton(label: "Close", variant: .ink, action: onDismiss)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cream)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
