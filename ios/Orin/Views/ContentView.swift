import SwiftUI

/// Root view. Either the home screen (metrics + start) or an active session
/// that walks through the four loop stages.
struct ContentView: View {
    @Environment(LearningStore.self) private var store
    @State private var session: SessionViewModel?

    var body: some View {
        NavigationStack {
            if let session {
                SessionContainerView(session: session) {
                    self.session = nil          // session finished → back home
                }
            } else {
                HomeView(startSession: startSession)
            }
        }
    }

    private func startSession() {
        session = SessionViewModel(store: store)
    }
}

/// Home: shows the *real-acquisition* snapshot and a start button.
private struct HomeView: View {
    @Environment(LearningStore.self) private var store
    let startSession: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Orin")
                        .font(.largeTitle.bold())
                    Text("Dürüst, elmə əsaslanan öyrənmə")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                MetricsDashboardView()

                let dueCount = store.dueItems.count
                Button(action: startSession) {
                    Label(
                        dueCount > 0 ? "\(dueCount) element hazırdır — başla" : "Öyrənmə döngəsini başlat",
                        systemImage: "play.circle.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Text("Gün: \(store.virtualDay) · Streak yoxdur — yalnız real bilik ölçülür")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Hosts the current stage and a progress header across the four stages.
/// Not `private` — reused by `AWLPracticeView` for the AWL-only track.
struct SessionContainerView: View {
    @Environment(LearningStore.self) private var store
    @Bindable var session: SessionViewModel
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StageProgressBar(current: session.stage)
                .padding()

            Divider()

            Group {
                switch session.stage {
                case .input:     InputStageView(session: session)
                case .retrieval: RetrievalStageView(session: session)
                case .output:    OutputStageView(session: session)
                case .review:    SessionReviewView(session: session, onFinish: onFinish)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(session.stage.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A four-dot header showing where we are in the loop.
private struct StageProgressBar: View {
    let current: LoopStage

    var body: some View {
        HStack(spacing: 12) {
            ForEach(LoopStage.allCases, id: \.rawValue) { stage in
                VStack(spacing: 6) {
                    Image(systemName: stage.systemImage)
                        .foregroundStyle(stage.rawValue <= current.rawValue ? Color.accentColor : .secondary)
                    Text(stage.title)
                        .font(.caption2)
                        .foregroundStyle(stage.rawValue == current.rawValue ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
