import SwiftUI

// MARK: - Color tokens
extension Color {
    static let quackOrange     = Color(hex: 0xF86A38)
    static let quackOrangeDeep = Color(hex: 0xE54E1B)
    static let quackOrangeSoft = Color(hex: 0xFFB7A0)
    static let quackYellow     = Color(hex: 0xFCC83C)
    static let cream           = Color(hex: 0xFFF1E1)
    static let creamDeep       = Color(hex: 0xFBE6CB)
    static let paper           = Color.white
    static let ink             = Color(hex: 0x14213D)
    static let inkSoft         = Color(hex: 0x2A3556)
    static let inkMuted        = Color(hex: 0x9098AE)
    static let inkFaint        = Color(hex: 0xD7DAE3)
    static let cobalt          = Color(hex: 0x4F5DDB)
    static let cobaltDeep      = Color(hex: 0x2F3CB8)
    static let mint            = Color(hex: 0x93D5B8)
    static let mintDeep        = Color(hex: 0x5FB594)
    static let rose            = Color(hex: 0xFF8FA3)
    static let lilac           = Color(hex: 0xC9C5F2)

    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255
        )
    }
}

// MARK: - Tone
enum Tone: String, CaseIterable {
    case orange, yellow, cobalt, mint, rose, lilac, cream

    var bg: Color {
        switch self {
        case .orange: return .quackOrange
        case .yellow: return .quackYellow
        case .cobalt: return .cobalt
        case .mint:   return .mint
        case .rose:   return .rose
        case .lilac:  return .lilac
        case .cream:  return .creamDeep
        }
    }

    var fg: Color {
        switch self {
        case .orange, .cobalt: return .white
        default: return .ink
        }
    }
}

// MARK: - Font helpers
extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func bodyText(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }
    static var eyebrow: Font { .system(size: 11, weight: .heavy, design: .rounded) }
}

// MARK: - Shadow helpers
extension View {
    func cardShadow() -> some View {
        self.shadow(color: .ink.opacity(0.08), radius: 6, x: 0, y: 2)
    }
    func popShadow() -> some View {
        self.shadow(color: .ink.opacity(0.16), radius: 12, x: 0, y: 4)
    }
}

// MARK: - QuackCard modifier
struct QuackCardModifier: ViewModifier {
    var fill: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .cardShadow()
    }
}

extension View {
    func quackCard(fill: Color = .paper, radius: CGFloat = 22) -> some View {
        modifier(QuackCardModifier(fill: fill, radius: radius))
    }
    func quackCard(tone: Tone, radius: CGFloat = 22) -> some View {
        modifier(QuackCardModifier(fill: tone.bg, radius: radius))
    }
}

// MARK: - GrainOverlay
struct GrainOverlay: View {
    var opacity: Double = 0.07

    var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / 4)
            let rows = Int(size.height / 4)
            for row in 0..<rows {
                for col in 0..<cols {
                    let hash = (UInt32(row) &* 2_654_435_761 &+ UInt32(col) &* 40_503) & 0xFF
                    if hash < 18 {
                        let x = CGFloat(col) * 4 + CGFloat(hash % 4)
                        let y = CGFloat(row) * 4 + CGFloat((hash / 4) % 4)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                            with: .color(.white.opacity(opacity))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func grain(opacity: Double = 0.07) -> some View {
        self.overlay(GrainOverlay(opacity: opacity))
    }
}

// MARK: - TapPress button style
struct TapPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Screen-in transition helper
extension AnyTransition {
    static var screenIn: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 8)),
            removal: .opacity
        )
    }
}
