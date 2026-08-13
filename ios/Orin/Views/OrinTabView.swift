import SwiftUI

/// Root navigation shell — replaces the single linear demo flow with a
/// module hub. New modules (Grammar/Listening/Visual/Reading/Writing) get
/// their own tab only once built (Phase 2+); no placeholder tabs in V1.
struct OrinTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem { Label("Öyrən", systemImage: "book.fill") }

            NavigationStack {
                PracticeHubView()
            }
            .tabItem { Label("Məşq", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                ScrollView {
                    MetricsDashboardView()
                        .padding(.top)
                }
                .navigationTitle("İrəliləyiş")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("İrəliləyiş", systemImage: "chart.bar.fill") }

            NavigationStack {
                SocialHubView()
            }
            .tabItem { Label("Sosial", systemImage: "person.2.fill") }

            NavigationStack {
                SettingsView()
                    .navigationTitle("Ayarlar")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }
        }
    }
}
