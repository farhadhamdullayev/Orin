import SwiftUI

/// Stage 1 — Input (Anla). Comprehensible-input style exposure. Opens with a
/// coverage-graded reader (the passage matched to the learner's level), then
/// meets each item *in context* with audio (dual coding) before any recall.
/// Low affective filter: no scoring here.
struct InputStageView: View {
    @Environment(LearningStore.self) private var store
    @Environment(LocalizationStore.self) private var localization
    @Bindable var session: SessionViewModel
    @State private var showReader = true
    @State private var index = 0

    private var item: LearningItem { session.batch[index] }

    var body: some View {
        if showReader, let passage = store.recommendedPassage {
            VStack(spacing: 0) {
                ScrollView { ReadingView(passage: passage, known: store.knownWords) }
                Divider()
                Button {
                    withAnimation { showReader = false }
                } label: {
                    Label("Sözlərə keç", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        } else {
            itemFlow
        }
    }

    private var itemFlow: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text(item.target)
                    .font(.system(.largeTitle, design: .rounded).bold())

                Text(localization.text(item.gloss, fallback: item.target))
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Divider().padding(.vertical, 8)

                Text(item.exampleTarget)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                Text(localization.text(item.exampleGloss))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)

            Button {
                Speaker.shared.speak(item.exampleTarget)
            } label: {
                Label("Dinlə", systemImage: "speaker.wave.2.fill")
                    .font(.headline)
            }
            .buttonStyle(.bordered)

            Spacer()

            HStack {
                Text("\(index + 1) / \(session.batch.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(isLast ? "Xatırlamağa keç" : "Növbəti") {
                    if isLast { session.advanceStage() }
                    else { withAnimation { index += 1; Speaker.shared.speak(session.batch[index].exampleTarget) } }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear { Speaker.shared.speak(item.exampleTarget) }
    }

    private var isLast: Bool { index == session.batch.count - 1 }
}
