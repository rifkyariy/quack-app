import SwiftUI

struct ParentView: View {
    @Environment(AppState.self) private var appState
    @Binding var activeTab: TabItem

    @State private var showingSnap = false
    @State private var pulse = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    statCards
                    weekChart
                    snapButton
                    vocabList
                    deviceCard
                    screentimeCard
                    CTAButton(label: "Reset child's progress", variant: .ghost, action: { appState.resetProgress() })
                        .padding(.horizontal, 24)
                    Spacer().frame(height: 120)
                }
                .padding(.top, 16)
            }
            .background(Color.cream)

            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(isPresented: $showingSnap) { SnapPhotoView() }
        .onAppear { pulse = true }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: "Parent HQ", color: .quackOrange, flank: true, size: 12)
            Text("Dashboard")
                .font(.display(32, weight: .heavy))
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.bottom, 4)
    }

    // MARK: - Stat Cards
    private var statCards: some View {
        HStack(spacing: 12) {
            statCard(
                icon: .star,
                value: "\(appState.dailyProgress)",
                label: "Stars today",
                tone: .orange
            )
            statCard(
                icon: .fire,
                value: "\(appState.streak)",
                label: "Day streak",
                tone: .cobalt
            )
            statCard(
                icon: .check,
                value: "\(appState.learned.count)",
                label: "Words",
                tone: .mint
            )
        }
        .padding(.horizontal, 24)
    }

    private func statCard(icon: QuackIconName, value: String, label: String, tone: Tone) -> some View {
        VStack(spacing: 6) {
            QuackIcon(name: icon, size: 22, color: tone.fg, strokeWidth: 2)
            Text(value)
                .font(.display(22, weight: .heavy))
                .foregroundStyle(tone.fg)
            Text(label)
                .font(.bodyText(11, weight: .bold))
                .foregroundStyle(tone.fg.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .quackCard(tone: tone)
    }

    // MARK: - Week Chart
    private var weekChart: some View {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        let values: [Int] = [2, 1, 3, 0, 2, 1, appState.dailyProgress]
        let maxVal = max(Double(values.max() ?? 1), 1)
        let maxH: CGFloat = 80
        return VStack(alignment: .leading, spacing: 12) {
            Text("This week")
                .font(.display(16, weight: .heavy))
                .foregroundStyle(Color.ink)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days.indices, id: \.self) { i in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(i == 6 ? Color.quackOrange : Color.cobalt.opacity(0.35))
                            .frame(width: 28, height: max(4, maxH * CGFloat(values[i]) / CGFloat(maxVal)))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .animation(.easeOut, value: values[i])
                        Text(days[i])
                            .font(.bodyText(11, weight: .bold))
                            .foregroundStyle(i == 6 ? Color.ink : Color.inkMuted)
                    }
                }
            }
            .frame(height: maxH + 20, alignment: .bottom)
        }
        .padding(16)
        .quackCard()
        .padding(.horizontal, 24)
    }

    // MARK: - Snap Button
    private var snapButton: some View {
        Button { showingSnap = true } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.quackOrange)
                    .frame(width: 52, height: 52)
                    .overlay(QuackIcon(name: .photo, size: 26, color: .white, strokeWidth: 2))
                    .popShadow()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Snap a photo")
                        .font(.display(16, weight: .heavy))
                        .foregroundStyle(Color.ink)
                    Text("Q will name what's in it")
                        .font(.bodyText(13))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
                QuackIcon(name: .chevron, size: 18, color: .inkMuted, strokeWidth: 2)
            }
            .padding(16)
            .quackCard()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    // MARK: - Vocab List
    private var vocabList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Vocabulary")
                .font(.display(16, weight: .heavy))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(VOCAB.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(item.tone.bg)
                                .frame(width: 44, height: 44)
                            Text(item.hanzi)
                                .font(.display(16, weight: .heavy))
                                .foregroundStyle(item.tone.fg)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.en)
                                .font(.bodyText(14, weight: .bold))
                                .foregroundStyle(Color.ink)
                            Text(item.pinyin)
                                .font(.bodyText(12))
                                .foregroundStyle(Color.inkMuted)
                        }
                        Spacer()
                        if appState.learned.contains(item.id) {
                            QuackIcon(name: .check, size: 18, color: .mintDeep, strokeWidth: 2)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)

                    if index < VOCAB.count - 1 {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .quackCard()
        .padding(.horizontal, 24)
    }

    // MARK: - Device Card
    private var deviceCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.mintDeep)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.mintDeep.opacity(0.3), lineWidth: 2)
                        .scaleEffect(pulse ? 1.8 : 1)
                        .animation(.easeInOut(duration: 1.2).repeatForever(), value: pulse)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Edge device")
                    .font(.bodyText(13, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text("Connected · syncing vocab")
                    .font(.bodyText(11))
                    .foregroundStyle(Color.inkMuted)
            }
            Spacer()
            Pill(text: "Live", color: .mintDeep, bg: Color.mint.opacity(0.25), pulseDot: true)
        }
        .padding(16)
        .quackCard()
        .padding(.horizontal, 24)
    }

    // MARK: - Screentime Card
    private var screentimeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Screen time today")
                    .font(.display(15, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("12 min / 30 min")
                    .font(.bodyText(12))
                    .foregroundStyle(Color.inkMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.inkFaint).frame(height: 8)
                    Capsule().fill(Color.quackOrange).frame(width: geo.size.width * 0.4, height: 8)
                }
            }
            .frame(height: 8)
            Button("Adjust limit") {}
                .font(.bodyText(13, weight: .heavy))
                .foregroundStyle(Color.quackOrange)
                .buttonStyle(.plain)
        }
        .padding(16)
        .quackCard()
        .padding(.horizontal, 24)
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
