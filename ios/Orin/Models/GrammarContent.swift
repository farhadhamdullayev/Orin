import Foundation

/// Static grammar content — decoded from `grammar.json` (produced by
/// `Orin/tools/export_ios_content.py` from the web app's GRAMMAR array).
/// `title`/`icon`/`level` are language-neutral display text (e.g. "am / is /
/// are"); `note`/`examples[].gloss`/`drills[].gloss` are Azerbaijani-only —
/// the web app has no translated grammar packs for the other 8 languages yet
/// (see the export script's module docstring), so this struct has no
/// per-language dict, unlike `VocabItem`.
struct GrammarTopic: Identifiable, Codable, Equatable {
    let id: String
    let icon: String
    let title: String
    let level: String
    let note: String
    let examples: [GrammarExample]
    let drills: [GrammarDrill]
}

struct GrammarExample: Codable, Equatable {
    let english: String
    let gloss: String
}

struct GrammarDrill: Identifiable, Codable, Equatable {
    let id: String
    let question: String
    let options: [String]
    let correctIndex: Int
    let gloss: String
}

extension ContentStore {
    static func loadGrammar() -> [GrammarTopic] {
        ContentStore.loadJSON("grammar", as: [GrammarTopic].self) ?? []
    }
}
