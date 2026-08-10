import Foundation

/// Per-item memory state — the FSRS **DSR** model (Difficulty, Stability,
/// Retrievability), as confirmed in the research (open-spaced-repetition).
///
///   • Stability (S)  — days for recall probability to fall from 100% → 90%.
///   • Difficulty (D) — item complexity, bounded [1, 10].
///   • Retrievability (R) — current recall probability, decays along a
///     power-law forgetting curve R(t,S) = (1 + FACTOR·t/S)^DECAY.
///
/// This is a faithful *structure* of FSRS-4.5 using its published default
/// weights, deliberately NOT refit on data (a real build swaps in ts-fsrs /
/// py-fsrs, which ship fitted parameters and personalise them per user).
struct ScheduleState: Codable, Equatable {
    var stability: Double = 0      // S, in days
    var difficulty: Double = 0     // D, in [1, 10]
    var reps: Int = 0              // successful+failed reviews so far
    var lapses: Int = 0           // number of "Again" ratings
    /// Interval that was scheduled at the last review (days) — used for
    /// mastery display and to estimate elapsed time in this virtual-clock demo.
    var lastInterval: Double = 0
    /// Days from "now" until this item is next due (0 = due).
    var dueInDays: Double = 0

    var isNew: Bool { reps == 0 }
    var isDue: Bool { dueInDays <= 0 }
}

/// Pure, deterministic FSRS-4.5 scheduling logic (no Date dependency, so the
/// prototype can simulate days instantly).
enum FSRSScheduler {

    // MARK: Constants (FSRS-4.5)

    /// Default 17-weight parameter set shipped by FSRS-4.5.
    static let w: [Double] = [
        0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49,
        0.14, 0.94, 2.18, 0.05, 0.34, 1.26, 0.29, 2.61
    ]
    static let decay = -0.5
    static let factor = 19.0 / 81.0          // makes R(S, S) == 0.9
    /// Desired retention: the recall probability at which we re-show a card.
    /// FSRS commonly defaults near 0.90 (workload↔retention tradeoff). This
    /// exact value is a design knob, not an empirically fixed constant.
    static let desiredRetention = 0.90

    // MARK: Forgetting curve

    /// Power-law retrievability after `t` days at stability `S`.
    static func retrievability(elapsedDays t: Double, stability S: Double) -> Double {
        guard S > 0 else { return 0 }
        return pow(1 + factor * t / S, decay)
    }

    /// Interval (days) to next review: invert R(t,S)=desiredRetention.
    /// t = S/FACTOR · (r^(1/DECAY) − 1). At r=0.9 this yields t ≈ S.
    static func interval(forStability S: Double, retention r: Double = desiredRetention) -> Double {
        guard S > 0 else { return 1 }
        let t = S / factor * (pow(r, 1 / decay) - 1)
        return max(1, t.rounded())
    }

    // MARK: Initialisation (first review)

    static func initialStability(_ g: Int) -> Double { max(0.1, w[g - 1]) }

    static func initialDifficulty(_ g: Int) -> Double {
        clampDifficulty(w[4] - exp(w[5] * Double(g - 1)) + 1)
    }

    // MARK: Updates (subsequent reviews)

    static func nextDifficulty(_ D: Double, grade g: Int) -> Double {
        let delta = D - w[6] * Double(g - 3)                 // easier grade → lower D
        let reverted = w[7] * initialDifficulty(4) + (1 - w[7]) * delta  // mean reversion
        return clampDifficulty(reverted)
    }

    /// New stability after a successful recall (grade ≥ 2).
    static func stabilityOnSuccess(D: Double, S: Double, R: Double, grade g: Int) -> Double {
        let hardPenalty = g == 2 ? w[15] : 1
        let easyBonus   = g == 4 ? w[16] : 1
        let increase = exp(w[8]) * (11 - D) * pow(S, -w[9])
            * (exp(w[10] * (1 - R)) - 1) * hardPenalty * easyBonus
        return S * (1 + increase)
    }

    /// New (reduced) stability after a lapse (grade == 1).
    static func stabilityOnLapse(D: Double, S: Double, R: Double) -> Double {
        w[11] * pow(D, -w[12]) * (pow(S + 1, w[13]) - 1) * exp(w[14] * (1 - R))
    }

    static func clampDifficulty(_ d: Double) -> Double { min(10, max(1, d)) }

    // MARK: Entry point

    /// Apply a grade to a card's memory state and return the updated state.
    static func apply(_ grade: RecallGrade, to state: ScheduleState) -> ScheduleState {
        var s = state
        let g = grade.rawValue + 1                            // 0…3 → 1…4

        if s.isNew {
            s.stability = initialStability(g)
            s.difficulty = initialDifficulty(g)
        } else {
            let elapsed = s.lastInterval                      // assume reviewed when due
            let R = retrievability(elapsedDays: elapsed, stability: s.stability)
            s.difficulty = nextDifficulty(s.difficulty, grade: g)
            if g == 1 {
                s.stability = stabilityOnLapse(D: s.difficulty, S: s.stability, R: R)
            } else {
                s.stability = stabilityOnSuccess(D: s.difficulty, S: s.stability, R: R, grade: g)
            }
        }

        s.reps += 1
        if g == 1 {
            s.lapses += 1
            s.lastInterval = 0                                // resurface within session
            s.dueInDays = 0
        } else {
            let next = interval(forStability: s.stability)
            s.lastInterval = next
            s.dueInDays = next
        }
        return s
    }
}
