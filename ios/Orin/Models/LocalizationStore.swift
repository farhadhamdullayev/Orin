import Foundation
import Observation

/// Tracks the learner's chosen gloss language (the language they read
/// translations/instructions in — English is always the *target* being
/// learned, never a gloss language). Mirrors the web app's 9-language set
/// (`az` is the always-complete base; the other 8 fall back to `az` for any
/// word missing a translation, matching applyLangPack()'s runtime fallback).
@Observable
final class LocalizationStore {
    static let supportedVocabLanguages = ["az", "hi", "zh", "es", "pt", "id", "ar", "vi", "ko"]

    var currentLang: String

    init(initial: String? = nil) {
        if let initial, Self.supportedVocabLanguages.contains(initial) {
            currentLang = initial
        } else {
            let deviceLang = Locale.current.language.languageCode?.identifier ?? "az"
            currentLang = Self.supportedVocabLanguages.contains(deviceLang) ? deviceLang : "az"
        }
    }

    /// Resolve a translated-text dictionary (e.g. `VocabItem.gloss`) to the
    /// current language, falling back to Azerbaijani, then to `fallback`.
    func text(_ dict: [String: String], fallback: String = "") -> String {
        dict[currentLang] ?? dict["az"] ?? fallback
    }
}
