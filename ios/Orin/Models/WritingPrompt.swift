import Foundation

/// A writing-practice prompt — decoded from `writing_prompts.json` (the web
/// app's WRITING_PROMPTS array). `prompt`/`kind` are Azerbaijani-only, same
/// reasoning as Grammar/Listening (no translated packs for this content type
/// exist yet). `minWords` drives the rule-based feedback in `WritingView`.
struct WritingPrompt: Identifiable, Codable, Equatable {
    let id: String
    let level: String
    let kind: String
    let prompt: String
    let minWords: Int
}

extension ContentStore {
    static func loadWritingPrompts() -> [WritingPrompt] {
        ContentStore.loadJSON("writing_prompts", as: [WritingPrompt].self) ?? []
    }
}
