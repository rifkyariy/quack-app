import Foundation
import Observation
import LiteRTLM

/// Shared on-device Gemma 4 inference service for quack missions.
/// Lazily loads the bundled .litertlm model on first use and keeps the
/// LiteRT-LM `Engine` warm for the lifetime of the app.
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

    /// The one-time engine load. Once resolved, `.value` returns the same
    /// initialized `Engine` to every caller — `Conversation`s are created
    /// fresh per mission, the engine itself is shared.
    private var loadTask: Task<Engine, Error>?

    private init() {}

    /// Kicks off model loading without blocking. Safe to call multiple times.
    func preload() {
        guard loadTask == nil else { return }
        state = .loading
        let task = Task.detached(priority: .userInitiated) {
            try await Self.makeEngine()
        }
        loadTask = task
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await task.value
                self.state = .ready
            } catch {
                self.state = .failed(error.localizedDescription)
            }
        }
    }

    /// Awaits the model becoming ready. Triggers a preload if none is in flight.
    func ensureReady() async throws {
        _ = try await engine()
    }

    /// Returns the initialized engine, starting a preload if needed.
    private func engine() async throws -> Engine {
        if loadTask == nil { preload() }
        guard let loadTask else { throw GemmaError.modelMissing }
        return try await loadTask.value
    }

    /// Builds and initializes the LiteRT-LM engine for the bundled model.
    /// Runs CPU backends across text, vision, and audio — the multimodal
    /// missions need all three.
    private static func makeEngine() async throws -> Engine {
        guard let modelPath = Bundle.main.path(
            forResource: "gemma-4-E4B-it",
            ofType: "litertlm"
        ) else {
            throw GemmaError.modelMissing
        }
        // The model lives in the read-only app bundle; LiteRT-LM needs a
        // writable directory for its cache files.
        let cacheDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first?.path
        let config = try EngineConfig(
            modelPath: modelPath,
            backend: .cpu(),
            visionBackend: .cpu(),
            audioBackend: .cpu(),
            cacheDir: cacheDir
        )
        let engine = Engine(engineConfig: config)
        try await engine.initialize()
        return engine
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
        let engine = try await engine()
        // A fresh conversation gives this scoring a clean context, with no
        // turn history leaking in from a prior mission.
        let conversation = try await engine.createConversation()
        let wavPath = try Self.writeWAVFile(pcmData: audio)
        defer { try? FileManager.default.removeItem(atPath: wavPath) }
        // Do NOT include the target word — small models will regurgitate the
        // reference instead of transcribing what they heard.
        let prompt = """
        Transcribe this audio as Mandarin pinyin. Lowercase letters only, \
        no tone marks, no spaces inside a single word, no punctuation, no \
        English translation.
        If the audio is silent, in English, or not Mandarin, respond with \
        exactly: none
        Respond on a single line with just the pinyin or the word "none".
        """
        let response = try await conversation.sendMessage(
            Message(of: .audioFile(wavPath), .text(prompt))
        )
        let heard = response.toString.trimmingCharacters(in: .whitespacesAndNewlines)
        let score = Self.pronunciationScore(heard: heard, target: target.pinyin)
        print("[QuackGemma] scorePronunciation target=\(target.pinyin) raw='\(heard)' score=\(score)")
        return PronunciationResult(score: score, heard: heard)
    }

    struct VisionResult {
        /// What Gemma said the photo contains (raw, trimmed).
        let recognized: String
        /// Whether `recognized` matches the target vocab word.
        let matched: Bool
    }

    /// Asks Gemma to name the main object in a photo, then checks that name
    /// against the target vocab item. Uses open-ended naming rather than a
    /// yes/no question — handing a small model the expected answer biases it
    /// toward agreement (same reason scorePronunciation hides the target).
    func recognizeObject(image: Data, target: VocabItem) async throws -> VisionResult {
        let engine = try await engine()
        // A fresh conversation gives this recognition a clean context.
        let conversation = try await engine.createConversation()
        let imagePath = try Self.writeTempImage(image)
        defer { try? FileManager.default.removeItem(atPath: imagePath) }
        let prompt = """
        Look at this photo. What is the main object in it? \
        Answer with just one or two words in English, all lowercase, no \
        punctuation, no description, no sentence.
        If you cannot tell, respond with exactly: none
        Respond on a single line.
        """
        let response = try await conversation.sendMessage(
            Message(of: .imageFile(imagePath), .text(prompt))
        )
        let recognized = response.toString.trimmingCharacters(in: .whitespacesAndNewlines)
        let matched = Self.objectMatches(recognized: recognized, target: target.en)
        print("[QuackGemma] recognizeObject target=\(target.en) raw='\(recognized)' matched=\(matched)")
        return VisionResult(recognized: recognized, matched: matched)
    }

    /// Decides whether Gemma's recognized object name matches the target
    /// English word. Compares word-by-word: normalize() drops spaces, so a
    /// substring test on the whole phrase would falsely match "egg" inside
    /// "eggplant" — splitting on whitespace first keeps word boundaries
    /// intact. Lenient within a word (tolerates "a cat", "grapes" for
    /// "grape"). Returns false when the model signaled it could not tell.
    static func objectMatches(recognized rawRecognized: String, target rawTarget: String) -> Bool {
        let target = normalize(rawTarget)
        guard !target.isEmpty else { return false }
        // Reject explicit uncertainty before tokenizing.
        let lowerRaw = rawRecognized.lowercased()
        if lowerRaw.contains("none") || lowerRaw.contains("unknown")
            || lowerRaw.contains("not sure") || lowerRaw.contains("unclear") {
            return false
        }
        let tokens = rawRecognized
            .split(whereSeparator: { $0.isWhitespace })
            .map { normalize(String($0)) }
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return false }
        for token in tokens {
            if token == target { return true }
            // Fuzzy match within a word tolerates plurals and near-miss
            // spellings ("grape"/"grapes"), but not unrelated compounds.
            let distance = levenshtein(token, target)
            let maxLen = max(token.count, target.count)
            if maxLen > 0, 1.0 - Double(distance) / Double(maxLen) >= 0.8 {
                return true
            }
        }
        return false
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

    // MARK: - Temp file helpers

    /// Writes raw 16-bit PCM as a WAV file in the temp directory and returns
    /// its path. LiteRT-LM expects audio as 16-bit signed LE PCM, 16 kHz mono
    /// — exactly what `MicRecorder` produces; this only adds the WAV framing.
    private static func writeWAVFile(
        pcmData: Data,
        sampleRate: Int = 16000,
        channels: Int = 1,
        bitsPerSample: Int = 16
    ) throws -> String {
        let tempDir = NSTemporaryDirectory()
        let fileName = "quack_audio_\(UUID().uuidString).wav"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)

        let dataSize = UInt32(pcmData.count)
        let byteRate = UInt32(sampleRate * channels * bitsPerSample / 8)
        let blockAlign = UInt16(channels * bitsPerSample / 8)

        var header = Data()
        header.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        var chunkSize = UInt32(36 + dataSize).littleEndian
        header.append(Data(bytes: &chunkSize, count: 4))
        header.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"

        header.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        var subchunk1Size = UInt32(16).littleEndian
        header.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat = UInt16(1).littleEndian // PCM
        header.append(Data(bytes: &audioFormat, count: 2))
        var numChannels = UInt16(channels).littleEndian
        header.append(Data(bytes: &numChannels, count: 2))
        var sampleRateLE = UInt32(sampleRate).littleEndian
        header.append(Data(bytes: &sampleRateLE, count: 4))
        var byteRateLE = byteRate.littleEndian
        header.append(Data(bytes: &byteRateLE, count: 4))
        var blockAlignLE = blockAlign.littleEndian
        header.append(Data(bytes: &blockAlignLE, count: 2))
        var bitsPerSampleLE = UInt16(bitsPerSample).littleEndian
        header.append(Data(bytes: &bitsPerSampleLE, count: 2))

        header.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        var dataSizeLE = dataSize.littleEndian
        header.append(Data(bytes: &dataSizeLE, count: 4))

        var wavData = header
        wavData.append(pcmData)
        try wavData.write(to: URL(fileURLWithPath: filePath))
        return filePath
    }

    /// Writes image bytes to a temp JPEG file and returns its path.
    private static func writeTempImage(_ imageData: Data) throws -> String {
        let tempDir = NSTemporaryDirectory()
        let fileName = "quack_image_\(UUID().uuidString).jpg"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)
        try imageData.write(to: URL(fileURLWithPath: filePath))
        return filePath
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
