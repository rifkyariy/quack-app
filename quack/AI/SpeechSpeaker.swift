import AVFoundation
import Foundation

/// Speaks Mandarin (zh-CN) text via the system speech synthesizer.
/// Used by missions to play a "this is what it should sound like" reference.
@MainActor
final class SpeechSpeaker {
    static let shared = SpeechSpeaker()

    private let synthesizer = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "zh-CN")

    private init() {}

    /// Cancels any in-flight utterance and speaks the given text in Mandarin.
    func speak(_ text: String, rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        activatePlaybackSessionIfNeeded()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    /// Ensures the audio session can actually play speech. When a recording
    /// flow owns the session, MicRecorder has set `.playAndRecord` (with
    /// `.defaultToSpeaker`) — that is already audible and ignores the
    /// Ring/Silent switch, so leave it untouched to avoid breaking recording.
    /// Otherwise — e.g. the Camera Mission, which never records — the session
    /// is still the default `.soloAmbient`, which the Ring/Silent switch
    /// mutes. Switch to `.playback` so the duck's pronunciation is audible
    /// even when the device is on silent.
    private func activatePlaybackSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        guard session.category != .playAndRecord, session.category != .record else {
            return
        }
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }

    /// Stops any in-flight utterance immediately.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
