import SwiftUI

/// Comprehensible-input reader. Shows the graded passage the CoverageEngine
/// picked for the learner, with the live coverage % and unknown words marked.
/// This makes the strategy's 95%/98% thresholds visible and concrete.
///
/// Every word is individually tappable (via `FlowLayout`) — tapping shows its
/// Azerbaijani translation in a card below the passage, looked up against the
/// same 3871-word vocab catalog the rest of the app uses. Not every English
/// word in a passage is guaranteed to be in that catalog (passages are free
/// text; the catalog is curated), so a miss shows an honest "not found"
/// message rather than nothing.
struct ReadingView: View {
    let passage: ReadingPassage
    let known: Set<String>

    @Environment(ContentStore.self) private var contentStore
    @Environment(LocalizationStore.self) private var localization
    @State private var vocabLookup: [String: [String: String]] = [:]
    @State private var selectedWord: String?

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

            wordFlow
                .font(.title3)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

            if let selectedWord {
                translationCard(for: selectedWord)
            }

            Button {
                Speaker.shared.speak(passage.text)
            } label: {
                Label("Dinlə", systemImage: "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)

            if !unknown.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yeni sözlər (\(unknown.count)) — toxunub tərcüməsinə bax:")
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
        .task {
            guard vocabLookup.isEmpty else { return }
            var lookup: [String: [String: String]] = [:]
            for item in contentStore.vocab {
                // Multi-word targets ("to keep", "as soon as") can't map to a
                // single passage word — skip them rather than mis-key on
                // their first token (e.g. "to", colliding across dozens of
                // "to <verb>" entries and showing the wrong translation).
                let tokens = CoverageEngine.tokenize(item.target)
                guard tokens.count == 1, let key = tokens.first else { continue }
                if lookup[key] == nil { lookup[key] = item.gloss }
            }
            vocabLookup = lookup
        }
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

    /// Individually-tappable words, tinting words not in the known set.
    private var wordFlow: some View {
        FlowLayout(spacing: 5) {
            ForEach(Array(passage.text.split(separator: " ", omittingEmptySubsequences: true).enumerated()), id: \.offset) { _, raw in
                let display = String(raw)
                let normalized = CoverageEngine.tokenize(display).first ?? ""
                let isKnown = normalized.isEmpty || known.contains(normalized)
                Button {
                    selectedWord = normalized.isEmpty ? nil : normalized
                } label: {
                    Text(display)
                        .foregroundStyle(isKnown ? Color.primary : Color.orange)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// The catalog stores only base/dictionary forms ("walk"), but passage
    /// text naturally uses inflected forms ("walked"/"walking"/"walks") —
    /// try common regular-suffix strips before giving up. Doesn't catch
    /// irregular forms (went/ate) or words genuinely outside the 3871-word
    /// catalog; those honestly report "not found" rather than guessing.
    private func lookupGloss(for word: String) -> [String: String]? {
        if let gloss = vocabLookup[word] { return gloss }
        var candidates: [String] = []
        if word.hasSuffix("ies") { candidates.append(String(word.dropLast(3)) + "y") }
        if word.hasSuffix("ing") {
            let stem = String(word.dropLast(3))
            candidates.append(stem)
            candidates.append(stem + "e")
        }
        if word.hasSuffix("ed") {
            candidates.append(String(word.dropLast(2)))
            candidates.append(String(word.dropLast(1)))
        }
        if word.hasSuffix("es") { candidates.append(String(word.dropLast(2))) }
        if word.hasSuffix("s") { candidates.append(String(word.dropLast(1))) }
        for candidate in candidates {
            if let gloss = vocabLookup[candidate] { return gloss }
        }
        return nil
    }

    private func translationCard(for word: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "text.bubble.fill").foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(word).font(.subheadline.weight(.semibold))
                if let gloss = lookupGloss(for: word) {
                    Text(localization.text(gloss, fallback: gloss["az"] ?? ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Tərcümə tapılmadı (kataloqda yoxdur)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .transition(.opacity)
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
