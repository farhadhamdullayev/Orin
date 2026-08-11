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
    private(set) var grammar: [GrammarTopic]
    private(set) var listening: [ListeningTopic]
    private(set) var visualVocab: [VisualCategory]

    init() {
        vocab = ContentStore.loadJSON("vocab", as: [VocabItem].self) ?? []
        grammar = ContentStore.loadGrammar()
        listening = ContentStore.loadListening()
        visualVocab = ContentStore.loadVisualVocab()
    }

    /// Decodes `<name>.json` from the bundle, checking the `Content`
    /// subdirectory first (folder-reference add) and falling back to the
    /// bundle root (group add) — see README's Xcode setup step for context.
    static func loadJSON<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Content")
            ?? Bundle.main.url(forResource: name, withExtension: "json") else {
            assertionFailure("\(name).json not found in the app bundle — add Resources/Content/\(name).json to the Xcode target.")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            assertionFailure("Failed to decode \(name).json: \(error)")
            return nil
        }
    }
}
