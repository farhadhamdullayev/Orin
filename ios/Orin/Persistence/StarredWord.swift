import Foundation
import SwiftData

/// A word the learner explicitly starred while reading (tap-to-translate →
/// ⭐) to build a personal review list. Removed the same way it was added —
/// tapping the star again, either from the reading view or from the
/// practice list once the word feels learned.
@Model
final class StarredWord {
    @Attribute(.unique) var word: String
    var translation: String
    var dateAdded: Date

    init(word: String, translation: String, dateAdded: Date = Date()) {
        self.word = word
        self.translation = translation
        self.dateAdded = dateAdded
    }
}
