import SwiftUI

struct LibraryView: View {
    @Binding var activeTab: TabItem
    @Environment(AppState.self) private var appState

    @State private var selectedCat: String = "all"

    private var learnedCount: Int { appState.learned.count }

    private var filteredVocab: [VocabItem] {
        if selectedCat == "all" { return VOCAB }
        return VOCAB.filter { $0.cat == selectedCat }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Header
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
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .popShadow()

                    // MARK: Category chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(label: "All", id: "all", selectedCat: $selectedCat)
                            ForEach(CATEGORIES) { cat in
                                CategoryChip(label: cat.label, id: cat.id, selectedCat: $selectedCat)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }

                    // MARK: Sticker grid
                    if selectedCat == "all" {
                        ForEach(CATEGORIES) { cat in
                            let items = VOCAB.filter { $0.cat == cat.id }
                            if !items.isEmpty {
                                Text(cat.label)
                                    .font(.display(16, weight: .heavy))
                                    .foregroundStyle(Color.ink)
                                    .padding(.leading, 20)
                                    .padding(.top, 12)
                                    .padding(.bottom, 4)

                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ],
                                    spacing: 12
                                ) {
                                    ForEach(items) { v in
                                        StickerTile(
                                            item: v,
                                            locked: !appState.learned.contains(v.id),
                                            size: .md
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 12
                        ) {
                            ForEach(filteredVocab) { v in
                                StickerTile(
                                    item: v,
                                    locked: !appState.learned.contains(v.id),
                                    size: .md
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }

                    Spacer(minLength: 120)
                }
            }
            .background(Color.cream.ignoresSafeArea())

            TabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - CategoryChip
private struct CategoryChip: View {
    let label: String
    let id: String
    @Binding var selectedCat: String

    private var isSelected: Bool { selectedCat == id }

    var body: some View {
        Button {
            selectedCat = id
        } label: {
            Text(label)
                .font(.bodyText(13, weight: .heavy))
                .foregroundStyle(isSelected ? Color.white : Color.inkMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.quackOrange : Color.inkFaint)
                .clipShape(Capsule())
        }
        .buttonStyle(TapPress())
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var tab = TabItem.library
    let state = AppState()
    state.learned = ["apple", "cat", "dog", "rice"]
    return LibraryView(activeTab: $tab)
        .environment(state)
}
