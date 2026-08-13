import SwiftUI

struct LeaderboardView: View {
    @Environment(LearningStore.self) private var store
    @State private var period = "all"
    @State private var entries: [LeaderboardEntry] = []
    @State private var myStats: LeaderboardMeResponse?
    @State private var errorMessage: String?

    private var client: APIClient { APIClient(baseURLString: store.serverBaseURL) }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Dövr", selection: $period) {
                Text("Bütün vaxt").tag("all")
                Text("Bu ay").tag("month")
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: period) { _, _ in Task { await load() } }

            if let myStats {
                HStack {
                    VStack(alignment: .leading) {
                        Text(myStats.displayName).font(.headline)
                        Text("Qlobal: #\(myStats.globalRank) · \(myStats.currentBand ?? "—"): #\(myStats.bandRank)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(myStats.points) xal").font(.title3.bold())
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.secondary).padding()
            }

            List(Array(entries.enumerated()), id: \.offset) { i, entry in
                HStack {
                    Text("\(i + 1)").font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 28)
                    Text(entry.displayName)
                    Spacer()
                    Text("\(entry.points)").font(.subheadline.monospacedDigit().bold())
                }
            }
        }
        .navigationTitle("Lider bord")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            async let lb = try client.leaderboard(period: period)
            async let me = try? client.leaderboardMe(deviceId: store.deviceId, period: period)
            entries = try await lb.entries
            myStats = await me
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
