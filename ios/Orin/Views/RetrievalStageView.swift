import SwiftUI

/// Stage 2 — Retrieval (Xatırla). The best-evidenced mechanism in the whole
/// strategy. The learner is shown only the *cue* and must actively produce the
/// answer from memory before revealing it, then self-grades. The first grade on
/// each item feeds recall-accuracy (the real metric); in-session re-tries don't.
struct RetrievalStageView: View {
    @Environment(LearningStore.self) private var store
    @Environment(LocalizationStore.self) private var localization
    @Bindable var session: SessionViewModel

    @State private var index = 0
    @State private var revealed = false
    @State private var gradedIDs: Set<String> = []   // which items had a first grade

    private var item: LearningItem { session.batch[index] }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Cue: native gloss + blanked context. Learner must recall `target`.
            VStack(spacing: 14) {
                Text(localization.text(item.gloss, fallback: item.target))
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(blankedExample)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if revealed {
                    Divider().padding(.vertical, 4)
                    Text(item.target)
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundStyle(Color.accentColor)
                        .transition(.opacity)
                    Text(item.exampleTarget)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)

            Spacer()

            if revealed {
                gradeButtons
            } else {
                Button {
                    withAnimation { revealed = true }
                } label: {
                    Text("Cavabı göstər")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                Text("Əvvəlcə yadında canlandır, sonra aç")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text("\(index + 1) / \(session.batch.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
    }

    private var gradeButtons: some View {
        HStack(spacing: 10) {
            ForEach(RecallGrade.allCases) { option in
                Button {
                    grade(option)
                } label: {
                    Text(option.label)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(color(for: option))
            }
        }
        .padding(.horizontal)
    }

    private func grade(_ grade: RecallGrade) {
        let isFirst = !gradedIDs.contains(item.id)
        store.grade(grade, for: item, isFirstAttempt: isFirst)
        gradedIDs.insert(item.id)

        withAnimation {
            revealed = false
            if index < session.batch.count - 1 {
                index += 1
            } else {
                session.advanceStage()
            }
        }
    }

    /// Replace the target inside its example with a blank as a recall scaffold.
    private var blankedExample: String {
        item.exampleTarget.replacingOccurrences(
            of: item.target,
            with: "____",
            options: [.caseInsensitive]
        )
    }

    private func color(for grade: RecallGrade) -> Color {
        switch grade {
        case .again: return .red
        case .hard:  return .orange
        case .good:  return .green
        case .easy:  return .blue
        }
    }
}
