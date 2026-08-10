import Foundation

/// One learnable unit at runtime — a `VocabItem` (static content) combined
/// with its current `ScheduleState` (hydrated from `VocabProgress` by
/// `LearningStore`). `gloss`/`exampleGloss` stay as full per-language
/// dictionaries — not resolved to a single String — so switching the UI
/// language re-renders instantly via `LocalizationStore.text(_:)` without
/// needing to rebuild the deck.
///
/// Every item lives on the same spaced-repetition schedule regardless of which
/// stage (input / retrieval / output) it was last seen in.
struct LearningItem: Identifiable, Equatable {
    let id: String
    /// The target-language form the learner must eventually *produce*.
    let target: String
    /// Language code -> translated gloss, used as a retrieval cue.
    let gloss: [String: String]
    /// The item shown in context — comprehensible-input style (i+1).
    let exampleTarget: String
    let exampleGloss: [String: String]
    /// Corpus frequency rank (lower = more frequent). Drives curriculum order.
    let frequencyRank: Int

    // MARK: Spaced-repetition memory state (see FSRSScheduler)
    var schedule: ScheduleState = .init()

    /// A learner "actively knows" an item once its memory *stability* reaches
    /// three weeks — i.e. it would take ~21 days to decay to 90% recall. This
    /// is a real-acquisition signal grounded in the DSR model, not a vanity
    /// counter.
    var isMastered: Bool { schedule.stability >= 21 }
}

/// The four self-graded outcomes of a retrieval attempt (Anki-style).
/// Kept deliberately small — the research found elaborate schemes add little.
enum RecallGrade: Int, CaseIterable, Identifiable {
    case again = 0   // failed to recall
    case hard  = 1   // recalled with difficulty
    case good  = 2   // recalled correctly
    case easy  = 3   // effortless

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .again: return "Again"
        case .hard:  return "Hard"
        case .good:  return "Good"
        case .easy:  return "Easy"
        }
    }

    /// Only Good/Easy count as a successful first-attempt recall for accuracy.
    var isSuccess: Bool { self == .good || self == .easy }
}
