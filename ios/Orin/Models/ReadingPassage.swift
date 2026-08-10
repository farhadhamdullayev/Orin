import Foundation

/// A short graded reader used for the comprehensible-input (reading) step.
/// In a real build these come from a leveled corpus tagged by frequency band;
/// here a few hand-written passages of increasing lexical difficulty let the
/// CoverageEngine actually choose a level for the learner.
struct ReadingPassage: Identifiable, Equatable {
    let id: UUID
    let title: String
    /// Highest frequency band the passage draws on (1 = first 1,000 families,
    /// 2 = second 1,000, 3 = third 1,000). Higher = harder.
    let band: Int
    let text: String

    init(id: UUID = UUID(), title: String, band: Int, text: String) {
        self.id = id
        self.title = title
        self.band = band
        self.text = text
    }
}

enum PassageLibrary {
    /// Ordered easiest → hardest. Vocabulary load rises with `band`.
    static func all() -> [ReadingPassage] {
        [
            ReadingPassage(
                title: "A normal morning",
                band: 1,
                text: """
                I get up early. I make coffee and I look out the window. \
                The street is quiet because it is still very early. \
                I like this time of the day.
                """
            ),
            ReadingPassage(
                title: "Missing the bus",
                band: 2,
                text: """
                I wanted to catch the early bus, but I left the house late. \
                As soon as I reached the stop, the bus was already leaving. \
                I decided to walk, although it was a long way.
                """
            ),
            ReadingPassage(
                title: "Fixing the plan",
                band: 3,
                text: """
                We could not figure out why the schedule kept changing. \
                Although everyone arrived on time, the meeting was delayed again. \
                Eventually we agreed to keep the arrangement simple and flexible.
                """
            ),
            ReadingPassage(
                title: "An unexpected delay",
                band: 3,
                text: """
                The negotiations stalled because neither side would compromise. \
                Despite considerable pressure, the committee postponed its decision, \
                acknowledging that the underlying disagreements remained unresolved.
                """
            )
        ]
    }
}
