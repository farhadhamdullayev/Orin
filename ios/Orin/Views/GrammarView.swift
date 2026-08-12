import SwiftUI

/// Topic list for grammar practice. Session-only (no cross-launch progress
/// tracking) — matches the web app's own behaviour: grammar drills are
/// practiced in batches, not individually spaced-repetition scheduled.
struct GrammarView: View {
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(Array(contentStore.grammar.enumerated()), id: \.element.id) { i, topic in
            NavigationLink {
                GrammarPracticeView(topics: contentStore.grammar, startIndex: i)
            } label: {
                HStack {
                    Text(topic.icon)
                    VStack(alignment: .leading) {
                        Text(topic.title).font(.body)
                        Text(topic.level).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Qrammatika")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Runs the drill batch for one topic: note + examples, then an MCQ loop
/// over `practiceQueue` (the full topic, or — after a "retry mistakes"
/// choice — just the drills answered wrong), then a mistakes-only result
/// list with in-place "retry" / "next topic" actions.
struct GrammarPracticeView: View {
    let topics: [GrammarTopic]
    @State private var topicIndex: Int
    @State private var drillIndex = 0
    @State private var showIntro = true
    @State private var selected: Int?
    /// The drills being worked through this pass — either `topic.drills` or,
    /// after "Səhvlərin təkrarı", just the ones answered wrong last time.
    @State private var practiceQueue: [GrammarDrill] = []
    /// Which option index the learner picked for each entry in
    /// `practiceQueue`, in order — drives both the score and the
    /// tap-to-explain result rows.
    @State private var picks: [Int] = []

    init(topics: [GrammarTopic], startIndex: Int) {
        self.topics = topics
        _topicIndex = State(initialValue: startIndex)
    }

    private var topic: GrammarTopic { topics[topicIndex] }
    private var hasNextTopic: Bool { topicIndex < topics.count - 1 }
    private var wrongEntries: [(index: Int, drill: GrammarDrill)] {
        Array(zip(picks, practiceQueue).enumerated()).compactMap { i, pair in
            pair.0 != pair.1.correctIndex ? (i, pair.1) : nil
        }
    }

    var body: some View {
        if showIntro {
            introView
        } else if drillIndex < practiceQueue.count {
            drillView(practiceQueue[drillIndex])
        } else {
            resultView
        }
    }

    private var introView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(strippingTags(topic.note))
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                ForEach(Array(topic.examples.enumerated()), id: \.offset) { _, ex in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.english).font(.body.weight(.medium))
                        Text(ex.gloss).font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    practiceQueue = topic.drills
                    picks = []
                    drillIndex = 0
                    showIntro = false
                } label: {
                    Text(topic.drills.isEmpty ? "Drill yoxdur" : "Məşqə başla")
                        .frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(topic.drills.isEmpty)
            }
            .padding()
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func drillView(_ drill: GrammarDrill) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text(drill.question)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .padding()

            VStack(spacing: 10) {
                ForEach(Array(drill.options.enumerated()), id: \.offset) { i, opt in
                    Button {
                        if selected == nil { selected = i }
                    } label: {
                        Text(opt)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .tint(color(for: i, drill: drill))
                    .disabled(selected != nil)
                }
            }
            .padding(.horizontal)

            if selected != nil {
                Text(drill.gloss)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.bottom)
        .onChange(of: selected) { _, newValue in
            guard newValue != nil else { return }
            Task {
                try? await Task.sleep(for: .seconds(1.1))
                advance()
            }
        }
        .navigationTitle("\(drillIndex + 1) / \(practiceQueue.count)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func color(for i: Int, drill: GrammarDrill) -> Color {
        guard let selected else { return .primary }
        if i == drill.correctIndex { return .green }
        if i == selected { return .red }
        return .primary
    }

    private func advance() {
        picks.append(selected ?? -1)
        selected = nil
        drillIndex += 1
    }

    private var resultView: some View {
        let correctCount = picks.count - wrongEntries.count
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: wrongEntries.isEmpty ? "star.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(wrongEntries.isEmpty ? .yellow : .green)
                Text("\(correctCount) / \(picks.count) düzgün")
                    .font(.title2.bold())

                if wrongEntries.isEmpty {
                    Text("Hamısı düzgün! 🎉")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Səhv cavablar — toxunub izahı görə bilərsiniz")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        ForEach(Array(wrongEntries.enumerated()), id: \.offset) { row, entry in
                            GrammarResultRow(drill: entry.drill, pickedIndex: picks[entry.index], rule: strippingTags(topic.note))
                            if row < wrongEntries.count - 1 { Divider() }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                VStack(spacing: 12) {
                    if hasNextTopic {
                        Button {
                            goToNextTopic()
                        } label: {
                            Label("Növbəti mövzu", systemImage: "arrow.right.circle.fill")
                                .frame(maxWidth: .infinity).padding()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    if !wrongEntries.isEmpty {
                        Button {
                            retryMistakesOnly()
                        } label: {
                            Label("Səhvlərin təkrarı", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity).padding()
                        }
                        .buttonStyle(.bordered)
                    }
                    Button("Tam mövzunun təkrarı") { restartSameTopic() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("Nəticə")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func retryMistakesOnly() {
        practiceQueue = wrongEntries.map(\.drill)
        drillIndex = 0
        selected = nil
        picks = []
        showIntro = false
    }

    private func restartSameTopic() {
        practiceQueue = topic.drills
        drillIndex = 0
        selected = nil
        picks = []
        showIntro = true
    }

    private func goToNextTopic() {
        topicIndex += 1
        practiceQueue = topic.drills
        drillIndex = 0
        selected = nil
        picks = []
        showIntro = true
    }

    private func strippingTags(_ s: String) -> String {
        s.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
    }
}

/// One tappable result row — expands to show the corrected sentence, its
/// Azerbaijani translation, what the learner picked vs the right answer,
/// and the topic's grammar rule, so a mistake always comes with a concrete "why".
private struct GrammarResultRow: View {
    let drill: GrammarDrill
    let pickedIndex: Int
    let rule: String
    @State private var expanded = false

    private var correctedSentence: String {
        drill.question.replacingOccurrences(of: "___", with: drill.options[drill.correctIndex])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { expanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(drill.question)
                        .font(.caption)
                        .lineLimit(expanded ? nil : 2)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text(correctedSentence)
                        .font(.callout.weight(.semibold))
                    Text(drill.gloss)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pickedIndex >= 0 && pickedIndex < drill.options.count
                         ? "Sizin cavabınız: \(drill.options[pickedIndex]) — düzgünü: \(drill.options[drill.correctIndex])"
                         : "Düzgün cavab: \(drill.options[drill.correctIndex])")
                        .font(.caption)
                        .foregroundStyle(.red)

                    Divider().padding(.vertical, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Qayda")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                        Text(rule)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.leading, 26)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
    }
}
