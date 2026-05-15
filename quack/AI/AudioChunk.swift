//
//  AudioChunk.swift
//  Spiku
//
//  Created by Rifky Ari on 06/05/26.
//

import Foundation

/// Represents a discrete audio segment bounded by silence (VAD-detected).
struct AudioChunk {
    /// Raw PCM audio data (16-bit signed little-endian).
    let audioData: Data
    
    /// Duration of the audio chunk in seconds.
    let duration: TimeInterval
    
    /// Sample rate in Hz. Expected: 16000 Hz.
    let sampleRate: Int
    
    /// Number of channels. Expected: 1 (Mono).
    let channelCount: Int
    
    /// Timestamp when this chunk was captured.
    let captureTime: Date
    
    init(
        audioData: Data,
        duration: TimeInterval,
        sampleRate: Int = 16000,
        channelCount: Int = 1,
        captureTime: Date = Date()
    ) {
        self.audioData = audioData
        self.duration = duration
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.captureTime = captureTime
    }
    
    /// Total number of samples in this chunk.
    var sampleCount: Int {
        audioData.count / 2 // 16-bit PCM = 2 bytes per sample
    }
}
