import SwiftUI

struct CompleteView: View {
    let earned: VocabItem
    let onDone: () -> Void

    @Environment(AppState.self) private var appState
    @State private var starAppeared = [false, false, false]

    var body: some View {
        ZStack {
            Color.mint.ignoresSafeArea()
            Confetti(count: 30)
            Sparkles(count: 8, animate: true)

            VStack(spacing: 0) {
                Spacer()

                Mascot(state: .celebrating, size: 170)

                Eyebrow(text: "Mission complete", color: .mintDeep)
                    .padding(.top, 16)

                Text("Nice one, \(appState.name)!")
                    .font(.display(28, weight: .heavy))
                    .foregroundStyle(Color.ink)
                    .padding(.top, 8)

                // Stars
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.quackYellow)
                            .frame(width: 52, height: 52)
                            .overlay(
                                QuackIcon(name: .star, size: 28, color: .white)
                            )
                            .cardShadow()
                            .scaleEffect(starAppeared[i] ? 1 : 0.05)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.45)
                                    .delay(0.3 + Double(i) * 0.15),
                                value: starAppeared[i]
                            )
                    }
                }
                .padding(.top, 24)

                // Sticker reveal
                StickerTile(item: earned, size: .lg, justEarned: true)
                    .frame(width: 140)
                    .padding(.top, 28)

                Spacer()

                CTAButton(label: "Back home", variant: .ink, action: onDone)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
            .scrollableWhenCompact()
        }
        .onAppear {
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.15) {
                    starAppeared[i] = true
                }
            }
        }
    }
}

#Preview {
    CompleteView(earned: VOCAB[0], onDone: {})
        .environment(AppState())
}
