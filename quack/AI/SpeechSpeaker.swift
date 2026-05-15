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
        // MicRecorder owns audio-session category (playAndRecord). Don't
        // override it here — that would break the next recording.
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    /// Stops any in-flight utterance immediately.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
