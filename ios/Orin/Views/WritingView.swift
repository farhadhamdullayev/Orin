import SwiftUI

/// Writing prompt list. Session-only drafts (no cross-launch persistence,
/// same simplification as Grammar/Listening/Visual) — matches the web app's
/// own honest framing: no auto-grading, only objective structural feedback.
struct WritingView: View {
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(contentStore.writingPrompts) { prompt in
            NavigationLink {
                WritingTaskView(prompt: prompt)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(prompt.kind).font(.body)
                        Spacer()
                        Text(prompt.level).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(prompt.prompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .navigationTitle("Yazı")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WritingTaskView: View {
    let prompt: WritingPrompt
    @State private var text = ""
    @State private var showFeedback = false

    private var wordCount: Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    var body: some View {
        if showFeedback {
            WritingFeedbackView(prompt: prompt, text: text) {
                showFeedback = false
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(prompt.prompt)
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                TextEditor(text: $text)
                    .frame(minHeight: 220)
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                HStack {
                    Text("\(wordCount) söz")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("hədəf: \(prompt.minWords)+ söz")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Button {
                    showFeedback = true
                } label: {
                    Text("Yoxla")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .navigationTitle(prompt.kind)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Rule-based-only feedback (word/sentence/paragraph counts, linking-word
/// usage) — deliberately never a "band"/score. Mirrors the web app's
/// WritingFeedback() logic exactly (index.html ~line 25731).
private struct WritingFeedbackView: View {
    let prompt: WritingPrompt
    let text: String
    let onTryAnother: () -> Void
    @Environment(\.dismiss) private var dismiss

    private static let linkingWords = [
        "however", "because", "although", "therefore", "moreover", "furthermore",
        "for example", "for instance", "in addition", "on the other hand",
        "as a result", "in conclusion", "firstly", "secondly", "finally",
        "in my opinion", "despite", "nevertheless", "consequently", "overall",
    ]

    private var wordCount: Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
    private var sentenceCount: Int {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return max(sentences.count, 1)
    }
    private var avgWordsPerSentence: Double {
        (Double(wordCount) / Double(sentenceCount) * 10).rounded() / 10
    }
    private var paragraphCount: Int {
        let paras = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return max(paras.count, 1)
    }
    private var linksUsed: [String] {
        let lower = text.lowercased()
        return Self.linkingWords.filter { lower.contains($0) }
    }

    private var rows: [(ok: Bool, label: String)] {
        [
            (wordCount >= prompt.minWords, "Söz sayı: \(wordCount) (hədəf \(prompt.minWords)+)"),
            (sentenceCount >= 3, "\(sentenceCount) cümlə, orta \(avgWordsPerSentence) söz/cümlə"),
            (paragraphCount >= 2 || wordCount < 150,
             paragraphCount >= 2 ? "\(paragraphCount) paraqraf — struktur var" : "1 paraqraf — uzun cavablarda 2-3 paraqrafa böl"),
            (linksUsed.count >= 2,
             linksUsed.isEmpty
                ? "Heç bir əlaqələndirici söz yoxdur (however, for example, in conclusion...) — fikirləri bağlamaq üçün əlavə et"
                : "\(linksUsed.count) əlaqələndirici söz istifadə etdin: \(linksUsed.prefix(4).joined(separator: ", "))"),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("📝").font(.system(size: 40))
                Text("Yazını yoxladım").font(.title3.bold())

                VStack(spacing: 12) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: row.ok ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(row.ok ? .green : .secondary)
                            Text(row.label)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                Text("⚠️ Bu, bal/band deyil — yalnız obyektiv strukturu göstərir. Qrammatika/məzmun keyfiyyətini özün və ya bir müəllim qiymətləndirməlidir.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    Button("Başqa tapşırıq") { onTryAnother() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    Button("Siyahıya qayıt") { dismiss() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("Geri-bildirim")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}
