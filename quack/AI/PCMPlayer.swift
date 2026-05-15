import AVFoundation
import Foundation

/// Plays back raw 16-bit mono 16 kHz PCM (the same format MicRecorder
/// captures) so users can hear what their attempt actually sounded like.
@MainActor
final class PCMPlayer {
    private var player: AVAudioPlayer?

    /// Plays the given PCM data. Stops any in-flight playback first.
    func play(pcm: Data, sampleRate: Int = 16000, channels: Int = 1, bitsPerSample: Int = 16) throws {
        stop()
        // MicRecorder owns audio-session category (playAndRecord). Don't
        // override it here — that would break the next recording.
        let wav = Self.makeWAV(pcm: pcm, sampleRate: sampleRate, channels: channels, bitsPerSample: bitsPerSample)
        let p = try AVAudioPlayer(data: wav)
        p.prepareToPlay()
        p.play()
        player = p
    }

    func stop() {
        player?.stop()
        player = nil
    }

    /// Wraps raw PCM in a minimal RIFF/WAV header so AVAudioPlayer can read it.
    private static func makeWAV(pcm: Data, sampleRate: Int, channels: Int, bitsPerSample: Int) -> Data {
        let dataSize = UInt32(pcm.count)
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
        var audioFormat = UInt16(1).littleEndian
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

        var out = header
        out.append(pcm)
        return out
    }
}
