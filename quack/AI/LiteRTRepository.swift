//
//  LiteRTRepository.swift
//  Spiku
//
//  Created by Rifky Ari on 06/05/26.
//
//  Implements InferenceRepository using LiteRT-LM C++ API via Objective-C++ bridge.
//  Supports both blocking and streaming inference with token-by-token output.
//  Thread-safe via actor isolation for model operations.

import Foundation

/// Implements InferenceRepository using LiteRT-LM Conversation API.
/// Handles model inference with support for both blocking and streaming modes.
/// Multimodal support for audio + text input via JSON message format.
actor LiteRTRepository: InferenceRepository {
    private var bridge: LiteRTBridgeSwift?
    private var isInitialized = false
    
    func initialize(modelPath: String) async throws {
        let bridge = LiteRTBridgeSwift(modelPath: modelPath)
        
        guard bridge.isReady else {
            throw RepositoryError.initializationFailed("LiteRT-LM bridge failed to initialize")
        }
        
        self.bridge = bridge
        self.isInitialized = true
    }
    
    /// Performs blocking inference and returns complete output.
    /// Uses LiteRT-LM SendMessage API for full response.
    func infer(
        text: String,
        sourceLanguage: SupportedLanguage,
        targetLanguage: SupportedLanguage
    ) async throws -> InferenceResult {
        guard let bridge = bridge, isInitialized else {
            throw RepositoryError.notInitialized
        }
        
        let startTime = Date()
        
        guard let output = bridge.infer(withPrompt: text) else {
            throw RepositoryError.inferenceFailed("No output from model")
        }
        
        let latency = Date().timeIntervalSince(startTime)
        
        // Parse output according to PROJECT.md specification:
        // "first output the transcription in {SOURCE_LANGUAGE}, then one newline,
        // then output the string '{TARGET_LANGUAGE}: ', then the translation"
        let components = output.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        
        let transcribedText = String(components.first ?? "")
        var translatedText = ""
        
        if components.count > 1 {
            let secondPart = String(components[1])
            // Look for pattern: "TargetLanguage: translation"
            if let range = secondPart.range(of: ": ") {
                translatedText = String(secondPart[range.upperBound...])
            } else {
                translatedText = secondPart
            }
        }
        
        return InferenceResult(
            transcribedText: transcribedText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            inferenceTime: Date(),
            inferenceLatency: latency
        )
    }
    
    /// Performs streaming inference with token-by-token output.
    /// Uses LiteRT-LM SendMessageAsync API for real-time streaming.
    /// Useful for displaying output as it's generated.
    func inferStreaming(
        text: String,
        sourceLanguage: SupportedLanguage,
        targetLanguage: SupportedLanguage,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping (Result<InferenceResult, Error>) -> Void
    ) async throws {
        guard let bridge = bridge, isInitialized else {
            throw RepositoryError.notInitialized
        }
        
        let startTime = Date()
        var accumulatedOutput = ""
        
        // Create completion handler for streaming tokens
        let completion: ObjCTokenCallback = { token, isComplete in
            if let token = token {
                let tokenStr = token as String
                if !tokenStr.isEmpty {
                    accumulatedOutput.append(tokenStr)
                    onToken(tokenStr)
                }
            }
            
            if isComplete {
                // Parse complete output
                let latency = Date().timeIntervalSince(startTime)
                let components = accumulatedOutput.split(
                    separator: "\n",
                    maxSplits: 1,
                    omittingEmptySubsequences: false
                )
                
                let transcribedText = String(components.first ?? "")
                var translatedText = ""
                
                if components.count > 1 {
                    let secondPart = String(components[1])
                    if let range = secondPart.range(of: ": ") {
                        translatedText = String(secondPart[range.upperBound...])
                    } else {
                        translatedText = secondPart
                    }
                }
                
                let result = InferenceResult(
                    transcribedText: transcribedText,
                    translatedText: translatedText,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    inferenceTime: Date(),
                    inferenceLatency: latency
                )
                
                onComplete(.success(result))
            }
        }
        
        // Perform streaming inference
        let success = bridge.inferStreaming(withPrompt: text, completion: completion)
        
        if !success {
            onComplete(.failure(RepositoryError.inferenceFailed("Streaming inference failed")))
        }
    }
    
    /// Performs multimodal audio inference by writing PCM data as a WAV file
    /// and sending it through the LiteRT-LM Conversation API.
    func inferWithAudio(
        audioData: Data,
        sourceLanguage: SupportedLanguage,
        targetLanguage: SupportedLanguage
    ) async throws -> InferenceResult {
        guard let bridge = bridge, isInitialized else {
            throw RepositoryError.notInitialized
        }

        // Write PCM data as a WAV file to a temporary location
        let wavPath = try writeWAVFile(pcmData: audioData, sampleRate: 16000, channels: 1, bitsPerSample: 16)

        let startTime = Date()

        let textPrompt = """
        Transcribe this audio in \(sourceLanguage.displayName), then translate to \(targetLanguage.displayName).
        First output the transcription, then on a new line output "\(targetLanguage.displayName): " followed by the translation.
        """

        guard let output = bridge.infer(withAudioPath: wavPath, prompt: textPrompt) else {
            // Clean up temp file
            try? FileManager.default.removeItem(atPath: wavPath)
            throw RepositoryError.inferenceFailed("No output from audio inference")
        }

        // Clean up temp file
        try? FileManager.default.removeItem(atPath: wavPath)

        let latency = Date().timeIntervalSince(startTime)

        let components = output.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        let transcribedText = String(components.first ?? "")
        var translatedText = ""

        if components.count > 1 {
            let secondPart = String(components[1])
            if let range = secondPart.range(of: ": ") {
                translatedText = String(secondPart[range.upperBound...])
            } else {
                translatedText = secondPart
            }
        }

        return InferenceResult(
            transcribedText: transcribedText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            inferenceTime: Date(),
            inferenceLatency: latency
        )
    }

    /// Writes raw 16-bit PCM data as a WAV file and returns the file path.
    private func writeWAVFile(pcmData: Data, sampleRate: Int, channels: Int, bitsPerSample: Int) throws -> String {
        let tempDir = NSTemporaryDirectory()
        let fileName = "spiku_audio_\(UUID().uuidString).wav"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)

        let dataSize = UInt32(pcmData.count)
        let byteRate = UInt32(sampleRate * channels * bitsPerSample / 8)
        let blockAlign = UInt16(channels * bitsPerSample / 8)

        var header = Data()
        // RIFF header
        header.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        var chunkSize = UInt32(36 + dataSize).littleEndian
        header.append(Data(bytes: &chunkSize, count: 4))
        header.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"

        // fmt sub-chunk
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

        // data sub-chunk
        header.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        var dataSizeLE = dataSize.littleEndian
        header.append(Data(bytes: &dataSizeLE, count: 4))

        var wavData = header
        wavData.append(pcmData)

        try wavData.write(to: URL(fileURLWithPath: filePath))
        return filePath
    }

    deinit {
        bridge?.shutdown()
    }
}

// MARK: - Error Types

enum RepositoryError: LocalizedError {
    case initializationFailed(String)
    case notInitialized
    case inferenceFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            return "Initialization failed: \(reason)"
        case .notInitialized:
            return "Repository not initialized"
        case .inferenceFailed(let reason):
            return "Inference failed: \(reason)"
        }
    }
}
