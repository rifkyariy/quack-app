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

// MARK: - CTAButton
enum CTAVariant { case ink, orange, ghost }

struct CTAButton: View {
    let label: String
    var variant: CTAVariant = .ink
    var disabled: Bool = false
    let action: () -> Void

    private var bg: Color {
        switch variant {
        case .ink:    return .ink
        case .orange: return .quackOrange
        case .ghost:  return .clear
        }
    }
    private var fg: Color {
        switch variant {
        case .ink, .orange: return .white
        case .ghost:        return .ink
        }
    }

    var body: some View {
        Button(action: disabled ? {} : action) {
            Text(label)
                .font(.bodyText(16, weight: .heavy))
                .foregroundStyle(fg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(bg)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(variant == .ghost ? Color.inkFaint : .clear, lineWidth: 2)
                )
                .cardShadow()
                .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(TapPress())
        .disabled(disabled)
    }
}

// MARK: - BackBtn
struct BackBtn: View {
    var dark: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(dark ? Color.ink : Color.white)
                .frame(width: 44, height: 44)
                .background(dark ? Color.white : Color.ink)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .cardShadow()
        }
        .buttonStyle(TapPress())
    }
}

#Preview("Buttons") {
    VStack(spacing: 12) {
        CTAButton(label: "Let's go", variant: .ink) {}
        CTAButton(label: "Start mission", variant: .orange) {}
        CTAButton(label: "Skip", variant: .ghost) {}
        CTAButton(label: "Disabled", disabled: true) {}
        HStack {
            BackBtn { }
            BackBtn(dark: true) { }
        }
    }
    .padding()
    .background(Color.cream)
}

// MARK: - ProgressBar
struct ProgressBar: View {
    var value: Double
    var max: Double
    var color: Color = .quackOrange
    var trackColor: Color = .inkFaint
    var height: CGFloat = 12

    private var pct: Double { Swift.max(0, Swift.min(1, value / max)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor).frame(height: height)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * pct, height: height)
                    .animation(.easeOut(duration: 0.4), value: pct)
            }
        }
        .frame(height: height)
    }
}

// MARK: - DailyRing
struct DailyRing: View {
    var value: Int
    var max: Int

    private var pct: Double { Double(value) / Double(Swift.max(1, max)) }
    private let r: CGFloat = 24
    private let strokeWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let startAngle = Angle.degrees(-90)

                var trackPath = Path()
                trackPath.addArc(center: center, radius: r,
                                 startAngle: .degrees(0), endAngle: .degrees(360),
                                 clockwise: false)
                ctx.stroke(trackPath,
                           with: .color(.inkFaint),
                           style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

                let endDegrees = -90 + 360 * pct
                var progressPath = Path()
                progressPath.addArc(center: center, radius: r,
                                    startAngle: startAngle,
                                    endAngle: .degrees(endDegrees),
                                    clockwise: false)
                ctx.stroke(progressPath,
                           with: .color(.quackOrange),
                           style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            }
            .frame(width: 64, height: 64)
            .animation(.easeOut(duration: 0.4), value: pct)

            Text("\(value)")
                .font(.display(20, weight: .heavy))
                .foregroundStyle(Color.ink)
        }
        .frame(width: 64, height: 64)
    }
}

#Preview("Progress") {
    VStack(spacing: 24) {
        ProgressBar(value: 0.6, max: 1.0, height: 12)
        ProgressBar(value: 2, max: 5, color: .cobalt, height: 8)
        DailyRing(value: 2, max: 3)
        DailyRing(value: 3, max: 3)
    }
    .padding()
    .background(Color.cream)
}
