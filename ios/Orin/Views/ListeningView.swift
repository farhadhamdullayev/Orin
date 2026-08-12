import SwiftUI

/// Topic list for listening practice. Session-only, same reasoning as
/// `GrammarView` — the web app doesn't spaced-repetition-schedule these either.
struct ListeningView: View {
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(Array(contentStore.listening.enumerated()), id: \.element.id) { i, topic in
            NavigationLink {
                ListeningPracticeView(topics: contentStore.listening, startIndex: i)
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
        .navigationTitle("Dinləmə")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Same "practice queue" / "retry mistakes only" / "next topic" pattern as
/// `GrammarPracticeView` — see that file for the rationale.
struct ListeningPracticeView: View {
    let topics: [ListeningTopic]
    @State private var topicIndex: Int
    @State private var itemIndex = 0
    @State private var selected: String?
    /// The items being worked through this pass — either `topic.items` or,
    /// after "Səhvlərin təkrarı", just the ones answered wrong last time.
    @State private var practiceQueue: [ListeningItem]
    /// The option string the learner picked for each entry in
    /// `practiceQueue`, in order ("" = skipped).
    @State private var picks: [String] = []

    init(topics: [ListeningTopic], startIndex: Int) {
        self.topics = topics
        _topicIndex = State(initialValue: startIndex)
        _practiceQueue = State(initialValue: topics[startIndex].items)
    }

    private var topic: ListeningTopic { topics[topicIndex] }
    private var hasNextTopic: Bool { topicIndex < topics.count - 1 }
    private var item: ListeningItem? {
        itemIndex < practiceQueue.count ? practiceQueue[itemIndex] : nil
    }
    private var wrongEntries: [(index: Int, item: ListeningItem)] {
        Array(zip(picks, practiceQueue).enumerated()).compactMap { i, pair in
            pair.0 != pair.1.correctAnswer ? (i, pair.1) : nil
        }
    }

    var body: some View {
        if let item {
            VStack(spacing: 24) {
                Spacer()

                Button {
                    Speaker.shared.speak(item.english)
                } label: {
                    Label("Dinlə", systemImage: "speaker.wave.2.fill")
                        .font(.title3)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                Text(item.question)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    ForEach(item.options, id: \.self) { opt in
                        Button {
                            if selected == nil { selected = opt }
                        } label: {
                            Text(opt)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.bordered)
                        .tint(color(for: opt, item: item))
                        .disabled(selected != nil)
                    }
                }
                .padding(.horizontal)

                if selected != nil {
                    VStack(spacing: 4) {
                        Text(item.english).font(.callout.weight(.medium))
                        Text(item.gloss).font(.caption).foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.bottom)
            .navigationTitle("\(itemIndex + 1) / \(practiceQueue.count)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { Speaker.shared.speak(item.english) }
            .onChange(of: selected) { _, newValue in
                guard newValue != nil else { return }
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    advance()
                }
            }
        } else {
            resultView
        }
    }

    private func color(for opt: String, item: ListeningItem) -> Color {
        guard let selected else { return .primary }
        if opt == item.correctAnswer { return .green }
        if opt == selected { return .red }
        return .primary
    }

    private func advance() {
        picks.append(selected ?? "")
        selected = nil
        itemIndex += 1
        if itemIndex < practiceQueue.count { Speaker.shared.speak(practiceQueue[itemIndex].english) }
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
                            ListeningResultRow(item: entry.item, picked: picks[entry.index])
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
        practiceQueue = wrongEntries.map(\.item)
        itemIndex = 0
        selected = nil
        picks = []
    }

    private func restartSameTopic() {
        practiceQueue = topic.items
        itemIndex = 0
        selected = nil
        picks = []
    }

    private func goToNextTopic() {
        topicIndex += 1
        practiceQueue = topic.items
        itemIndex = 0
        selected = nil
        picks = []
    }
}

/// One tappable result row — expands to show the English sentence, its
/// Azerbaijani translation, and what the learner picked vs the right answer,
/// so a mistake always comes with a concrete "why".
private struct ListeningResultRow: View {
    let item: ListeningItem
    let picked: String
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { expanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(item.question)
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
                    Text(item.english)
                        .font(.callout.weight(.semibold))
                    Text(item.gloss)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(picked.isEmpty
                         ? "Düzgün cavab: \(item.correctAnswer)"
                         : "Sizin cavabınız: \(picked) — düzgünü: \(item.correctAnswer)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.leading, 26)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
    }
}
