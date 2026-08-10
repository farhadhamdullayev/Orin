import Foundation
import Observation

/// Static vocabulary content — decoded once from the bundled `vocab.json`
/// (produced by `Orin/tools/export_ios_content.py` from the web app's own
/// CONTENT + LP.<lang>.vocab data). Never persisted; the dynamic per-user
/// review state lives separately in `VocabProgress` (SwiftData).
struct VocabItem: Identifiable, Codable, Equatable {
    let id: String
    let target: String
    let frequencyRank: Int
    let exampleTarget: String
    /// Language code ("az","hi","zh","es","pt","id","ar","vi","ko") → translated gloss.
    let gloss: [String: String]
    let exampleGloss: [String: String]
}

/// Loads and holds the full static content catalog in memory. One instance
/// lives for the app's lifetime; content never changes at runtime.
@Observable
final class ContentStore {
    private(set) var vocab: [VocabItem]

    init() {
        vocab = Self.loadVocab()
    }

    private static func loadVocab() -> [VocabItem] {
        guard let url = Bundle.main.url(forResource: "vocab", withExtension: "json", subdirectory: "Content")
            ?? Bundle.main.url(forResource: "vocab", withExtension: "json") else {
            assertionFailure("vocab.json not found in the app bundle — add Resources/Content/vocab.json to the Xcode target.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([VocabItem].self, from: data)
        } catch {
            assertionFailure("Failed to decode vocab.json: \(error)")
            return []
        }
    }
}
