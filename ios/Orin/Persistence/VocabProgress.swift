import Foundation
import SwiftData

/// Persisted per-word FSRS memory state, keyed by `VocabItem.id` (a plain
/// string join, NOT a SwiftData relationship — static content lives in
/// `ContentStore`, never in the database).
///
/// A row is created lazily, the first time a word enters the review queue —
/// with thousands of words in the catalog, pre-creating a row per word at
/// first launch would mean thousands of near-empty writes for content the
/// learner hasn't seen yet.
@Model
final class VocabProgress {
    @Attribute(.unique) var itemId: String
    var stability: Double
    var difficulty: Double
    var reps: Int
    var lapses: Int
    var lastInterval: Double
    var dueInDays: Double

    init(itemId: String, schedule: ScheduleState = ScheduleState()) {
        self.itemId = itemId
        stability = schedule.stability
        difficulty = schedule.difficulty
        reps = schedule.reps
        lapses = schedule.lapses
        lastInterval = schedule.lastInterval
        dueInDays = schedule.dueInDays
    }

    var schedule: ScheduleState {
        get {
            ScheduleState(
                stability: stability, difficulty: difficulty, reps: reps,
                lapses: lapses, lastInterval: lastInterval, dueInDays: dueInDays
            )
        }
        set {
            stability = newValue.stability
            difficulty = newValue.difficulty
            reps = newValue.reps
            lapses = newValue.lapses
            lastInterval = newValue.lastInterval
            dueInDays = newValue.dueInDays
        }
    }
}
