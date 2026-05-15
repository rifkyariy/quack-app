//
//  InferenceResult.swift
//  Spiku
//
//  Created by Rifky Ari on 06/05/26.
//

import Foundation

/// Result of speech-to-speech translation via LiteRT inference.
struct InferenceResult {
    /// Transcribed text in the source language.
    let transcribedText: String
    
    /// Translated text in the target language.
    let translatedText: String
    
    /// Source language of the transcription.
    let sourceLanguage: SupportedLanguage
    
    /// Target language of the translation.
    let targetLanguage: SupportedLanguage
    
    /// Timestamp when inference was completed.
    let inferenceTime: Date
    
    /// Latency of inference in seconds.
    let inferenceLatency: TimeInterval
    
    init(
        transcribedText: String,
        translatedText: String,
        sourceLanguage: SupportedLanguage,
        targetLanguage: SupportedLanguage,
        inferenceTime: Date = Date(),
        inferenceLatency: TimeInterval = 0
    ) {
        self.transcribedText = transcribedText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.inferenceTime = inferenceTime
        self.inferenceLatency = inferenceLatency
    }
}
