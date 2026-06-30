import SwiftUI
import UIKit

/// Hooks into UIKit's per-window orientation query. SwiftUI has no native
/// per-screen orientation lock, so this is the standard escape hatch.
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Self.orientationLock
    }
}

enum OrientationLock {
    /// Updates the allowed orientation mask and, when locking to portrait,
    /// forces an immediate rotation back if currently in landscape.
    @MainActor static func set(_ mask: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = mask
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
    }

    @MainActor private static var keyWindowSafeAreaInsets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first(where: \.isKeyWindow) }
            .first?.safeAreaInsets ?? .zero
    }

    /// In landscape, the notch / Dynamic Island side carries a *larger* safe-area
    /// inset (~50-60pt, to clear the pill/cutout) than the home-indicator side
    /// (~21pt, just the swipe-up strip). So the smaller of the two leading/trailing
    /// insets is the home-indicator side — that's where a sidebar should sit.
    /// (On non-notched devices, e.g. iPhone SE, both are 0 and the choice is moot.)
    @MainActor static var homeIndicatorOnTrailing: Bool {
        let insets = keyWindowSafeAreaInsets
        return insets.right <= insets.left
    }

    /// The opposite edge from `homeIndicatorOnTrailing` — where the notch /
    /// Dynamic Island physically sits in the current landscape orientation.
    @MainActor static var dynamicIslandOnTrailing: Bool {
        !homeIndicatorOnTrailing
    }
}
