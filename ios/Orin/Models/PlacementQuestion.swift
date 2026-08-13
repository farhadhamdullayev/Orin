import Foundation

/// A vocabulary MCQ question — decoded from `placement_bank.json` (the web
/// app's PLACEMENT_BANK, originally used internally for level placement).
/// Feeds the native Mock Test's vocabulary section.
struct PlacementQuestion: Identifiable, Codable, Equatable {
    let id: String
    let word: String
    let band: Int
    let correctAnswer: String
    let options: [String]
}

extension ContentStore {
    static func loadPlacementBank() -> [PlacementQuestion] {
        ContentStore.loadJSON("placement_bank", as: [PlacementQuestion].self) ?? []
    }
}
