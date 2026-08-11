import SwiftUI

/// Topic list for grammar practice. Session-only (no cross-launch progress
/// tracking) — matches the web app's own behaviour: grammar drills are
/// practiced in batches, not individually spaced-repetition scheduled.
struct GrammarView: View {
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(contentStore.grammar) { topic in
            NavigationLink {
                GrammarPracticeView(topic: topic)
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

/// Runs the drill batch for one topic: note + examples, then an MCQ loop.
struct GrammarPracticeView: View {
    let topic: GrammarTopic
    @State private var index = 0
    @State private var showIntro = true
    @State private var selected: Int?
    @State private var correctCount = 0

    var body: some View {
        if showIntro {
            introView
        } else if index < topic.drills.count {
            drillView(topic.drills[index])
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

            if selected != nil {
                Button("Növbəti") { advance() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.bottom)
        .navigationTitle("\(index + 1) / \(topic.drills.count)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func color(for i: Int, drill: GrammarDrill) -> Color {
        guard let selected else { return .primary }
        if i == drill.correctIndex { return .green }
        if i == selected { return .red }
        return .primary
    }

    private func advance() {
        if selected == topic.drills[index].correctIndex { correctCount += 1 }
        selected = nil
        index += 1
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("\(correctCount) / \(topic.drills.count) düzgün")
                .font(.title2.bold())
        }
        .navigationTitle("Nəticə")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func strippingTags(_ s: String) -> String {
        s.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
    }
}
