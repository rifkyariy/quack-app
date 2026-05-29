import SwiftUI
import Sticker

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

// MARK: - LogoType
struct LogoType: View {
    var body: some View {
        Image("duck-logotype")
            .resizable()
            .scaledToFit()
            .accessibilityLabel("Quack logo")
    }
}

#Preview("LogoType") {
    VStack(spacing: 32) {
        ZStack {
            Color.quackOrange.ignoresSafeArea()
            LogoType()
                .frame(maxWidth: 260)
        }
        .frame(height: 200)
        
        ZStack {
            Color.cream.ignoresSafeArea()
            LogoType()
                .frame(maxWidth: 200)
        }
        .frame(height: 150)
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

// MARK: - QuackIcon
enum QuackIconName {
    case home, mission, book, parent
    case back, close, mic, camera, speaker, star, fire
    case check, plus, chevron, lock, shield, photo, clock, heart, sound, play
}

struct QuackIcon: View {
    let name: QuackIconName
    var size: CGFloat = 24
    var color: Color = .primary
    var strokeWidth: CGFloat = 1.8

    var body: some View {
        Canvas { ctx, sz in
            let filled: [QuackIconName] = [.star, .fire, .heart, .speaker, .play]
            if filled.contains(name) {
                ctx.fill(iconPath(for: name, in: sz), with: .color(color))
            } else {
                ctx.stroke(iconPath(for: name, in: sz), with: .color(color),
                           style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
    }

    private func iconPath(for icon: QuackIconName, in sz: CGSize) -> Path {
        let s = sz.width / 24
        var p = Path()
        switch icon {
        case .home:
            p.move(to: CGPoint(x: 3*s, y: 11*s))
            p.addLine(to: CGPoint(x: 12*s, y: 3*s))
            p.addLine(to: CGPoint(x: 21*s, y: 11*s))
            p.move(to: CGPoint(x: 5*s, y: 10*s))
            p.addLine(to: CGPoint(x: 5*s, y: 20*s))
            p.addLine(to: CGPoint(x: 19*s, y: 20*s))
            p.addLine(to: CGPoint(x: 19*s, y: 10*s))
        case .mission:
            p.addEllipse(in: CGRect(x: 3*s, y: 3*s, width: 18*s, height: 18*s))
            p.addEllipse(in: CGRect(x: 8*s, y: 8*s, width: 8*s, height: 8*s))
        case .book:
            p.move(to: CGPoint(x: 4*s, y: 4*s))
            p.addLine(to: CGPoint(x: 11*s, y: 4*s))
            p.addCurve(to: CGPoint(x: 14*s, y: 7*s),
                       control1: CGPoint(x: 14*s, y: 4*s), control2: CGPoint(x: 14*s, y: 5.5*s))
            p.addLine(to: CGPoint(x: 14*s, y: 17*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 15*s),
                       control1: CGPoint(x: 14*s, y: 17*s), control2: CGPoint(x: 13*s, y: 15*s))
            p.addLine(to: CGPoint(x: 4*s, y: 15*s))
            p.closeSubpath()
            p.move(to: CGPoint(x: 20*s, y: 4*s))
            p.addLine(to: CGPoint(x: 13*s, y: 4*s))
            p.addCurve(to: CGPoint(x: 10*s, y: 7*s),
                       control1: CGPoint(x: 10*s, y: 4*s), control2: CGPoint(x: 10*s, y: 5.5*s))
            p.addLine(to: CGPoint(x: 10*s, y: 17*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 15*s),
                       control1: CGPoint(x: 10*s, y: 17*s), control2: CGPoint(x: 11*s, y: 15*s))
            p.addLine(to: CGPoint(x: 20*s, y: 15*s))
            p.closeSubpath()
        case .parent:
            p.addEllipse(in: CGRect(x: 8*s, y: 4*s, width: 8*s, height: 8*s))
            p.move(to: CGPoint(x: 4*s, y: 21*s))
            p.addCurve(to: CGPoint(x: 20*s, y: 21*s),
                       control1: CGPoint(x: 5*s, y: 17*s), control2: CGPoint(x: 19*s, y: 17*s))
        case .back:
            p.move(to: CGPoint(x: 15*s, y: 6*s))
            p.addLine(to: CGPoint(x: 9*s, y: 12*s))
            p.addLine(to: CGPoint(x: 15*s, y: 18*s))
        case .close:
            p.move(to: CGPoint(x: 6*s, y: 6*s))
            p.addLine(to: CGPoint(x: 18*s, y: 18*s))
            p.move(to: CGPoint(x: 6*s, y: 18*s))
            p.addLine(to: CGPoint(x: 18*s, y: 6*s))
        case .mic:
            p.addRoundedRect(in: CGRect(x: 9*s, y: 3*s, width: 6*s, height: 12*s),
                             cornerSize: CGSize(width: 3*s, height: 3*s))
            p.move(to: CGPoint(x: 5*s, y: 11*s))
            p.addCurve(to: CGPoint(x: 19*s, y: 11*s),
                       control1: CGPoint(x: 5*s, y: 18*s), control2: CGPoint(x: 19*s, y: 18*s))
            p.move(to: CGPoint(x: 12*s, y: 18*s))
            p.addLine(to: CGPoint(x: 12*s, y: 21*s))
        case .camera:
            p.move(to: CGPoint(x: 4*s, y: 7*s))
            p.addLine(to: CGPoint(x: 7*s, y: 7*s))
            p.addLine(to: CGPoint(x: 9*s, y: 4*s))
            p.addLine(to: CGPoint(x: 15*s, y: 4*s))
            p.addLine(to: CGPoint(x: 17*s, y: 7*s))
            p.addLine(to: CGPoint(x: 20*s, y: 7*s))
            p.addLine(to: CGPoint(x: 20*s, y: 19*s))
            p.addLine(to: CGPoint(x: 4*s, y: 19*s))
            p.closeSubpath()
            p.addEllipse(in: CGRect(x: 8*s, y: 9*s, width: 8*s, height: 8*s))
        case .speaker:
            p.move(to: CGPoint(x: 4*s, y: 9*s))
            p.addLine(to: CGPoint(x: 8*s, y: 9*s))
            p.addLine(to: CGPoint(x: 13*s, y: 5*s))
            p.addLine(to: CGPoint(x: 13*s, y: 19*s))
            p.addLine(to: CGPoint(x: 8*s, y: 15*s))
            p.addLine(to: CGPoint(x: 4*s, y: 15*s))
            p.closeSubpath()
            p.move(to: CGPoint(x: 16*s, y: 8*s))
            p.addCurve(to: CGPoint(x: 16*s, y: 16*s),
                       control1: CGPoint(x: 19*s, y: 9.5*s), control2: CGPoint(x: 19*s, y: 14.5*s))
        case .star:
            p.move(to: CGPoint(x: 12*s, y: 3*s))
            p.addLine(to: CGPoint(x: 14.6*s, y: 8.5*s))
            p.addLine(to: CGPoint(x: 20.7*s, y: 9.2*s))
            p.addLine(to: CGPoint(x: 16.2*s, y: 13.2*s))
            p.addLine(to: CGPoint(x: 17.4*s, y: 19.2*s))
            p.addLine(to: CGPoint(x: 12*s, y: 16.1*s))
            p.addLine(to: CGPoint(x: 6.6*s, y: 19.2*s))
            p.addLine(to: CGPoint(x: 7.8*s, y: 13.2*s))
            p.addLine(to: CGPoint(x: 3.3*s, y: 9.2*s))
            p.addLine(to: CGPoint(x: 9.4*s, y: 8.5*s))
            p.closeSubpath()
        case .fire:
            p.move(to: CGPoint(x: 12*s, y: 3*s))
            p.addCurve(to: CGPoint(x: 17*s, y: 13*s),
                       control1: CGPoint(x: 13*s, y: 7*s), control2: CGPoint(x: 17*s, y: 8*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 21*s),
                       control1: CGPoint(x: 21*s, y: 18*s), control2: CGPoint(x: 17*s, y: 21*s))
            p.addCurve(to: CGPoint(x: 7*s, y: 13*s),
                       control1: CGPoint(x: 7*s, y: 21*s), control2: CGPoint(x: 3*s, y: 18*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 3*s),
                       control1: CGPoint(x: 7*s, y: 8*s), control2: CGPoint(x: 11*s, y: 7*s))
        case .check:
            p.move(to: CGPoint(x: 5*s, y: 12*s))
            p.addLine(to: CGPoint(x: 9*s, y: 16*s))
            p.addLine(to: CGPoint(x: 19*s, y: 6*s))
        case .chevron:
            p.move(to: CGPoint(x: 9*s, y: 6*s))
            p.addLine(to: CGPoint(x: 15*s, y: 12*s))
            p.addLine(to: CGPoint(x: 9*s, y: 18*s))
        case .lock:
            p.addRoundedRect(in: CGRect(x: 5*s, y: 11*s, width: 14*s, height: 9*s),
                             cornerSize: CGSize(width: 2*s, height: 2*s))
            p.move(to: CGPoint(x: 8*s, y: 11*s))
            p.addLine(to: CGPoint(x: 8*s, y: 8*s))
            p.addCurve(to: CGPoint(x: 16*s, y: 8*s),
                       control1: CGPoint(x: 8*s, y: 4*s), control2: CGPoint(x: 16*s, y: 4*s))
            p.addLine(to: CGPoint(x: 16*s, y: 11*s))
        case .shield:
            p.move(to: CGPoint(x: 12*s, y: 3*s))
            p.addLine(to: CGPoint(x: 20*s, y: 6*s))
            p.addLine(to: CGPoint(x: 20*s, y: 12*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 21*s),
                       control1: CGPoint(x: 20*s, y: 17*s), control2: CGPoint(x: 16*s, y: 20*s))
            p.addCurve(to: CGPoint(x: 4*s, y: 12*s),
                       control1: CGPoint(x: 8*s, y: 20*s), control2: CGPoint(x: 4*s, y: 17*s))
            p.addLine(to: CGPoint(x: 4*s, y: 6*s))
            p.closeSubpath()
        case .photo:
            p.addRoundedRect(in: CGRect(x: 3*s, y: 5*s, width: 18*s, height: 14*s),
                             cornerSize: CGSize(width: 2*s, height: 2*s))
            p.addEllipse(in: CGRect(x: 7*s, y: 9*s, width: 4*s, height: 4*s))
            p.move(to: CGPoint(x: 3*s, y: 17*s))
            p.addLine(to: CGPoint(x: 9*s, y: 12*s))
            p.addLine(to: CGPoint(x: 14*s, y: 16*s))
            p.addLine(to: CGPoint(x: 17*s, y: 14*s))
            p.addLine(to: CGPoint(x: 21*s, y: 17*s))
        case .clock:
            p.addEllipse(in: CGRect(x: 3*s, y: 3*s, width: 18*s, height: 18*s))
            p.move(to: CGPoint(x: 12*s, y: 7*s))
            p.addLine(to: CGPoint(x: 12*s, y: 12*s))
            p.addLine(to: CGPoint(x: 15*s, y: 14*s))
        case .heart:
            p.move(to: CGPoint(x: 12*s, y: 20*s))
            p.addCurve(to: CGPoint(x: 5*s, y: 10*s),
                       control1: CGPoint(x: 12*s, y: 20*s), control2: CGPoint(x: 5*s, y: 16*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 6*s),
                       control1: CGPoint(x: 5*s, y: 6*s), control2: CGPoint(x: 8*s, y: 6*s))
            p.addCurve(to: CGPoint(x: 19*s, y: 10*s),
                       control1: CGPoint(x: 16*s, y: 6*s), control2: CGPoint(x: 19*s, y: 6*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 20*s),
                       control1: CGPoint(x: 19*s, y: 16*s), control2: CGPoint(x: 12*s, y: 20*s))
        case .sound:
            p.move(to: CGPoint(x: 4*s, y: 9*s))
            p.addLine(to: CGPoint(x: 8*s, y: 9*s))
            p.addLine(to: CGPoint(x: 13*s, y: 5*s))
            p.addLine(to: CGPoint(x: 13*s, y: 19*s))
            p.addLine(to: CGPoint(x: 8*s, y: 15*s))
            p.addLine(to: CGPoint(x: 4*s, y: 15*s))
            p.closeSubpath()
        case .plus:
            p.move(to: CGPoint(x: 12*s, y: 5*s))
            p.addLine(to: CGPoint(x: 12*s, y: 19*s))
            p.move(to: CGPoint(x: 5*s, y: 12*s))
            p.addLine(to: CGPoint(x: 19*s, y: 12*s))
        case .play:
            p.move(to: CGPoint(x: 7*s, y: 5*s))
            p.addLine(to: CGPoint(x: 18*s, y: 12*s))
            p.addLine(to: CGPoint(x: 7*s, y: 19*s))
            p.closeSubpath()
        }
        return p
    }
}

// MARK: - TabBar
enum TabItem: String, CaseIterable {
    case home, missions, library, parent

    var label: String {
        switch self {
        case .home:     return "Home"
        case .missions: return "Missions"
        case .library:  return "Stickers"
        case .parent:   return "Parent"
        }
    }
    var icon: QuackIconName {
        switch self {
        case .home:     return .home
        case .missions: return .mission
        case .library:  return .book
        case .parent:   return .parent
        }
    }
}

struct TabBar: View {
    @Binding var active: TabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                let on = active == tab
                Button { active = tab } label: {
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 999)
                            .fill(on ? Color.quackOrange : Color.clear)
                            .frame(width: 28, height: 4)

                        QuackIcon(name: tab.icon, size: 24,
                                  color: on ? .quackOrange : .inkMuted,
                                  strokeWidth: on ? 2.2 : 1.8)

                        Text(tab.label)
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(0.4)
                            .foregroundStyle(on ? Color.quackOrange : Color.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                }
                .buttonStyle(TapPress())
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(Color.paper)
        .shadow(color: .ink.opacity(0.08), radius: 8, x: 0, y: -4)
    }
}

private struct TabBarPreviewWrapper: View {
    @State var active: TabItem = .home
    var body: some View { TabBar(active: $active) }
}

#Preview("TabBar") {
    VStack {
        Spacer()
        TabBarPreviewWrapper()
    }
}

// MARK: - PulsingBorderEffect
struct PulsingBorderEffect: ViewModifier {
    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let progress = (t.truncatingRemainder(dividingBy: 1.5)) / 1.5
            let scale = 0.95 + (sin(progress * .pi * 2) + 1) / 2 * 0.1
            let opacity = 0.3 + (sin(progress * .pi * 2) + 1) / 2 * 0.3

            content
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: [4, 4]
                            )
                        )
                        .foregroundStyle(Color.quackOrange.opacity(opacity))
                        .scaleEffect(scale)
                )
        }
    }
}

// MARK: - LoopingStickerMotionEffect

struct LoopingStickerMotionEffect: ViewModifier {
    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            content
                .rotation3DEffect(.degrees(sin(t * 0.4) * 10), axis: (x: 0, y: 1, z: 0), perspective: 0.3)
                .rotation3DEffect(.degrees(cos(t * 0.28) * 7), axis: (x: 1, y: 0, z: 0), perspective: 0.3)
        }
    }
}

// MARK: - StickerTile
enum StickerSize { case sm, md, lg }

struct StickerTile: View {
    let item: VocabItem
    var locked: Bool = false
    var size: StickerSize = .md
    var justEarned: Bool = false
    var onTap: (() -> Void)? = nil

    private var dim: CGFloat {
        switch size { case .sm: 78; case .md: 110; case .lg: 140 }
    }
    private var hanziSize: CGFloat {
        switch size { case .sm: 28; case .md: 38; case .lg: 48 }
    }

    @State private var appeared = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(locked ? item.tone.bg : item.tone.bg)

                if !locked {
                    GrainOverlay()
                    Text(item.emoji)
                        .font(.system(size: 18))
                        .opacity(0.35)
                        .rotationEffect(.degrees(14))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(10)
                    Text("✦")
                        .font(.system(size: 14, weight: .black))
                        .opacity(0.35)
                        .rotationEffect(.degrees(-10))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(8)
                }

                ZStack {
                    // Faded hanzi in background (locked only)
                    if locked {
                        Text(item.hanzi)
                            .font(.display(hanziSize, weight: .heavy))
                            .foregroundStyle(item.tone.fg.opacity(0.2))
                    }

                    // Lock icon on top
                    VStack(spacing: 4) {
                        if locked {
                            QuackIcon(name: .lock, size: 28, color: .inkMuted, strokeWidth: 1.8)
                        } else {
                            Text(item.hanzi)
                                .font(.display(hanziSize, weight: .heavy))
                                .foregroundStyle(item.tone.fg)
                            Text(item.pinyin)
                                .font(.bodyText(10, weight: .bold))
                                .foregroundStyle(item.tone.fg.opacity(0.9))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .stickerEffect()
            .modifier(LoopingStickerMotionEffect())
            .modifier(locked ? AnyView(PulsingBorderEffect()) : AnyView(EmptyView()))
            .cardShadow()
            .scaleEffect(appeared ? 1 : 0.05)
            .opacity(appeared ? 1 : 0)
        }
        .buttonStyle(TapPress())
        .disabled(onTap == nil || locked)
        .onAppear {
            if justEarned {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.45).delay(0.2)) {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
    }
}

// MARK: - Confetti
private struct ConfettiPiece {
    let x: Double
    let delay: Double
    let duration: Double
    let rotation: Double
    let colorIndex: Int
    let shape: Int
}

private let confettiColors: [Color] = [.quackOrange, .quackYellow, .mint, .cobalt, .rose]

struct Confetti: View {
    var count: Int = 30

    private let pieces: [ConfettiPiece] = (0..<30).map { (i: Int) -> ConfettiPiece in
        let x = Double(i * 3337 % 100) / 100
        let delay = Double(i * 1234 % 800) / 1000
        let duration = 1.6 + Double(i * 567 % 1600) / 1000
        let rotation = Double(i * 137 % 360)
        return ConfettiPiece(
            x: x,
            delay: delay,
            duration: duration,
            rotation: rotation,
            colorIndex: i % 5,
            shape: i % 3
        )
    }

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let now = tl.date.timeIntervalSinceReferenceDate
                for piece in pieces.prefix(count) {
                    let elapsed = (now - piece.delay).truncatingRemainder(dividingBy: piece.duration + 0.5)
                    guard elapsed > 0 else { continue }
                    let progress = elapsed / (piece.duration + 0.5)
                    let py = -20 + progress * (size.height + 40)
                    let px = piece.x * size.width
                    let rot = Angle.degrees(piece.rotation + progress * 720)
                    let w: CGFloat = piece.shape == 0 ? 10 : 14
                    let h: CGFloat = piece.shape == 1 ? 16 : 10
                    let rect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
                    let path = piece.shape == 2 ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 2)
                    var copy = ctx
                    copy.translateBy(x: px, y: py)
                    copy.rotate(by: rot)
                    copy.fill(path, with: .color(confettiColors[piece.colorIndex].opacity(1 - progress * 0.5)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("StickerTile") {
    let apple = VOCAB[0]
    let fish  = VOCAB[7]
    VStack {
        HStack {
            StickerTile(item: apple, size: .sm)
            StickerTile(item: fish, size: .sm)
            StickerTile(item: apple, locked: true, size: .sm)
        }
        StickerTile(item: apple, size: .md)
        StickerTile(item: fish, size: .lg, justEarned: true)
    }
    .padding()
    .background(Color.cream)
}

// MARK: - WaveBar
struct WaveBar: View {
    let index: Int
    var animating: Bool = false
    var color: Color = .quackOrange

    private let heights: [CGFloat] = [22, 38, 54, 38, 22]

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: 6, height: animating ? heights[index % heights.count] : 10)
            .animation(
                .easeInOut(duration: 0.36 + Double(index) * 0.08)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.12),
                value: animating
            )
    }
}

#Preview("Confetti") {
    ZStack {
        Color.mint.ignoresSafeArea()
        Confetti(count: 30)
    }
}
