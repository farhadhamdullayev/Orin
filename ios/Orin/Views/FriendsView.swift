import SwiftUI

struct FriendsView: View {
    @Environment(LearningStore.self) private var store
    @State private var friends: [FriendEntry] = []
    @State private var myInviteCode: String?
    @State private var codeInput = ""
    @State private var statusMessage: String?
    @State private var isLoading = false

    private var client: APIClient { APIClient(baseURLString: store.serverBaseURL) }

    var body: some View {
        List {
            Section("Mənim dəvət kodum") {
                if let myInviteCode {
                    HStack {
                        Text(myInviteCode).font(.title3.monospaced().bold())
                        Spacer()
                    }
                } else {
                    Text("Yüklənir…").foregroundStyle(.secondary)
                }
            }

            Section("Dost əlavə et") {
                HStack {
                    TextField("Dəvət kodu", text: $codeInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button("Əlavə et") {
                        Task { await addFriend() }
                    }
                    .disabled(codeInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if let statusMessage {
                    Text(statusMessage).font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Dostlarım (\(friends.count))") {
                if friends.isEmpty && !isLoading {
                    Text("Hələ dostunuz yoxdur").foregroundStyle(.secondary)
                }
                ForEach(friends) { friend in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(friend.displayName).font(.body)
                            Spacer()
                            Text("\(friend.points) xal").font(.caption).foregroundStyle(.secondary)
                        }
                        if friend.todayPoints > 0 || friend.todayMastered > 0 {
                            Text("Bu gün: \(friend.todayPoints) xal, \(friend.todayMastered) söz mənimsədi")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle("Dostlar")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadAll() }
        .refreshable { await loadAll() }
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        async let meTask = try? client.leaderboardMe(deviceId: store.deviceId)
        async let friendsTask = try? client.friendsList(deviceId: store.deviceId)
        myInviteCode = await meTask?.inviteCode
        friends = await friendsTask?.friends ?? []
    }

    private func addFriend() async {
        do {
            let response = try await client.friendsAdd(deviceId: store.deviceId, inviteCode: codeInput.trimmingCharacters(in: .whitespaces))
            statusMessage = "\(response.friendName) dostlarınıza əlavə olundu"
            codeInput = ""
            await loadAll()
        } catch {
            statusMessage = "Xəta: \(error.localizedDescription)"
        }
    }
}
