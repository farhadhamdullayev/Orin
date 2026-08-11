import Foundation

/// Static listening-practice content — decoded from `listening.json`.
/// `english` is the text fed to `Speaker` (TTS); `gloss`/`question`/`options`/
/// `correctAnswer` are Azerbaijani-only for the same reason as `GrammarTopic`
/// (no translated `listen` packs exist yet for the other 8 languages).
struct ListeningTopic: Identifiable, Codable, Equatable {
    let id: String
    let icon: String
    let title: String
    let level: String
    let items: [ListeningItem]
}

struct ListeningItem: Identifiable, Codable, Equatable {
    let id: String
    let english: String
    let gloss: String
    let question: String
    let options: [String]
    let correctAnswer: String
}

extension ContentStore {
    static func loadListening() -> [ListeningTopic] {
        ContentStore.loadJSON("listening", as: [ListeningTopic].self) ?? []
    }
}
