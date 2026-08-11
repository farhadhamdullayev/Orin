import SwiftUI

/// Topic list for listening practice. Session-only, same reasoning as
/// `GrammarView` — the web app doesn't spaced-repetition-schedule these either.
struct ListeningView: View {
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(contentStore.listening) { topic in
            NavigationLink {
                ListeningPracticeView(topic: topic)
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

struct ListeningPracticeView: View {
    let topic: ListeningTopic
    @State private var index = 0
    @State private var selected: String?
    @State private var correctCount = 0

    private var item: ListeningItem? {
        index < topic.items.count ? topic.items[index] : nil
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

                if selected != nil {
                    Button("Növbəti") { advance() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.bottom)
            .navigationTitle("\(index + 1) / \(topic.items.count)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { Speaker.shared.speak(item.english) }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("\(correctCount) / \(topic.items.count) düzgün")
                    .font(.title2.bold())
            }
            .navigationTitle("Nəticə")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func color(for opt: String, item: ListeningItem) -> Color {
        guard let selected else { return .primary }
        if opt == item.correctAnswer { return .green }
        if opt == selected { return .red }
        return .primary
    }

    private func advance() {
        if selected == topic.items[index].correctAnswer { correctCount += 1 }
        selected = nil
        index += 1
        if index < topic.items.count { Speaker.shared.speak(topic.items[index].english) }
    }
}
