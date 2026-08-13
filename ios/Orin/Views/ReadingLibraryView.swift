import SwiftUI

/// Browsable list of the full 1200-passage graded reader library, sorted
/// easiest → hardest by the learner's current coverage. Tapping a passage
/// reuses the existing `ReadingView` (coverage badge, highlighted unknown
/// words, "Dinlə") that already powers the Input stage's recommended read.
struct ReadingLibraryView: View {
    @Environment(LearningStore.self) private var store
    @Environment(ContentStore.self) private var contentStore
    // Computed once (not a live `body`-computed property) — tokenizing +
    // sorting 1200 passages on every SwiftUI re-render would be wasteful.
    @State private var sortedByCoverage: [(passage: ReadingPassage, coverage: Double)] = []

    var body: some View {
        List(sortedByCoverage, id: \.passage.id) { entry in
            NavigationLink {
                ScrollView { ReadingView(passage: entry.passage, known: store.knownWords) }
                    .navigationTitle(entry.passage.title)
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.passage.title).font(.body)
                        Text("\(entry.passage.wordCount) söz")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(Int(entry.coverage * 100))%")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(CoverageEngine.band(forCoverage: entry.coverage) == .tooHard ? .red : .green)
                }
            }
        }
        .navigationTitle("Oxu (\(contentStore.reading.count))")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard sortedByCoverage.isEmpty else { return }
            let known = store.knownWords
            sortedByCoverage = contentStore.reading
                .map { ($0, CoverageEngine.coverage(of: $0.text, known: known)) }
                .sorted { $0.1 > $1.1 }
        }
    }
}
