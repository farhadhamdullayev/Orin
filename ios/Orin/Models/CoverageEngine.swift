import Foundation

/// Operationalises the strategy's comprehensible-input findings (§1.4-A):
/// text difficulty is estimated as *lexical coverage* — the share of a text's
/// running words the learner already knows.
///
///   ~95% coverage → supported comprehension (minimal)
///   ~98% coverage → independent comprehension (adequate; Hu & Nation 2000)
///
/// The engine picks, from a graded library, the passage whose coverage sits in
/// the learner's productive "sweet spot" — challenging but comprehensible (i+1
/// in spirit, without pretending to Krashen's exact, unfalsifiable mechanism).
enum CoverageEngine {

    /// Comprehension bands used across the UI.
    enum Band {
        case tooHard          // < 95% — frustration zone
        case supported        // 95–98% — comprehensible with effort (ideal for learning)
        case independent      // ≥ 98% — easy, good for fluency / confidence

        var label: String {
            switch self {
            case .tooHard:     return "Çətin"
            case .supported:   return "Öyrənmə zonası"
            case .independent: return "Müstəqil"
            }
        }
    }

    static func band(forCoverage c: Double) -> Band {
        switch c {
        case ..<0.95:  return .tooHard
        case ..<0.98:  return .supported
        default:       return .independent
        }
    }

    /// Split text into comparable word tokens (lowercased, punctuation stripped).
    static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    /// Fraction of running words (tokens) covered by the known-word set.
    /// This is *token* coverage (per the research), not type coverage.
    static func coverage(of text: String, known: Set<String>) -> Double {
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return 1 }
        let hits = tokens.filter { known.contains($0) }.count
        return Double(hits) / Double(tokens.count)
    }

    /// Distinct unknown word types in the text, preserving first-seen order —
    /// these are the natural candidates to teach next.
    static func unknownWords(in text: String, known: Set<String>) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for token in tokenize(text) where !known.contains(token) && !seen.contains(token) {
            seen.insert(token)
            result.append(token)
        }
        return result
    }

    /// Choose the passage that best fits the learner: prefer the "supported"
    /// zone (95–98%), then the highest-coverage passage below it, then the
    /// easiest available. Returns nil for an empty library.
    static func selectPassage(from library: [ReadingPassage], known: Set<String>) -> ReadingPassage? {
        guard !library.isEmpty else { return nil }

        let scored = library.map { ($0, coverage(of: $0.text, known: known)) }

        // 1) Best fit inside the learning zone (closest to 0.965 midpoint).
        let inZone = scored.filter { $0.1 >= 0.95 && $0.1 < 0.98 }
        if let best = inZone.min(by: { abs($0.1 - 0.965) < abs($1.1 - 0.965) }) {
            return best.0
        }
        // 2) Nothing in-zone yet → the hardest passage the learner can still
        //    mostly follow (highest coverage under 0.95).
        let belowZone = scored.filter { $0.1 < 0.95 }
        if let closest = belowZone.max(by: { $0.1 < $1.1 }) {
            return closest.0
        }
        // 3) Everything is easy → give the lowest-coverage (most novel) one.
        return scored.min(by: { $0.1 < $1.1 })?.0
    }
}
