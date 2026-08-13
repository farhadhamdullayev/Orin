import SwiftUI

/// Comprehensible-input reader. Shows the graded passage the CoverageEngine
/// picked for the learner, with the live coverage % and unknown words marked.
/// This makes the strategy's 95%/98% thresholds visible and concrete.
struct ReadingView: View {
    let passage: ReadingPassage
    let known: Set<String>

    private var coverage: Double { CoverageEngine.coverage(of: passage.text, known: known) }
    private var band: CoverageEngine.Band { CoverageEngine.band(forCoverage: coverage) }
    private var unknown: [String] { CoverageEngine.unknownWords(in: passage.text, known: known) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(passage.title).font(.headline)
                    Text("\(passage.wordCount) söz").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                coverageBadge
            }

            // Passage with unknown words highlighted.
            highlightedText
                .font(.title3)
                .lineSpacing(6)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

            Button {
                Speaker.shared.speak(passage.text)
            } label: {
                Label("Dinlə", systemImage: "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)

            if !unknown.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yeni sözlər (\(unknown.count)):")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(unknown.joined(separator: " · "))
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color.orange)
                }
            }

            Text(explanation)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }

    private var coverageBadge: some View {
        VStack(spacing: 2) {
            Text("\(Int(coverage * 100))%")
                .font(.title3.bold().monospacedDigit())
            Text(band.label).font(.caption2)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(bandColor.opacity(0.15), in: Capsule())
        .foregroundStyle(bandColor)
    }

    /// Render the passage word-by-word, tinting words not in the known set.
    private var highlightedText: Text {
        // Split on spaces but keep words; punctuation stays attached for display.
        var result = AttributedString()
        for raw in passage.text.split(separator: " ", omittingEmptySubsequences: true) {
            let display = String(raw)
            let normalized = CoverageEngine.tokenize(display).first ?? ""
            let isKnown = normalized.isEmpty || known.contains(normalized)
            var piece = AttributedString(display + " ")
            piece.foregroundColor = isKnown ? Color.primary : Color.orange
            result.append(piece)
        }
        return Text(result)
    }

    private var explanation: String {
        switch band {
        case .tooHard:
            return "95%-dən aşağı — çətin zona. Bir az daha asan mətn və ya daha çox söz lazımdır."
        case .supported:
            return "95–98% — ideal öyrənmə zonası: kontekstdən yeni sözləri tuta bilərsən (comprehensible input)."
        case .independent:
            return "98%+ — müstəqil anlama. Axıcılıq və özünəinam üçün yaxşıdır."
        }
    }

    private var bandColor: Color {
        switch band {
        case .tooHard: return .red
        case .supported: return .green
        case .independent: return .blue
        }
    }
}
