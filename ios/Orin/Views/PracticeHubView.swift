import SwiftUI

/// "Practice" tab — entry hub for the content modules that don't have their
/// own spaced-repetition schedule (Grammar/Listening/Visual vocab practice
/// happens in self-contained sessions, unlike the FSRS-scheduled vocab deck
/// on the Learn tab). New modules land here as another card, not a new tab —
/// keeps the tab bar from growing one-tab-per-module (see the plan's
/// navigation guidance).
struct PracticeHubView: View {
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink {
                    GrammarView()
                } label: {
                    ModuleCard(
                        icon: "textformat.abc",
                        title: "Qrammatika",
                        subtitle: "\(contentStore.grammar.count) mövzu",
                        tint: .blue
                    )
                }

                NavigationLink {
                    ListeningView()
                } label: {
                    ModuleCard(
                        icon: "ear",
                        title: "Dinləmə",
                        subtitle: "\(contentStore.listening.count) mövzu",
                        tint: .purple
                    )
                }

                NavigationLink {
                    VisualVocabView()
                } label: {
                    ModuleCard(
                        icon: "photo.on.rectangle",
                        title: "Vizual lüğət",
                        subtitle: "\(contentStore.visualVocab.count) kateqoriya",
                        tint: .orange
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Məşq")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ModuleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
