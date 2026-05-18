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
            forResource: "gemma-4-E2B-it",
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
        /// Blended 0–100 score: syllable similarity, modulated by tone.
        let score: Int
        /// The pinyin syllables the model heard (toneless letters, for display).
        let heard: String
        /// Whether the spoken syllables basically match the target word.
        let syllableOK: Bool
        /// Whether every tone in the target was pronounced correctly.
        let toneOK: Bool
        /// An encouraging hint shown when the word was right but a tone was off.
        let toneHint: String
    }

    /// Returns a blended pronunciation score plus the pinyin transcription
    /// for the spoken audio against the target Mandarin vocab item. Uses
    /// transcription-then-compare for reliability — Gemma transcribes what
    /// it heard (syllables and tone), Swift computes similarity.
    func scorePronunciation(audio: Data, target: VocabItem) async throws -> PronunciationResult {
        let engine = try await engine()
        // A fresh conversation gives this scoring a clean context, with no
        // turn history leaking in from a prior mission. A system message
        // anchors the task — framing the speaker as a beginner stops the
        // model from rejecting imperfect pronunciation — and greedy
        // sampling (topK 1) keeps the transcription deterministic so the
        // same recording always scores the same.
        let config = ConversationConfig(
            systemMessage: Message(
                """
                You transcribe a single spoken Mandarin Chinese word into \
                Hanyu Pinyin with a tone number after each syllable. The \
                speaker is a young child learning Mandarin, so their \
                pronunciation is often imperfect — always write your best \
                guess at both the syllables and the tone you heard, rather \
                than refusing.
                """,
                role: .system
            ),
            samplerConfig: try? SamplerConfig(topK: 1, topP: 1.0, temperature: 1.0)
        )
        let conversation = try await engine.createConversation(with: config)
        let wavPath = try Self.writeWAVFile(pcmData: audio)
        defer { try? FileManager.default.removeItem(atPath: wavPath) }
        // Do NOT include the target word — small models will regurgitate the
        // reference instead of transcribing what they heard. Ask for numbered
        // pinyin so we can grade the tone. Reserve "none" for genuine silence;
        // a learner's imperfect attempt should still be transcribed.
        let prompt = """
        Write the Mandarin word in this audio as Hanyu Pinyin with a tone \
        number right after each syllable: 1 high, 2 rising, 3 dipping, \
        4 falling, 5 neutral. Lowercase letters only, no spaces, no tone \
        marks, no other text. Examples: mao1, mi3fan4, ping2guo3.
        Only if the audio is completely silent with no speech at all, \
        reply with exactly: none
        """
        let response = try await conversation.sendMessage(
            Message(of: .audioFile(wavPath), .text(prompt))
        )
        let heard = response.toString.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = Self.evaluatePronunciation(heard: heard, target: target.pinyin)
        print("[QuackGemma] scorePronunciation target=\(target.pinyin) raw='\(heard)' "
            + "score=\(result.score) syllableOK=\(result.syllableOK) toneOK=\(result.toneOK)")
        return result
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

    /// Generates a 3-line mini story — one line per vocab item — using Gemma's
    /// text modality. Each line teaches one word. Throws if the model does not
    /// return three usable lines, so the caller can fall back to a template.
    func generateStory(items: [VocabItem]) async throws -> [String] {
        guard items.count >= 3 else { throw GemmaError.storyGenerationFailed }
        let engine = try await engine()
        // A fresh conversation; no greedy sampler — a story wants some variety.
        let conversation = try await engine.createConversation(
            with: ConversationConfig(
                systemMessage: Message(
                    """
                    You are Q, a cheerful secret-agent duck who helps young \
                    children learn Mandarin. You write tiny, simple, happy \
                    stories a five-year-old can follow.
                    """,
                    role: .system
                )
            )
        )
        let w = items
        let prompt = """
        Write a 3-line mini story for a young child learning Mandarin. Output \
        exactly 3 lines — one short, cheerful sentence per line — and nothing else.
        Line 1 teaches "\(w[0].en)": Chinese \(w[0].hanzi), pinyin \(w[0].pinyin).
        Line 2 teaches "\(w[1].en)": Chinese \(w[1].hanzi), pinyin \(w[1].pinyin).
        Line 3 teaches "\(w[2].en)": Chinese \(w[2].hanzi), pinyin \(w[2].pinyin).
        Each sentence must name the English word, show the Chinese characters, \
        and give the pinyin, and mention Q the duck. No line numbers, no extra text.
        """
        let response = try await conversation.sendMessage(Message(prompt))
        let lines = response.toString
            .split(whereSeparator: \.isNewline)
            .map { Self.cleanStoryLine(String($0)) }
            .filter { !$0.isEmpty }
        guard lines.count >= 3 else { throw GemmaError.storyGenerationFailed }
        print("[QuackGemma] generateStory produced \(lines.count) lines")
        return Array(lines.prefix(3))
    }

    /// Strips leading list markers ("1.", "-", "*") and surrounding whitespace
    /// from a generated story line.
    private static func cleanStoryLine(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespaces)
        while let first = s.first, "-*•".contains(first) {
            s = String(s.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        // Drop a leading "1." / "1)" enumerator.
        if let mark = s.firstIndex(where: { $0 == "." || $0 == ")" }),
           s.distance(from: s.startIndex, to: mark) <= 2,
           s[s.startIndex..<mark].allSatisfy(\.isNumber),
           mark != s.startIndex {
            s = String(s[s.index(after: mark)...]).trimmingCharacters(in: .whitespaces)
        }
        return s
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

    /// Grades a heard pinyin transcription against the target. The score is
    /// "blended & encouraging": syllable similarity carries the bulk of it
    /// and tone correctness modulates the top third — so the right word with
    /// a wrong tone still earns ~65%, and getting both right earns 100%.
    static func evaluatePronunciation(heard rawHeard: String, target rawTarget: String) -> PronunciationResult {
        let heardLetters = normalize(rawHeard)
        let targetLetters = normalize(rawTarget)
        // Genuine non-attempt (silence, or the model bailed with "none").
        if heardLetters.isEmpty || rawHeard.lowercased().contains("none") {
            return PronunciationResult(
                score: 0, heard: heardLetters.isEmpty ? "—" : heardLetters,
                syllableOK: false, toneOK: false, toneHint: ""
            )
        }

        // Syllable similarity (toneless letters), with a strict curve so
        // anything below ~0.4 similarity is treated as a different word.
        let syllable01: Double
        if heardLetters == targetLetters {
            syllable01 = 1.0
        } else {
            let distance = levenshtein(heardLetters, targetLetters)
            let maxLen = max(targetLetters.count, heardLetters.count)
            let similarity = maxLen > 0 ? 1.0 - Double(distance) / Double(maxLen) : 0
            syllable01 = max(0.0, min(1.0, (similarity - 0.2) / 0.8))
        }
        let syllableOK = syllable01 >= 0.8

        // Tone match over each of the target's tone positions.
        let targetTones = tones(in: rawTarget)
        let heardTones = tones(in: rawHeard)
        var toneSim = 1.0
        var toneOK = true
        if !targetTones.isEmpty {
            var matches = 0
            for (i, tone) in targetTones.enumerated() where i < heardTones.count && heardTones[i] == tone {
                matches += 1
            }
            toneSim = Double(matches) / Double(targetTones.count)
            toneOK = matches == targetTones.count
        }

        // Syllable dominates; tone modulates the top 35%.
        let blended = syllable01 * (0.65 + 0.35 * toneSim)
        let score = Int(round(blended * 100))

        // Encourage when they nailed the word but missed a tone.
        var toneHint = ""
        if syllableOK && !toneOK {
            if targetTones.count == 1 {
                toneHint = "Right word — try the \(toneName(targetTones[0])) tone!"
            } else {
                toneHint = "Right word — keep practising the tones!"
            }
        }
        return PronunciationResult(
            score: score, heard: heardLetters,
            syllableOK: syllableOK, toneOK: toneOK, toneHint: toneHint
        )
    }

    /// The tone numbers (1–5), in order, of a pinyin string. Handles numbered
    /// pinyin ("mi3fan4" → [3,4]) and tone-marked pinyin ("mǐfàn" → [3,4]).
    private static func tones(in pinyin: String) -> [Int] {
        let digits = pinyin.compactMap { $0.wholeNumberValue }.filter { (1...5).contains($0) }
        if !digits.isEmpty { return digits }
        return pinyin.lowercased().compactMap { toneMarks[$0] }
    }

    /// Tone number for each tone-marked vowel.
    private static let toneMarks: [Character: Int] = [
        "ā": 1, "ē": 1, "ī": 1, "ō": 1, "ū": 1, "ǖ": 1,
        "á": 2, "é": 2, "í": 2, "ó": 2, "ú": 2, "ǘ": 2,
        "ǎ": 3, "ě": 3, "ǐ": 3, "ǒ": 3, "ǔ": 3, "ǚ": 3,
        "à": 4, "è": 4, "ì": 4, "ò": 4, "ù": 4, "ǜ": 4,
    ]

    /// A kid-friendly name for a Mandarin tone.
    private static func toneName(_ tone: Int) -> String {
        switch tone {
        case 1: return "flat"
        case 2: return "rising"
        case 3: return "dipping"
        case 4: return "falling"
        default: return "soft"
        }
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
        case storyGenerationFailed
        var errorDescription: String? {
            switch self {
            case .modelMissing:
                return "Gemma model file is missing from the app bundle."
            case .storyGenerationFailed:
                return "Could not generate a story."
            }
        }
    }
}
