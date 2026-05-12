import SwiftUI

extension Color {
    static let quOrange  = Color(red: 0.973, green: 0.416, blue: 0.220)  // #F86A38
    static let quYellow  = Color(red: 1.000, green: 0.824, blue: 0.247)  // #FFD23F
    static let quNavy    = Color(red: 0.078, green: 0.129, blue: 0.239)  // #14213D
    static let quRed     = Color(red: 0.898, green: 0.306, blue: 0.106)  // #E54E1B
    static let quGreen   = Color(red: 0.282, green: 0.780, blue: 0.455)  // #48C774
    static let quBlue    = Color(red: 0.310, green: 0.580, blue: 1.000)  // #4F94FF
    static let quPurple  = Color(red: 0.624, green: 0.353, blue: 0.992)  // #9F5AFA
    static let quCream   = Color(red: 1.000, green: 0.965, blue: 0.902)  // #FFF6E6
}

// Neo-brutalist "cave card" style: thick border + hard block shadow
extension View {
    func caveBox(
        fill: Color = .white,
        radius: CGFloat = 20,
        border: CGFloat = 3,
        sx: CGFloat = 5,
        sy: CGFloat = 5
    ) -> some View {
        self
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color.quNavy, lineWidth: border))
            .shadow(color: Color.quNavy, radius: 0, x: sx, y: sy)
    }
}

// Button style: card sinks into its own shadow on press
struct CavePress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(x: configuration.isPressed ? 4 : 0, y: configuration.isPressed ? 4 : 0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}
