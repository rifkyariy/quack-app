import SwiftUI

struct HomeView: View {
    let onSelectMission: (Int) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack(alignment: .top) {
            Color.quCream.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        sectionLabel("YOUR MISSIONS")
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Mission.all) { mission in
                                MissionCard(mission: mission) {
                                    guard mission.isUnlocked else { return }
                                    onSelectMission(mission.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 36)
                    }
                    .padding(.top, 20)
                }
            }
        }
    }

    // ── Header ────────────────────────────────────────────────────────────
    private var headerBar: some View {
        HStack(spacing: 12) {
            DuckView(size: 54)

            VStack(alignment: .leading, spacing: 2) {
                Text("Hi, little learner! 👋")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Text("Keep quacking!")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            // Streak badge
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 18))
                Text("7")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.quRed.opacity(0.55))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1.5))
        }
        .padding(.horizontal, 20)
        .padding(.top, 58)
        .padding(.bottom, 20)
        .background(Color.quOrange)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundColor(Color.quNavy.opacity(0.45))
            .padding(.horizontal, 20)
    }
}

// ── Mission card ─────────────────────────────────────────────────────────────
struct MissionCard: View {
    let mission: Mission
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(mission.emoji).font(.system(size: 34))
                    Spacer()
                    if !mission.isUnlocked {
                        Text("🔒").font(.system(size: 20))
                    }
                }

                Text(mission.chineseTitle)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text(mission.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                if mission.isUnlocked {
                    progressBar(progress: mission.progress)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .caveBox(
                fill: mission.isUnlocked ? mission.color : .gray.opacity(0.45),
                radius: 20, border: 3, sx: 4, sy: 4
            )
            .opacity(mission.isUnlocked ? 1.0 : 0.72)
        }
        .buttonStyle(CavePress())
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.2)).frame(height: 8)
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: geo.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    HomeView { _ in }
}
