import Foundation

extension ContentStore {
    /// A supplementary word→Azerbaijani-translation glossary covering every
    /// unique word that appears across the 1200 reading passages but isn't
    /// already in the curated 3871-word vocab catalog — generated once via
    /// `Orin/tools/build_reading_glossary.py`. `ReadingView` merges this with
    /// the vocab catalog so tapping ANY word in a passage always resolves to
    /// a translation (per explicit requirement — no "not found" gaps).
    static func loadReadingGlossary() -> [String: String] {
        ContentStore.loadJSON("reading_glossary", as: [String: String].self) ?? [:]
    }
}
