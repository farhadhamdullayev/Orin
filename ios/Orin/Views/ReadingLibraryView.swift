import SwiftUI

/// Browsable list of the full 1200-passage graded reader library, sorted
/// easiest → hardest by the learner's current coverage. Tapping a passage
/// opens `ReadingPassageDetailView`, which reuses the existing `ReadingView`
/// and adds in-place next/previous navigation through the sorted list — no
/// need to back out to this list between passages.
struct ReadingLibraryView: View {
    @Environment(LearningStore.self) private var store
    @Environment(ContentStore.self) private var contentStore
    // Computed once (not a live `body`-computed property) — tokenizing +
    // sorting 1200 passages on every SwiftUI re-render would be wasteful.
    @State private var sortedByCoverage: [(passage: ReadingPassage, coverage: Double)] = []

    var body: some View {
        List(Array(sortedByCoverage.enumerated()), id: \.element.passage.id) { i, entry in
            NavigationLink {
                ReadingPassageDetailView(
                    passages: sortedByCoverage.map(\.passage),
                    startIndex: i,
                    known: store.knownWords
                )
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

/// One passage, with "Növbəti mətn"/"Əvvəlki mətn" buttons that move through
/// `passages` in place — the same "practiceQueue index" pattern used by
/// `GrammarPracticeView`/`ListeningPracticeView`.
struct ReadingPassageDetailView: View {
    let passages: [ReadingPassage]
    let known: Set<String>
    @State private var index: Int

    init(passages: [ReadingPassage], startIndex: Int, known: Set<String>) {
        self.passages = passages
        self.known = known
        _index = State(initialValue: startIndex)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ReadingView(passage: passages[index], known: known)

                HStack(spacing: 12) {
                    Button {
                        index -= 1
                    } label: {
                        Label("Əvvəlki", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.bordered)
                    .disabled(index == 0)

                    Button {
                        index += 1
                    } label: {
                        Label("Növbəti mətn", systemImage: "chevron.right")
                            .frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(index == passages.count - 1)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(passages[index].title)
        .navigationBarTitleDisplayMode(.inline)
        // Reading view carries per-passage @State (selectedWord/lookup
        // cache); forcing a fresh identity per passage index avoids stale
        // "selected word" bleeding into the next passage's card.
        .id(passages[index].id)
    }
}
