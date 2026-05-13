import SwiftUI

struct MissionsHubView: View {
    var onStartMission: (MissionType, VocabItem) -> Void
    @Binding var activeTab: TabItem
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    private var todayWord: VocabItem {
        VOCAB.first { $0.id == appState.todayMission.target } ?? VOCAB[0]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "Daily Briefing", flank: false, size: 11)
                        Text("Choose your mission")
                            .font(.display(28, weight: .heavy))
                            .foregroundStyle(Color.ink)
                        Text("Train across all 4 styles")
                            .font(.bodyText(14))
                            .foregroundStyle(Color.inkMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        ForEach(MissionType.allCases.indices, id: \.self) { i in
                            let type = MissionType.allCases[i]
                            HubMissionCard(type: type, word: todayWord) {
                                onStartMission(type, todayWord)
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)
                            .animation(
                                .easeOut(duration: 0.32).delay(Double(i) * 0.08),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer().frame(height: 120)
                }
            }
            .background(Color.cream)

            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear { appeared = true }
    }
}

private struct HubMissionCard: View {
    let type: MissionType
    let word: VocabItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(type.tone.bg)
                    .grain()

                Sparkles(count: 4, opacity: 0.35)

                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 56, height: 56)
                        .overlay(
                            QuackIcon(name: type.icon, size: 28, color: type.tone.fg, strokeWidth: 2)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.title)
                            .font(.display(18, weight: .heavy))
                            .foregroundStyle(type.tone.fg)
                        Text(type.subtitle)
                            .font(.bodyText(13))
                            .foregroundStyle(type.tone.fg.opacity(0.85))

                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { _ in
                                QuackIcon(name: .star, size: 14, color: type.tone.fg.opacity(0.55))
                            }
                        }
                        .padding(.top, 2)
                    }

                    Spacer()

                    QuackIcon(name: .chevron, size: 20, color: type.tone.fg.opacity(0.65), strokeWidth: 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
            .popShadow()
        }
        .buttonStyle(TapPress())
    }
}

#Preview {
    @Previewable @State var tab = TabItem.missions
    MissionsHubView(onStartMission: { _, _ in }, activeTab: $tab)
        .environment(AppState())
}
