import SwiftUI

/// Entry point for Academic Word List practice — same Input→Retrieval→
/// Output→Review loop as the main vocab deck (reuses `SessionContainerView`
/// from ContentView.swift), just filtered to `VocabItem.awl == true` words
/// via `SessionViewModel(awlOnly: true)`.
struct AWLPracticeView: View {
    @Environment(LearningStore.self) private var store
    @State private var session: SessionViewModel?

    var body: some View {
        if let session {
            SessionContainerView(session: session) {
                self.session = nil
            }
        } else {
            introView
        }
    }

    private var introView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🎓").font(.system(size: 44))
                Text("Akademik Söz Siyahısı (AWL)")
                    .font(.title3.bold())
                Text("IELTS/TOEFL kimi imtahanlarda tez-tez rast gəlinən akademik sözlər — eyni FSRS cədvəli ilə, adi lüğət kimi.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                let dueCount = store.awlDueItems.count
                Button {
                    session = SessionViewModel(store: store, awlOnly: true)
                } label: {
                    Label(
                        dueCount > 0 ? "\(dueCount) AWL sözü hazırdır — başla" : "AWL məşqini başlat",
                        systemImage: "play.circle.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("AWL")
        .navigationBarTitleDisplayMode(.inline)
    }
}
