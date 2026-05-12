import SwiftUI

enum MascotState {
    case idle, speaking, celebrating, listening
}

struct Mascot: View {
    var state: MascotState = .idle
    var size: CGFloat = 160

    @State private var animating = false

    var body: some View {
        ZStack {
            // Listening rings
            if state == .listening {
                ForEach([0.0, 0.5, 1.0], id: \.self) { delay in
                    Circle()
                        .stroke(Color.quackOrange, lineWidth: 3)
                        .frame(width: size * 0.84, height: size * 0.84)
                        .scaleEffect(animating ? 2.2 : 0.8)
                        .opacity(animating ? 0 : 0.4)
                        .animation(
                            .easeOut(duration: 1.8)
                                .repeatForever(autoreverses: false)
                                .delay(delay),
                            value: animating
                        )
                }
            }

            // Celebrating sparkles
            if state == .celebrating {
                let glyphs = ["✦", "★", "✦", "+", "★"]
                let tops: [CGFloat]  = [0.10, 0.30, 0.60, 0.20, 0.70]
                let lefts: [CGFloat] = [-0.08, 1.00, -0.04, 1.08, 0.95]
                let sizes: [CGFloat] = [22, 16, 18, 14, 20]
                let colors: [Color]  = [.quackYellow, .quackOrange, .white, .quackYellow, .quackOrange]
                ForEach(glyphs.indices, id: \.self) { i in
                    Text(glyphs[i])
                        .font(.system(size: sizes[i], weight: .black))
                        .foregroundStyle(colors[i])
                        .offset(x: lefts[i] * size, y: tops[i] * size)
                        .rotationEffect(
                            .degrees(animating ? 360 : 0),
                            anchor: .center
                        )
                        .scaleEffect(animating ? 1.2 : 1.0)
                        .animation(
                            .easeOut(duration: 1.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: animating
                        )
                }
            }

            // Duck image
            Image("duck-mascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: .ink.opacity(0.18), radius: 16, x: 0, y: 8)
                .modifier(MascotAnimationModifier(state: state, animating: animating))
        }
        .frame(width: size, height: size)
        .onAppear { animating = true }
    }
}

private struct MascotAnimationModifier: ViewModifier {
    let state: MascotState
    let animating: Bool

    func body(content: Content) -> some View {
        switch state {
        case .idle:
            content
                .offset(y: animating ? -6 : 0)
                .rotationEffect(.degrees(animating ? 1 : -1), anchor: .bottom)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: animating
                )
        case .speaking:
            content
                .scaleEffect(animating ? CGSize(width: 1.02, height: 0.98) : CGSize(width: 0.99, height: 1.02))
                .offset(y: animating ? -2 : -1)
                .animation(
                    .easeInOut(duration: 0.35).repeatForever(autoreverses: true),
                    value: animating
                )
        case .celebrating:
            content
                .rotationEffect(.degrees(animating ? 8 : -8), anchor: .bottom)
                .offset(y: animating ? -22 : 0)
                .animation(
                    .spring(response: 0.7, dampingFraction: 0.45).repeatForever(autoreverses: true),
                    value: animating
                )
        case .listening:
            content
                .offset(y: animating ? -6 : 0)
                .animation(
                    .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                    value: animating
                )
        }
    }
}

#Preview("Mascot States") {
    HStack(spacing: 16) {
        VStack {
            Mascot(state: .idle, size: 100)
            Text("idle").font(.caption)
        }
        VStack {
            Mascot(state: .speaking, size: 100)
            Text("speak").font(.caption)
        }
        VStack {
            Mascot(state: .celebrating, size: 100)
            Text("celebrate").font(.caption)
        }
        VStack {
            Mascot(state: .listening, size: 100)
            Text("listen").font(.caption)
        }
    }
    .padding()
    .background(Color.cream)
}
