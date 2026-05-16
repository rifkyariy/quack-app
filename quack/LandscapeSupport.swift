import SwiftUI

extension View {
    /// Wraps the view in a `ScrollView` only when vertical space is compact
    /// (iPhone landscape). In regular height the view is returned untouched so
    /// portrait layouts — including their `Spacer()`s — behave exactly as before.
    /// Use on portrait-composed screens so tall content scrolls instead of
    /// clipping or pushing the CTA off-screen in landscape.
    func scrollableWhenCompact() -> some View {
        modifier(ScrollableWhenCompact())
    }
}

private struct ScrollableWhenCompact: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    func body(content: Content) -> some View {
        if verticalSizeClass == .compact {
            ScrollView(showsIndicators: false) { content }
        } else {
            content
        }
    }
}
