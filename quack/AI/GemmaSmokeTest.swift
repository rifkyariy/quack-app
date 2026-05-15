import Foundation

/// Logs a one-shot trivial text inference against the shared Gemma model.
/// Useful as a launch-time sanity check; never affects user-facing flow.
enum GemmaSmokeTest {
    static func run() async {
        do {
            try await QuackGemma.shared.ensureReady()
            print("[GemmaSmokeTest] Model ready")
        } catch {
            print("[GemmaSmokeTest] FAIL preload: \(error.localizedDescription)")
        }
    }
}
