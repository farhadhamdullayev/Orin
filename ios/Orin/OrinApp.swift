import SwiftUI
import SwiftData

/// Orin — evidence-based English learning.
///
/// This build demonstrates the *core learning loop* from the strategy doc:
///   Input (understand) → Retrieval (recall) → Output (produce) → Schedule (space)
/// over the full vocabulary catalog (`Resources/Content/vocab.json`), with
/// real persistence (SwiftData) so progress survives a relaunch.
///
/// It deliberately shows real-acquisition metrics (recall accuracy, mastered items)
/// and NO streaks / XP as a success signal.
@main
struct OrinApp: App {
    let modelContainer: ModelContainer

    @State private var contentStore: ContentStore
    @State private var localization: LocalizationStore
    @State private var store: LearningStore

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: VocabProgress.self, UserProfile.self)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
        modelContainer = container

        let content = ContentStore()
        let loc = LocalizationStore()
        _contentStore = State(initialValue: content)
        _localization = State(initialValue: loc)
        _store = State(initialValue: LearningStore(
            contentStore: content,
            localization: loc,
            modelContext: container.mainContext
        ))
    }

    var body: some Scene {
        WindowGroup {
            OrinTabView()
                .environment(store)
                .environment(contentStore)
                .environment(localization)
        }
        .modelContainer(modelContainer)
    }
}
