import SwiftUI

struct ObjectArt: View {
    let vocab: VocabItem
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle()
                .fill(vocab.tone.bg.opacity(0.22))
                .frame(width: size, height: size)
            Circle()
                .fill(vocab.tone.bg.opacity(0.14))
                .frame(width: size * 0.72, height: size * 0.72)
            Text(vocab.emoji)
                .font(.system(size: size * 0.48))
        }
        .frame(width: size, height: size)
    }
}

#Preview("ObjectArt") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
        ForEach(VOCAB.prefix(8)) { v in
            ObjectArt(vocab: v, size: 72)
        }
    }
    .padding()
    .background(Color.cream)
}
