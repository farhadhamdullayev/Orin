import Foundation
import AVFoundation

/// Text-to-speech for the Input stage. Dual-coding (audio + visual text) is a
/// core part of the loop, and audio-first exposure mirrors Pimsleur/shadowing.
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String, rate: Float = AVSpeechUtteranceDefaultSpeechRate * 0.9) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }
}
