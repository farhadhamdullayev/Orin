import Foundation
import AVFoundation

/// Text-to-speech for the Input stage. Dual-coding (audio + visual text) is a
/// core part of the loop, and audio-first exposure mirrors Pimsleur/shadowing.
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String, rate: Float = AVSpeechUtteranceDefaultSpeechRate * 0.9) {
        // SpeechRecognizer (Output/shadowing stage) switches the shared
        // AVAudioSession to `.record` while listening and never restores it —
        // `.record` has no playback route, so TTS goes silently mute afterward.
        // Force a playback-compatible category before every utterance so this
        // works regardless of what the recognizer left the session in.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true, options: [])

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }
}
