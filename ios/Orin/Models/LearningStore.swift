import Foundation
import Observation
import SwiftData

/// The app's single source of truth: the item deck, the virtual clock, and the
/// real-acquisition metrics. One store = one unified memory schedule.
///
/// Static content (word/gloss/example text) comes from `ContentStore` and is
/// never persisted. Only the dynamic per-word `ScheduleState` and the
/// singleton `UserProfile` are written through to SwiftData, and only for
/// words the learner has actually reviewed (see `VocabProgress`).
@Observable
final class LearningStore {
    private(set) var items: [LearningItem]

    /// Virtual day counter. Advancing it is how the prototype "waits" for
    /// spaced intervals to come due without real calendar time — this mirrors
    /// the web app's own `state.virtualDay`/`advanceDay()` production design.
    private(set) var virtualDay: Int

    // MARK: Real-acquisition metrics (NOT streaks / XP)
    /// First-attempt recall successes over total first attempts, this session.
    private(set) var firstAttempts = 0
    private(set) var firstAttemptSuccesses = 0

    /// Vocabulary the learner starts out knowing (approx. the high-frequency
    /// function/content words). Coverage is measured against this plus every
    /// item word they've since recalled at least once.
    private let baseKnownWords: Set<String>

    private let modelContext: ModelContext
    private let userProfile: UserProfile
    private var progressByItemId: [String: VocabProgress]
    /// Kept for on-demand access to content that isn't hydrated into
    /// `items` (reading passages) or that's cheap to re-derive from here
    /// rather than duplicate (writing prompts).
    private let contentStore: ContentStore

    init(
        contentStore: ContentStore,
        localization: LocalizationStore,
        modelContext: ModelContext,
        baseKnownWords: Set<String> = SampleContent.baseKnownWords()
    ) {
        self.modelContext = modelContext
        self.baseKnownWords = baseKnownWords
        self.contentStore = contentStore

        var profileDescriptor = FetchDescriptor<UserProfile>()
        profileDescriptor.fetchLimit = 1
        if let existing = try? modelContext.fetch(profileDescriptor).first {
            userProfile = existing
        } else {
            let fresh = UserProfile(uiLanguage: localization.currentLang)
            modelContext.insert(fresh)
            userProfile = fresh
        }
        virtualDay = userProfile.virtualDay

        let progressRows = (try? modelContext.fetch(FetchDescriptor<VocabProgress>())) ?? []
        // Built as a local first (not `self.progressByItemId`) — referencing an
        // instance member from inside a closure below would implicitly capture
        // `self` before all stored properties are initialized, which Swift forbids.
        let progressLookup = Dictionary(uniqueKeysWithValues: progressRows.map { ($0.itemId, $0) })
        progressByItemId = progressLookup

        items = contentStore.vocab
            .sorted { $0.frequencyRank < $1.frequencyRank }
            .map { vocab in
                LearningItem(
                    id: vocab.id,
                    target: vocab.target,
                    gloss: vocab.gloss,
                    exampleTarget: vocab.exampleTarget,
                    exampleGloss: vocab.exampleGloss,
                    frequencyRank: vocab.frequencyRank,
                    awl: vocab.awl,
                    schedule: progressLookup[vocab.id]?.schedule ?? ScheduleState()
                )
            }

        try? modelContext.save()
    }

    // MARK: Profile-backed settings

    var uiLanguage: String { userProfile.uiLanguage }
    var learningGoal: String { userProfile.learningGoal }

    func setUILanguage(_ code: String) {
        userProfile.uiLanguage = code
        try? modelContext.save()
    }

    func setLearningGoal(_ text: String) {
        userProfile.learningGoal = text
        try? modelContext.save()
    }

    var examType: String { userProfile.examType }
    var examTarget: String { userProfile.examTarget }

    func setExamGoal(type: String, target: String) {
        userProfile.examType = type
        userProfile.examTarget = target
        try? modelContext.save()
    }

    var serverBaseURL: String { userProfile.serverBaseURL }
    var deviceId: String { userProfile.deviceId.uuidString }
    var displayName: String { userProfile.displayName }

    func setServerBaseURL(_ url: String) {
        userProfile.serverBaseURL = url
        try? modelContext.save()
    }

    func setDisplayName(_ name: String) {
        userProfile.displayName = name
        try? modelContext.save()
    }

    // MARK: Derived metrics

    var recallAccuracy: Double {
        firstAttempts == 0 ? 0 : Double(firstAttemptSuccesses) / Double(firstAttempts)
    }

    var masteredCount: Int { items.filter(\.isMastered).count }

    /// Items whose spaced interval has come due (or that are brand new).
    var dueItems: [LearningItem] {
        items.filter { $0.schedule.isDue }
    }

    var newItems: [LearningItem] {
        items.filter { $0.schedule.isNew }
    }

    /// Due/new items restricted to the Academic Word List, for the
    /// dedicated AWL practice track.
    var awlDueItems: [LearningItem] { dueItems.filter(\.awl) }
    var awlNewItems: [LearningItem] { newItems.filter(\.awl) }

    // MARK: Coverage / comprehensible-input support (strategy §1.4)

    /// Everything the learner currently "knows": the base vocabulary plus the
    /// word tokens of any item they've recalled at least once. Grows as they
    /// study, which in turn unlocks harder graded passages.
    var knownWords: Set<String> {
        var known = baseKnownWords
        for item in items where item.schedule.reps >= 1 {
            for token in CoverageEngine.tokenize(item.target) { known.insert(token) }
        }
        return known
    }

    /// Honest, rough estimate of known word families for the level readout.
    /// Anchored at ~1,000 (the assumed base band) plus items learned.
    var estimatedKnownFamilies: Int {
        1000 + items.filter { $0.schedule.reps >= 1 }.count
    }

    /// The graded passage currently best matched to the learner's coverage.
    var recommendedPassage: ReadingPassage? {
        CoverageEngine.selectPassage(from: contentStore.reading, known: knownWords)
    }

    /// Rough CEFR band estimate from known word families, using the same
    /// frequency thresholds as `server/export_catalog.py`'s `WORD_BANDS` —
    /// keeps the native client's Duel band selection consistent with how
    /// the server buckets its own word/grammar catalog.
    var estimatedBand: String {
        let thresholds: [(String, Int)] = [
            ("Pre-A1", 0), ("A1", 700), ("A2", 1500), ("B1", 2500), ("B2", 3250), ("C1", 4000), ("C2", 4800),
        ]
        var band = thresholds[0].0
        for (name, threshold) in thresholds where estimatedKnownFamilies >= threshold { band = name }
        return band
    }

    // MARK: Mutations

    /// Grade a retrieval attempt and update both the schedule and the metrics.
    /// `isFirstAttempt` distinguishes the accuracy-defining first try from
    /// in-session re-tries after a lapse (which must not pollute accuracy).
    func grade(_ grade: RecallGrade, for item: LearningItem, isFirstAttempt: Bool) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        let newSchedule = FSRSScheduler.apply(grade, to: items[idx].schedule)
        items[idx].schedule = newSchedule
        persistSchedule(itemId: item.id, schedule: newSchedule, createIfMissing: true)

        if isFirstAttempt {
            firstAttempts += 1
            if grade.isSuccess { firstAttemptSuccesses += 1 }
        }

        try? modelContext.save()
    }

    /// Advance the virtual clock by one day and bring due items forward.
    func advanceOneDay() {
        virtualDay += 1
        userProfile.virtualDay = virtualDay
        for i in items.indices {
            items[i].schedule.dueInDays = max(0, items[i].schedule.dueInDays - 1)
            // Only words already reviewed have a row — advancing the day
            // never creates progress for words the learner hasn't touched.
            persistSchedule(itemId: items[i].id, schedule: items[i].schedule, createIfMissing: false)
        }
        try? modelContext.save()
    }

    private func persistSchedule(itemId: String, schedule: ScheduleState, createIfMissing: Bool) {
        if let existing = progressByItemId[itemId] {
            existing.schedule = schedule
        } else if createIfMissing {
            let row = VocabProgress(itemId: itemId, schedule: schedule)
            modelContext.insert(row)
            progressByItemId[itemId] = row
        }
    }

    /// Wipes all learning data — every `VocabProgress` row (FSRS schedules),
    /// every `StarredWord`, and the learning-relevant fields on the
    /// singleton `UserProfile` (points/streak/day counter/goal/milestones).
    /// Deliberately leaves `uiLanguage` and `serverBaseURL` alone — those are
    /// app configuration, not personal learning data, and re-entering them
    /// would just be friction. `UserProfile` is reset in place (its fields
    /// cleared), not deleted+recreated, since other code already holds a
    /// reference to this exact object.
    func resetAllData() {
        for progress in progressByItemId.values {
            modelContext.delete(progress)
        }
        progressByItemId.removeAll()

        let starred = (try? modelContext.fetch(FetchDescriptor<StarredWord>())) ?? []
        for word in starred {
            modelContext.delete(word)
        }

        userProfile.displayName = ""
        userProfile.points = 0
        userProfile.streak = 0
        userProfile.virtualDay = 0
        userProfile.learningGoal = ""
        userProfile.milestonesSeen = []
        userProfile.pointsAtDayStart = 0
        userProfile.streakAtDayStart = 0
        userProfile.examType = ""
        userProfile.examTarget = ""
        virtualDay = 0
        firstAttempts = 0
        firstAttemptSuccesses = 0

        for i in items.indices {
            items[i].schedule = ScheduleState()
        }

        try? modelContext.save()
    }
}
