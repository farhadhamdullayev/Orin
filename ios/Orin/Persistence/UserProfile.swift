import Foundation
import SwiftData

/// Singleton row holding the learner's own persisted state — points, streak,
/// the virtual-day counter, language/goal preferences. Fetched-or-created
/// once at launch (see `LearningStore.init`); never more than one row exists.
@Model
final class UserProfile {
    var displayName: String
    var deviceId: UUID
    var points: Int
    var streak: Int
    var virtualDay: Int
    var uiLanguage: String
    var learningGoal: String
    var milestonesSeen: [String]
    var pointsAtDayStart: Int
    var streakAtDayStart: Int

    init(
        displayName: String = "",
        deviceId: UUID = UUID(),
        points: Int = 0,
        streak: Int = 0,
        virtualDay: Int = 0,
        uiLanguage: String = "az",
        learningGoal: String = "",
        milestonesSeen: [String] = [],
        pointsAtDayStart: Int = 0,
        streakAtDayStart: Int = 0
    ) {
        self.displayName = displayName
        self.deviceId = deviceId
        self.points = points
        self.streak = streak
        self.virtualDay = virtualDay
        self.uiLanguage = uiLanguage
        self.learningGoal = learningGoal
        self.milestonesSeen = milestonesSeen
        self.pointsAtDayStart = pointsAtDayStart
        self.streakAtDayStart = streakAtDayStart
    }
}
