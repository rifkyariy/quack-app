import Foundation
import Observation

/// Shared on-device Gemma 4 inference service for quack missions.
/// Lazily loads the bundled .litertlm model on first use and keeps it warm
/// for the lifetime of the app.
@MainActor
@Observable
final class QuackGemma {
    static let shared = QuackGemma()

    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    private(set) var state: LoadState = .idle

    private let repo = LiteRTRepository()
    private var loadTask: Task<Void, Error>?

    private init() {}

    /// Kicks off model loading without blocking. Safe to call multiple times.
    func preload() {
        guard loadTask == nil else { return }
        state = .loading
        let repo = self.repo
        loadTask = Task.detached(priority: .userInitiated) {
            guard let path = Bundle.main.path(
                forResource: "gemma-4-E2B-it",
                ofType: "litertlm"
            ) else {
                throw GemmaError.modelMissing
            }
            try await repo.initialize(modelPath: path)
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.loadTask?.value
                self.state = .ready
            } catch {
                self.state = .failed(error.localizedDescription)
            }
        }
    }

    /// Awaits the model becoming ready. Triggers a preload if none is in flight.
    func ensureReady() async throws {
        if loadTask == nil { preload() }
        try await loadTask?.value
    }

    // MARK: - Mission use cases

    struct PronunciationResult {
        let score: Int
        let heard: String
    }

    /// Returns a 0–100 pronunciation score plus the raw pinyin transcription
    /// for the spoken audio against the target Mandarin vocab item. Uses
    /// transcription-then-compare for reliability — Gemma transcribes what
    /// it heard, Swift computes similarity.
    func scorePronunciation(audio: Data, target: VocabItem) async throws -> PronunciationResult {
        try await ensureReady()
        // Do NOT include the target word — small models (Gemma E2B) will
        // regurgitate the reference instead of transcribing what they heard.
        let prompt = """
        Transcribe this audio as Mandarin pinyin. Lowercase letters only, \
        no tone marks, no spaces inside a single word, no punctuation, no \
        English translation.
        If the audio is silent, in English, or not Mandarin, respond with \
        exactly: none
        Respond on a single line with just the pinyin or the word "none".
        """
        let raw = try await repo.inferAudio(audioData: audio, prompt: prompt)
        let heard = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let score = Self.pronunciationScore(heard: heard, target: target.pinyin)
        print("[QuackGemma] scorePronunciation target=\(target.pinyin) raw='\(heard)' score=\(score)")
        return PronunciationResult(score: score, heard: heard)
    }

    /// Computes a 0–100 score from a heard pinyin transcription against the
    /// target pinyin. Returns 0 when the model signaled "none".
    static func pronunciationScore(heard rawHeard: String, target rawTarget: String) -> Int {
        let heard = normalize(rawHeard)
        let target = normalize(rawTarget)
        if heard.isEmpty || heard == "none" || heard.contains("none") {
            return 0
        }
        if heard == target { return 100 }
        let distance = levenshtein(heard, target)
        let maxLen = max(target.count, heard.count)
        guard maxLen > 0 else { return 0 }
        let similarity = 1.0 - Double(distance) / Double(maxLen)
        // Map 0..1 similarity to 0..100, but be strict: anything below
        // ~0.4 similarity is functionally a different word.
        let scaled = max(0.0, min(1.0, (similarity - 0.2) / 0.8))
        return Int(round(scaled * 100))
    }

    private static func normalize(_ s: String) -> String {
        // Strip diacritics so tone marks fold (ē→e, ǐ→i), lowercase, then
        // keep only a–z so spaces, punctuation, and stray Unicode are
        // ignored. Without this, "yǐzi" vs Gemma's "yizi" would mismatch.
        let stripped = s.folding(options: .diacriticInsensitive, locale: .init(identifier: "en_US_POSIX"))
            .lowercased()
        return String(stripped.filter { ("a"..."z").contains($0) })
    }

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        if a == b { return 0 }
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        let aChars = Array(a)
        let bChars = Array(b)
        var prev = Array(0...bChars.count)
        var curr = Array(repeating: 0, count: bChars.count + 1)
        for i in 1...aChars.count {
            curr[0] = i
            for j in 1...bChars.count {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,
                    curr[j - 1] + 1,
                    prev[j - 1] + cost
                )
            }
            swap(&prev, &curr)
        }
        return prev[bChars.count]
    }

    enum GemmaError: LocalizedError {
        case modelMissing
        var errorDescription: String? {
            switch self {
            case .modelMissing:
                return "Gemma model file is missing from the app bundle."
            }
        }
    }
}
