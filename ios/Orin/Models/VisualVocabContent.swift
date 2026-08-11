import Foundation

/// Static visual-vocabulary content — decoded from `visual_vocab.json`
/// (the web app's PICSETS, which mixes plain category objects and a
/// `picCat(...)` JS helper — both shapes are normalized by the export
/// script into the same `VisualCategory`/`VisualVocabItem` records).
/// `gloss` is Azerbaijani-only, same reasoning as `GrammarTopic`.
///
/// A handful of items (the "body" category, originally rendered from an SVG
/// diagram on the web) have an empty `emoji` — the view falls back to the
/// category's own icon for those rather than requiring a ported SVG asset.
struct VisualCategory: Identifiable, Codable, Equatable {
    let id: String
    let icon: String
    let title: String
    let items: [VisualVocabItem]
}

struct VisualVocabItem: Identifiable, Codable, Equatable {
    let id: String
    let emoji: String
    let word: String
    let gloss: String
}

extension ContentStore {
    static func loadVisualVocab() -> [VisualCategory] {
        ContentStore.loadJSON("visual_vocab", as: [VisualCategory].self) ?? []
    }
}
