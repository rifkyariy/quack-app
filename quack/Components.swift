import SwiftUI

// MARK: - Eyebrow
struct Eyebrow: View {
    let text: String
    var color: Color = .quackOrange
    var flank: Bool = true
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 8) {
            if flank { Text("✦").font(.display(size)) }
            Text(text)
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .tracking(size * 0.14)
                .textCase(.uppercase)
            if flank { Text("✦").font(.display(size)) }
        }
        .foregroundStyle(color)
    }
}

// MARK: - Sparkles
private let sparklePositions: [(top: CGFloat, left: CGFloat, size: CGFloat, rot: Double)] = [
    (0.08, 0.12, 14, 12),  (0.18, 0.78, 22, -18),
    (0.42, 0.06, 16, 30),  (0.60, 0.84, 12,   0),
    (0.74, 0.20, 18, 22),  (0.32, 0.50, 10,  -8),
    (0.88, 0.70, 14, -14), (0.50, 0.30, 12,  14),
]

struct Sparkles: View {
    var count: Int = 6
    var color: Color = .white
    var opacity: Double = 0.7
    var animate: Bool = false

    @State private var floating = false

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<min(count, sparklePositions.count), id: \.self) { i in
                let p = sparklePositions[i]
                Text("✦")
                    .font(.system(size: p.size, weight: .black))
                    .foregroundStyle(color.opacity(opacity))
                    .rotationEffect(.degrees(p.rot))
                    .offset(
                        x: p.left * geo.size.width,
                        y: (floating && animate ? p.top * geo.size.height - 6 : p.top * geo.size.height)
                    )
                    .animation(
                        animate
                            ? .easeInOut(duration: 2.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3)
                            : .default,
                        value: floating
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { floating = animate }
    }
}

// MARK: - Pill
struct Pill: View {
    let text: String
    var color: Color = .quackOrange
    var bg: Color = .white
    var pulseDot: Bool = false

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            if pulseDot {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .opacity(pulse ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }
            }
            Text(text)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(11 * 0.08)
                .textCase(.uppercase)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(bg)
        .clipShape(Capsule())
        .cardShadow()
    }
}

#Preview("Eyebrow") {
    VStack(spacing: 16) {
        Eyebrow(text: "Mission begins")
        Eyebrow(text: "Step 1 of 3", flank: false, size: 11)
        Pill(text: "Q is listening", pulseDot: true)
    }
    .padding()
    .background(Color.cream)
}
