import SwiftUI

/// "Sosial" tab — Duel/Friends/Leaderboard, all backed by `Orin/server/`
/// (FastAPI, already built and tested locally). Gated on
/// `store.serverBaseURL` being set (Settings → Server) since no VPS/domain
/// exists yet at this phase — shows a clear setup prompt instead of
/// crashing or silently failing when unconfigured.
struct SocialHubView: View {
    @Environment(LearningStore.self) private var store

    var body: some View {
        Group {
            if store.serverBaseURL.isEmpty {
                notConfiguredView
            } else {
                configuredHub
            }
        }
        .navigationTitle("Sosial")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var notConfiguredView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "server.rack").font(.system(size: 40)).foregroundStyle(.secondary)
                Text("Server qurulmayıb").font(.title3.bold())
                Text("Duel, Dostlar və Lider-bord bu cihazın internetdən çatdığı bir server tələb edir. Ayarlar → Server-də ünvanı təyin edin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                NavigationLink {
                    SettingsView()
                } label: {
                    Text("Ayarlara keç").frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var configuredHub: some View {
        List {
            Section {
                NavigationLink {
                    DuelView()
                } label: {
                    Label("Duel", systemImage: "bolt.fill")
                }
                NavigationLink {
                    FriendsView()
                } label: {
                    Label("Dostlar", systemImage: "person.2.fill")
                }
                NavigationLink {
                    LeaderboardView()
                } label: {
                    Label("Lider bord", systemImage: "trophy.fill")
                }
            }
        }
    }
}
