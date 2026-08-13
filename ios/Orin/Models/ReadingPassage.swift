import Foundation

/// A graded reader passage — decoded from `reading.json` (the web app's
/// PASSAGES array, 1200 entries). English-only; no translation needed to
/// read comprehensible-input text. The web's `band` field is unused at its
/// own runtime (only the dynamic `CoverageEngine.coverage()` computation
/// matters) and is dropped here too — see `tools/export_ios_content.py`.
struct ReadingPassage: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let text: String
    let wordCount: Int
}

extension ContentStore {
    static func loadReading() -> [ReadingPassage] {
        ContentStore.loadJSON("reading", as: [ReadingPassage].self) ?? []
    }
}
