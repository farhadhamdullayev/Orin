import Foundation
import Speech
import AVFoundation
import Observation

/// Thin wrapper over on-device speech recognition for the Output/shadowing stage.
///
/// Honesty note from the research: automated pronunciation scoring is still far
/// from human-level, so we surface a *transcript-match* signal framed as an
/// approximation — never a hard "your pronunciation = 87%" verdict.
@Observable
final class SpeechRecognizer {
    enum State: Equatable {
        case idle
        case listening
        case result(transcript: String)
        case unavailable(reason: String)
    }

    private(set) var state: State = .idle

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Ask for mic + recognition permission up front.
    func requestPermission() async -> Bool {
        let speechOK = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        let micOK = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
        }
        return speechOK && micOK
    }

    func start() {
        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable(reason: "Tanınma hazırda əlçatan deyil.")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
            self.request = request

            let input = audioEngine.inputNode
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
                request.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            state = .listening

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    self.state = .result(transcript: result.bestTranscription.formattedString)
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stop()
                }
            }
        } catch {
            state = .unavailable(reason: error.localizedDescription)
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }

    /// A crude, honest intelligibility proxy: word-overlap between target and
    /// heard text. Apple's on-device Speech framework does TRANSCRIPTION only —
    /// it has no native phoneme/pronunciation scoring (strategy §1.5). So this
    /// measures "were the words understood", NOT pronunciation quality. Real
    /// pronunciation scoring would need a cloud API (e.g. Azure), and even that
    /// correlates only moderately with human raters — hence "approximate".
    static func closeness(target: String, heard: String) -> Double {
        let norm: (String) -> [String] = { s in
            s.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        }
        let t = norm(target)
        let h = Set(norm(heard))
        guard !t.isEmpty else { return 0 }
        let hits = t.filter { h.contains($0) }.count
        return Double(hits) / Double(t.count)
    }
}
