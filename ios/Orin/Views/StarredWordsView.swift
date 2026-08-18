import SwiftUI
import SwiftData

/// Personal review list built from words starred (⭐) while reading. Browse
/// and un-star here, or run a flashcard practice pass — marking a word
/// "learned" during practice removes it the same way un-starring it here
/// does (one remove path, not two).
struct StarredWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StarredWord.dateAdded, order: .reverse) private var starred: [StarredWord]
    /// A frozen snapshot taken when practice starts — NOT the live `@Query`,
    /// which would reshuffle indices mid-session as entries get deleted
    /// (marking one "learned" removes it, shifting every later index).
    @State private var practiceSnapshot: [StarredWord]?

    var body: some View {
        Group {
            if let practiceSnapshot {
                StarredWordsPracticeView(words: practiceSnapshot) {
                    self.practiceSnapshot = nil
                }
            } else {
                listView
            }
        }
        .navigationTitle("Ulduzlu sözlər (\(starred.count))")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var listView: some View {
        VStack(spacing: 0) {
            if starred.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        Image(systemName: "star").font(.system(size: 40)).foregroundStyle(.secondary)
                        Text("Hələ ulduzlu söz yoxdur")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Oxu bölməsində bir sözə toxunub tərcüməsini görəndə, yanındakı ⭐ ilə bura əlavə edə bilərsiniz.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                Button {
                    practiceSnapshot = starred
                } label: {
                    Label("Məşq et", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)
                .padding()

                List {
                    ForEach(starred) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.word).font(.body.weight(.medium))
                                Text(entry.translation).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                modelContext.delete(entry)
                                try? modelContext.save()
                            } label: {
                                Image(systemName: "star.fill").foregroundStyle(.yellow)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct StarredWordsPracticeView: View {
    let words: [StarredWord]
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var index = 0
    @State private var revealed = false

    var body: some View {
        if index < words.count {
            let entry = words[index]
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 14) {
                    Text(entry.word).font(.system(.title, design: .rounded).bold())
                    if revealed {
                        Divider()
                        Text(entry.translation)
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                            .transition(.opacity)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                Spacer()

                if revealed {
                    HStack(spacing: 12) {
                        Button {
                            modelContext.delete(entry)
                            try? modelContext.save()
                            advance()
                        } label: {
                            Label("Bilirəm, sil", systemImage: "checkmark")
                                .frame(maxWidth: .infinity).padding()
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            advance()
                        } label: {
                            Text("Yenə göstər").frame(maxWidth: .infinity).padding()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                } else {
                    Button {
                        withAnimation { revealed = true }
                    } label: {
                        Text("Tərcüməni göstər").frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }

                Text("\(index + 1) / \(words.count)").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.bottom)
            .navigationBarBackButtonHidden(true)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 48)).foregroundStyle(.green)
                Text("Siyahı bitdi").font(.title3.bold())
                Button("Bitir") { onFinish() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    private func advance() {
        revealed = false
        index += 1
    }
}
