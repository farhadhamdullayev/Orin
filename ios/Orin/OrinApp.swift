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
        modelContainer = Self.makeModelContainer()

        let content = ContentStore()
        let loc = LocalizationStore()
        _contentStore = State(initialValue: content)
        _localization = State(initialValue: loc)
        _store = State(initialValue: LearningStore(
            contentStore: content,
            localization: loc,
            modelContext: modelContainer.mainContext
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

    /// Pre-launch, there's no shipped user base whose data must survive a
    /// schema change (`UserProfile`/`VocabProgress` gained fields multiple
    /// times across phases already) — SwiftData's automatic lightweight
    /// migration can't always reconcile an on-disk store built under an
    /// older schema (e.g. adding a new non-optional attribute), and fails
    /// with "Cannot migrate store in-place". Rather than hard-crash on every
    /// such schema change during development, fall back to deleting the
    /// on-disk store and starting fresh. Safe to remove once the schema is
    /// stable ahead of a real release.
    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: VocabProgress.self, UserProfile.self, StarredWord.self)
        } catch {
            print("ModelContainer init failed (\(error)) — deleting on-disk store and retrying fresh.")
            deleteDefaultStore()
            do {
                return try ModelContainer(for: VocabProgress.self, UserProfile.self, StarredWord.self)
            } catch {
                fatalError("Failed to initialize SwiftData ModelContainer even after a fresh store: \(error)")
            }
        }
    }

    private static func deleteDefaultStore() {
        guard let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        for suffix in ["", "-wal", "-shm"] {
            let url = supportDir.appendingPathComponent("default.store\(suffix)")
            try? FileManager.default.removeItem(at: url)
        }
    }
}
