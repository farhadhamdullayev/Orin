import Foundation

enum APIError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case server(status: Int, message: String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Server ünvanı təyin edilməyib (Ayarlar → Server)."
        case .invalidURL: return "Yanlış server ünvanı."
        case .server(let status, let message): return "Server xətası (\(status)): \(message)"
        case .decoding: return "Serverdən gələn cavab oxunmadı."
        }
    }
}

/// Thin async/await wrapper over `Orin/server/main.py`'s JSON API. The base
/// URL is user-configured (Settings → Server) since there's no VPS/domain
/// baked in yet — every call throws `.notConfigured` cleanly until then,
/// which callers turn into a friendly "server not set up" state rather than
/// a crash (mirrors the web client's own `apiCall()` offline-friendly wrapper).
struct APIClient {
    let baseURLString: String

    private func request<T: Decodable>(_ path: String, method: String = "GET", jsonBody: Data? = nil, as type: T.Type) async throws -> T {
        guard !baseURLString.isEmpty else { throw APIError.notConfigured }
        guard let url = URL(string: baseURLString.trimmingCharacters(in: .init(charactersIn: "/")) + path) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let jsonBody {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = jsonBody
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }
        guard (200...299).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "HTTP \(http.statusCode)"
            throw APIError.server(status: http.statusCode, message: message)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func post<Body: Encodable, T: Decodable>(_ path: String, _ body: Body, as type: T.Type) async throws -> T {
        try await request(path, method: "POST", jsonBody: try JSONEncoder().encode(body), as: type)
    }

    // MARK: Request bodies (mirrors main.py's Pydantic models field-for-field)

    private struct RegisterBody: Encodable { let device_id: String; let display_name: String }
    private struct DuelJoinBody: Encodable { let device_id: String; let mode: String; let band: String; let friend_id: String? }
    private struct DuelAnswerBody: Encodable { let device_id: String; let qid: String; let chosen: String }
    private struct DeviceIdBody: Encodable { let device_id: String }
    private struct FriendAddBody: Encodable { let device_id: String; let invite_code: String }
    private struct ActivitySyncBody: Encodable {
        let device_id: String; let due_count: Int; let today_points: Int; let today_mastered: Int; let lang: String
    }

    func register(deviceId: String, displayName: String) async throws -> RegisterResponse {
        try await post("/api/register", RegisterBody(device_id: deviceId, display_name: displayName), as: RegisterResponse.self)
    }

    func duelJoin(deviceId: String, mode: String, band: String, friendId: String? = nil) async throws -> DuelJoinResponse {
        try await post("/api/duel/join", DuelJoinBody(device_id: deviceId, mode: mode, band: band, friend_id: friendId), as: DuelJoinResponse.self)
    }

    func duelAnswer(duelId: String, deviceId: String, qid: String, chosen: String) async throws -> DuelAnswerResponse {
        try await post("/api/duel/\(duelId)/answer", DuelAnswerBody(device_id: deviceId, qid: qid, chosen: chosen), as: DuelAnswerResponse.self)
    }

    func duelFinish(duelId: String, deviceId: String) async throws -> DuelFinishResponse {
        try await post("/api/duel/\(duelId)/finish", DeviceIdBody(device_id: deviceId), as: DuelFinishResponse.self)
    }

    func duelStatus(duelId: String, deviceId: String) async throws -> DuelStatusResponse {
        try await request("/api/duel/\(duelId)/status?device_id=\(deviceId)", as: DuelStatusResponse.self)
    }

    func duelPending(deviceId: String) async throws -> DuelPendingResponse {
        try await request("/api/duel/pending?device_id=\(deviceId)", as: DuelPendingResponse.self)
    }

    func leaderboard(band: String? = nil, period: String = "all") async throws -> LeaderboardResponse {
        var path = "/api/leaderboard?period=\(period)"
        if let band { path += "&band=\(band)" }
        return try await request(path, as: LeaderboardResponse.self)
    }

    func leaderboardMe(deviceId: String, period: String = "all") async throws -> LeaderboardMeResponse {
        try await request("/api/leaderboard/me?device_id=\(deviceId)&period=\(period)", as: LeaderboardMeResponse.self)
    }

    func friendsAdd(deviceId: String, inviteCode: String) async throws -> FriendAddResponse {
        try await post("/api/friends/add", FriendAddBody(device_id: deviceId, invite_code: inviteCode), as: FriendAddResponse.self)
    }

    func friendsList(deviceId: String) async throws -> FriendsResponse {
        try await request("/api/friends?device_id=\(deviceId)", as: FriendsResponse.self)
    }

    func activitySync(deviceId: String, dueCount: Int, todayPoints: Int, todayMastered: Int, lang: String) async throws {
        struct Empty: Decodable {}
        _ = try await post(
            "/api/activity/sync",
            ActivitySyncBody(device_id: deviceId, due_count: dueCount, today_points: todayPoints, today_mastered: todayMastered, lang: lang),
            as: Empty.self
        )
    }
}
