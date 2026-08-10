import SwiftUI

/// The honest metrics panel. Every tile here reflects *real acquisition*
/// (accuracy, mastered items, active vocabulary) — deliberately no streak/XP.
struct MetricsDashboardView: View {
    @Environment(LearningStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Real bilik göstəriciləri")
                .font(.headline)

            HStack(spacing: 12) {
                MetricTile(
                    value: "\(Int(store.recallAccuracy * 100))%",
                    label: "Xatırlama dəqiqliyi",
                    system: "target",
                    tint: .green
                )
                MetricTile(
                    value: "\(store.masteredCount)",
                    label: "Möhkəm bilinən",
                    system: "checkmark.seal.fill",
                    tint: .blue
                )
            }
            HStack(spacing: 12) {
                MetricTile(
                    value: "~\(store.estimatedKnownFamilies)",
                    label: "Söz ailəsi (təxmini)",
                    system: "text.word.spacing",
                    tint: .purple
                )
                MetricTile(
                    value: "\(store.dueItems.count)",
                    label: "Təkrara hazır",
                    system: "clock.arrow.circlepath",
                    tint: .orange
                )
            }

            if let passage = store.recommendedPassage {
                let cov = CoverageEngine.coverage(of: passage.text, known: store.knownWords)
                HStack(spacing: 6) {
                    Image(systemName: "book.pages")
                        .foregroundStyle(.teal)
                    Text("Oxu səviyyəsi: \(Int(cov * 100))% coverage")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("· ~3000 söz = 95% (Nation 2006)")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }

            Text("Streak və XP qəsdən yoxdur — bunlar bilik yox, vərdiş ölçür.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct MetricTile: View {
    let value: String
    let label: String
    let system: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: system)
                .foregroundStyle(tint)
            Text(value)
                .font(.title.bold())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Stage 4 — Review (Nəticə). Closes the loop: shows the updated real metrics,
/// then advances the virtual clock so spaced intervals can come due again.
struct SessionReviewView: View {
    @Environment(LearningStore.self) private var store
    @Bindable var session: SessionViewModel
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .padding(.top, 24)

                Text("Döngə tamamlandı")
                    .font(.title2.bold())

                MetricsDashboardView()

                VStack(spacing: 12) {
                    Button {
                        store.advanceOneDay()
                        onFinish()
                    } label: {
                        Label("Növbəti günə keç (interval simulyasiyası)", systemImage: "sun.max.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Ana səhifəyə qayıt", action: onFinish)
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}
