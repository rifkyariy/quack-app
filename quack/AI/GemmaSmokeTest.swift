import Foundation

/// One-shot diagnostic: locates the bundled .litertlm model, loads it via
/// LiteRT-LM, and runs a trivial text inference. Logs the outcome and never
/// throws — used to confirm the AI port is wired correctly end-to-end.
enum GemmaSmokeTest {
    static func run() async {
        guard let modelPath = Bundle.main.path(
            forResource: "gemma-4-E2B-it",
            ofType: "litertlm"
        ) else {
            print("[GemmaSmokeTest] FAIL: gemma-4-E2B-it.litertlm not found in bundle")
            return
        }
        print("[GemmaSmokeTest] Model path: \(modelPath)")

        let repo = LiteRTRepository()
        do {
            let initStart = Date()
            try await repo.initialize(modelPath: modelPath)
            print("[GemmaSmokeTest] Model loaded in \(String(format: "%.2f", Date().timeIntervalSince(initStart)))s")

            let result = try await repo.infer(
                text: "Reply with the single word: hello.",
                sourceLanguage: .english,
                targetLanguage: .english
            )
            let transcript = result.transcribedText.isEmpty
                ? "(empty)"
                : result.transcribedText
            print("[GemmaSmokeTest] OK — latency \(String(format: "%.2f", result.inferenceLatency))s, output: \(transcript)")
        } catch {
            print("[GemmaSmokeTest] FAIL: \(error.localizedDescription)")
        }
    }
}
