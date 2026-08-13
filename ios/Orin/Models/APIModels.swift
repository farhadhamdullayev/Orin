import Foundation

/// Request/response shapes for `Orin/server/main.py`'s JSON API. Field names
/// match the backend's snake_case exactly via `CodingKeys` where needed —
/// this file has no logic, just the wire format.

// MARK: Duel

struct DuelQuestionDTO: Codable, Identifiable {
    let qid: String
    let type: String // "word" | "grammar"
    let promptItemId: String?   // word only — resolve via ContentStore.vocab
    let options: [String]       // word: item ids; grammar: literal answer strings
    let question: String?       // grammar only
    var id: String { qid }

    enum CodingKeys: String, CodingKey {
        case qid, type, options, question
        case promptItemId = "prompt_item_id"
    }
}

struct DuelJoinResponse: Codable {
    let duelId: String
    let role: String // "waiting" | "matched"
    let opponentName: String?
    let questions: [DuelQuestionDTO]

    enum CodingKeys: String, CodingKey {
        case duelId = "duel_id", role, questions
        case opponentName = "opponent_name"
    }
}

struct DuelAnswerResponse: Codable {
    let ok: Bool
    let correct: Bool
    let points: Int
}

struct DuelFinishResponse: Codable {
    let ok: Bool
    let myScore: Int
    let done: Bool
    let opponentFinished: Bool

    enum CodingKeys: String, CodingKey {
        case ok, done
        case myScore = "my_score"
        case opponentFinished = "opponent_finished"
    }
}

struct DuelStatusResponse: Codable {
    let status: String
    let opponentName: String?
    let myScore: Int
    let iFinished: Bool
    let opponentFinished: Bool
    let opponentScore: Int?
    let winner: String? // "me" | "opponent" | "draw"

    enum CodingKeys: String, CodingKey {
        case status, winner
        case opponentName = "opponent_name"
        case myScore = "my_score"
        case iFinished = "i_finished"
        case opponentFinished = "opponent_finished"
        case opponentScore = "opponent_score"
    }
}

struct DuelPendingEntry: Codable, Identifiable {
    let duelId: String
    let mode: String
    let band: String
    let fromDeviceId: String
    let fromName: String
    var id: String { duelId }

    enum CodingKeys: String, CodingKey {
        case duelId = "duel_id", mode, band
        case fromDeviceId = "from_device_id"
        case fromName = "from_name"
    }
}

struct DuelPendingResponse: Codable {
    let pending: [DuelPendingEntry]
}

// MARK: Leaderboard

struct LeaderboardEntry: Codable, Identifiable {
    let displayName: String
    let points: Int
    let wins: Int
    let losses: Int
    let draws: Int
    var id: String { displayName + String(points) }

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name", points, wins, losses, draws
    }
}

struct LeaderboardResponse: Codable {
    let entries: [LeaderboardEntry]
    let period: String
}

struct LeaderboardMeResponse: Codable {
    let displayName: String
    let points: Int
    let wins: Int
    let losses: Int
    let draws: Int
    let currentBand: String?
    let globalRank: Int
    let bandRank: Int
    let inviteCode: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name", points, wins, losses, draws
        case currentBand = "current_band"
        case globalRank = "global_rank"
        case bandRank = "band_rank"
        case inviteCode = "invite_code"
    }
}

// MARK: Friends

struct FriendEntry: Codable, Identifiable {
    let deviceId: String
    let displayName: String
    let currentBand: String?
    let points: Int
    let todayPoints: Int
    let todayMastered: Int
    var id: String { deviceId }

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case displayName = "display_name"
        case currentBand = "current_band"
        case points
        case todayPoints = "today_points"
        case todayMastered = "today_mastered"
    }
}

struct FriendsResponse: Codable {
    let friends: [FriendEntry]
}

struct FriendAddResponse: Codable {
    let ok: Bool
    let friendName: String

    enum CodingKeys: String, CodingKey {
        case ok
        case friendName = "friend_name"
    }
}

struct RegisterResponse: Codable {
    let ok: Bool
    let inviteCode: String

    enum CodingKeys: String, CodingKey {
        case ok
        case inviteCode = "invite_code"
    }
}
