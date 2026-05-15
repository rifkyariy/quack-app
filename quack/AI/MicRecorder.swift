import AVFoundation
import Foundation

/// Single-utterance microphone recorder targeting Gemma's audio input format:
/// 16-bit signed little-endian PCM, 16 kHz mono. Returns a contiguous Data
/// blob on stop — no streaming, no VAD.
@MainActor
final class MicRecorder {
    enum RecorderError: LocalizedError {
        case permissionDenied
        case converterUnavailable
        case engineStartFailed(String)
        case noData

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Microphone access was denied. Enable it in Settings to use Say it."
            case .converterUnavailable:
                return "Could not configure audio for the model."
            case .engineStartFailed(let detail):
                return "Audio engine failed to start: \(detail)"
            case .noData:
                return "No audio was captured."
            }
        }
    }

    // Recreated per recording. Reusing the engine across audio-session
    // category changes (e.g. after TTS/playback) can leave its inputNode in
    // a state where subsequent taps capture only silence.
    private var engine = AVAudioEngine()
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16000,
        channels: 1,
        interleaved: false
    )!
    private var buffer = Data()
    private var converter: AVAudioConverter?
    private(set) var isRecording = false

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func start() throws {
        guard !isRecording else { return }
        buffer.removeAll(keepingCapacity: true)

        let session = AVAudioSession.sharedInstance()
        // playAndRecord lets us record AND play back without category churn,
        // which previously caused the inputNode to capture silence after a
        // TTS or PCM playback call. defaultToSpeaker keeps playback audible.
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        // Fresh engine each recording avoids any stale internal state from
        // previous sessions or category switches.
        engine = AVAudioEngine()
        let input = engine.inputNode
        let hwFormat = input.outputFormat(forBus: 0)
        guard let converter = AVAudioConverter(from: hwFormat, to: targetFormat) else {
            throw RecorderError.converterUnavailable
        }
        self.converter = converter

        input.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { [weak self] buf, _ in
            guard let self else { return }
            Task { @MainActor in self.appendConverted(buf) }
        }

        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw RecorderError.engineStartFailed(error.localizedDescription)
        }
        isRecording = true
    }

    func stop() throws -> Data {
        guard isRecording else { return buffer }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        // Leave the session active and in playAndRecord so the immediately
        // following Hear-it / Hear-you button taps can play without churn.
        let captured = buffer
        print("[MicRecorder] captured \(captured.count) bytes (~\(String(format: "%.2f", Double(captured.count) / 32000.0))s)")
        guard !captured.isEmpty else { throw RecorderError.noData }
        return captured
    }

    private func appendConverted(_ source: AVAudioPCMBuffer) {
        guard let converter else { return }
        let ratio = targetFormat.sampleRate / source.format.sampleRate
        let outFrames = AVAudioFrameCount(Double(source.frameLength) * ratio)
        guard outFrames > 0,
              let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outFrames)
        else { return }

        var hasData = true
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if hasData {
                hasData = false
                status.pointee = .haveData
                return source
            }
            status.pointee = .noDataNow
            return nil
        }
        if error != nil { return }

        guard let channel = out.int16ChannelData?[0] else { return }
        let samples = UnsafeBufferPointer(start: channel, count: Int(out.frameLength))
        buffer.append(Data(buffer: samples))
    }
}
