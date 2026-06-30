import SwiftUI
import Sticker

struct LibraryView: View {
    @Binding var activeTab: TabItem
    @Environment(AppState.self) private var appState

    @State private var selectedCat: String = "all"
    @State private var selectedSticker: VocabItem? = nil
    @State private var selectedCollectible: SavedCollectible? = nil

    private var learnedCount: Int { appState.learned.count }

    var body: some View {
        MainTabChrome(active: $activeTab) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.quackYellow)
                            .grain(opacity: 0.08)
                        Sparkles(count: 6, color: .white, opacity: 0.6, animate: true)
                        VStack(spacing: 8) {
                            Eyebrow(text: "Your sticker book", color: .ink, flank: true, size: 12)
                            Text("Words I know")
                                .font(.display(32, weight: .heavy))
                                .foregroundStyle(Color.ink)
                            Text("\(learnedCount) of \(VOCAB.count) collected")
                                .font(.bodyText(15, weight: .semibold))
                                .foregroundStyle(Color.ink.opacity(0.6))
                        }
                        .padding(.vertical, 32)
                    }
                    .padding(.horizontal, 16).padding(.top, 16).popShadow()

                    // Category chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(label: "All", id: "all", selectedCat: $selectedCat)
                            ForEach(CATEGORIES) { cat in
                                CategoryChip(label: cat.label, id: cat.id, selectedCat: $selectedCat)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 16)
                    }

                    // Grid
                    if selectedCat == "all" {
                        ForEach(CATEGORIES) { cat in
                            let items = VOCAB.filter { $0.cat == cat.id }
                            if !items.isEmpty {
                                Text(cat.label)
                                    .font(.display(16, weight: .heavy)).foregroundStyle(Color.ink)
                                    .padding(.leading, 20).padding(.top, 12).padding(.bottom, 4)
                                stickerGrid(items: items)
                            }
                        }
                    } else {
                        stickerGrid(items: VOCAB.filter { $0.cat == selectedCat })
                            .padding(.top, 4)
                    }

                    // Quack Collectibles — below all stickers
                    if !appState.collectibles.isEmpty {
                        collectiblesSection
                    }

                    Spacer(minLength: 120)
                }
            }
            .background(Color.cream.ignoresSafeArea())
        }
        .fullScreenCover(item: $selectedSticker) { vocab in
            StickerCollectibleView(item: vocab)
        }
        .sheet(item: $selectedCollectible) { c in
            NavigationStack {
                ScrollView {
                    CollectibleCard(
                        result: .init(en: c.en, hanzi: c.hanzi, pinyin: c.pinyin,
                                      funFact: c.funFact, itemClass: c.itemClass),
                        image: c.image
                    )
                    .padding(20)
                }
                .background(Color.cream)
                .navigationTitle(c.en.capitalized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { selectedCollectible = nil }
                    }
                }
            }
        }
    }

    private var collectiblesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your Quack Collectibles")
                    .font(.display(16, weight: .heavy)).foregroundStyle(Color.ink)
                Spacer()
                Text("\(appState.collectibles.count)")
                    .font(.bodyText(12, weight: .heavy))
                    .foregroundStyle(Color.quackOrange)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.quackOrange.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(appState.collectibles.reversed()) { c in
                        Button { selectedCollectible = c } label: {
                            miniCollectibleTile(c)
                        }
                        .buttonStyle(TapPress())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 16)
    }

    private func miniCollectibleTile(_ c: SavedCollectible) -> some View {
        let rarity = c.rarity
        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(rarity.headerBg)
                    .frame(width: 80, height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(rarity.accentColor.opacity(0.5), lineWidth: 1.5))
                if let img = c.image {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(c.hanzi)
                        .font(.display(26, weight: .heavy))
                        .foregroundStyle(rarity.accentColor)
                }
                // Rarity corner dot
                Circle().fill(rarity.accentColor).frame(width: 8, height: 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(5)
            }
            Text(c.en.capitalized)
                .font(.bodyText(10, weight: .bold)).foregroundStyle(Color.ink)
                .lineLimit(1).frame(width: 80)
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: i < rarity.stars ? "star.fill" : "star")
                        .font(.system(size: 7)).foregroundStyle(i < rarity.stars ? rarity.accentColor : Color.inkFaint)
                }
            }
        }
    }

    private func stickerGrid(items: [VocabItem]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            ForEach(items) { v in
                let unlocked = appState.learned.contains(v.id)
                StickerTile(
                    item: v,
                    locked: !unlocked,
                    size: .md,
                    onTap: unlocked ? { selectedSticker = v } : nil
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Sticker Collectible (fullscreen)
struct StickerCollectibleView: View {
    let item: VocabItem
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        ZStack {
            item.tone.bg.opacity(0.35).ignoresSafeArea()
            Sparkles(count: 10, color: item.tone.fg, opacity: 0.4, animate: true)

            VStack(spacing: 0) {
                // Close
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.inkMuted)
                    }
                    .buttonStyle(TapPress())
                }
                .padding(.horizontal, 24).padding(.top, 16)

                Spacer()

                // Large interactive sticker
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(item.tone.bg)
                        .frame(width: 260, height: 260)

                    GrainOverlay()
                        .frame(width: 260, height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 32))

                    Text(item.emoji)
                        .font(.system(size: 28))
                        .opacity(0.4)
                        .rotationEffect(.degrees(14))
                        .frame(width: 260, height: 260, alignment: .topTrailing)
                        .padding(16)

                    Text(item.hanzi)
                        .font(.display(90, weight: .heavy))
                        .foregroundStyle(item.tone.fg)
                }
                .frame(width: 260, height: 260)
                .stickerEffect()
                .modifier(LoopingStickerMotionEffect())
                .cardShadow()
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.5).delay(0.1), value: appeared)

                Spacer().frame(height: 32)

                // Info card
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text(item.hanzi)
                            .font(.display(44, weight: .heavy))
                            .foregroundStyle(Color.ink)
                        Text(item.pinyin)
                            .font(.bodyText(18, weight: .bold))
                            .foregroundStyle(Color.inkMuted)
                        Text(item.en.capitalized)
                            .font(.bodyText(15, weight: .bold))
                            .foregroundStyle(Color.ink)
                    }

                    // Hear it button
                    Button {
                        SpeechSpeaker.shared.speak(item.hanzi)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Hear it")
                                .font(.bodyText(14, weight: .heavy))
                        }
                        .foregroundStyle(Color.paper)
                        .padding(.horizontal, 28).padding(.vertical, 12)
                        .background(item.tone.fg)
                        .clipShape(Capsule())
                        .cardShadow()
                    }
                    .buttonStyle(TapPress())
                }
                .padding(24)
                .background(Color.paper)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .cardShadow()
                .padding(.horizontal, 24)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)

                Spacer()
            }
        }
        .onAppear { appeared = true }
        .onDisappear { SpeechSpeaker.shared.stop() }
    }
}

// MARK: - CategoryChip
private struct CategoryChip: View {
    let label: String
    let id: String
    @Binding var selectedCat: String
    private var isSelected: Bool { selectedCat == id }

    var body: some View {
        Button { selectedCat = id } label: {
            Text(label)
                .font(.bodyText(13, weight: .heavy))
                .foregroundStyle(isSelected ? Color.white : Color.inkMuted)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(isSelected ? Color.quackOrange : Color.inkFaint)
                .clipShape(Capsule())
        }
        .buttonStyle(TapPress())
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}

#Preview {
    @Previewable @State var tab = TabItem.library
    let state = AppState()
    state.learned = ["apple", "cat", "dog", "rice"]
    return LibraryView(activeTab: $tab)
        .environment(state)
}
