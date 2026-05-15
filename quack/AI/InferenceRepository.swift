//
//  InferenceRepository.swift
//  Spiku
//
//  Created by Rifky Ari on 06/05/26.
//
//  Protocol defining LiteRT-LM model inference requirements.
//  Implemented by the Data layer (LiteRTRepository).

import Foundation

/// Protocol defining LiteRT-LM model inference requirements.
/// Implemented by the Data layer (LiteRTRepository).
/// Supports both blocking and streaming inference via LiteRT-LM Conversation API.
protocol InferenceRepository: AnyObject {
    /// Initializes the repository with the model file path.
    /// The model is memory-mapped via LiteRT-LM (never loaded via Data(contentsOf:)).
    func initialize(modelPath: String) async throws
    
    /// Performs text-only inference (blocking).
    func infer(
        text: String,
        sourceLanguage: SupportedLanguage,
        targetLanguage: SupportedLanguage
    ) async throws -> InferenceResult

    /// Performs multimodal audio inference (blocking).
    /// Sends audio as a WAV file to the LiteRT-LM Conversation API.
    /// - Parameters:
    ///   - audioData: Raw 16-bit signed LE PCM data at 16kHz mono.
    ///   - sourceLanguage: Language of the audio.
    ///   - targetLanguage: Target language for translation.
    /// - Returns: InferenceResult containing transcribed and translated text.
    func inferWithAudio(
        audioData: Data,
        sourceLanguage: SupportedLanguage,
        targetLanguage: SupportedLanguage
    ) async throws -> InferenceResult
}
