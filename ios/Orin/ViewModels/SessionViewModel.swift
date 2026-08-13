import Foundation
import Observation

/// The four stages of the core loop, in order.
enum LoopStage: Int, CaseIterable {
    case input, retrieval, output, review

    var title: String {
        switch self {
        case .input:     return "Anla"          // Understand (comprehensible input)
        case .retrieval: return "Xatırla"       // Recall (retrieval practice)
        case .output:    return "Danış"         // Produce (output + pronunciation)
        case .review:    return "Nəticə"        // Real-acquisition metrics
        }
    }

    var systemImage: String {
        switch self {
        case .input:     return "text.book.closed"
        case .retrieval: return "brain.head.profile"
        case .output:    return "waveform"
        case .review:    return "chart.line.uptrend.xyaxis"
        }
    }
}

/// Drives one pass through the loop over a fixed batch of items.
@Observable
final class SessionViewModel {
    let store: LearningStore
    let batch: [LearningItem]

    var stage: LoopStage = .input

    /// `awlOnly`: restricts the batch to Academic Word List items, for the
    /// dedicated AWL practice track — same loop, same schedule, just a
    /// filtered source deck.
    init(store: LearningStore, batchSize: Int = 4, awlOnly: Bool = false) {
        self.store = store
        // Prioritise due items, then fill with new ones — spaced review first.
        let due = awlOnly ? store.awlDueItems : store.dueItems
        let fresh = (awlOnly ? store.awlNewItems : store.newItems)
            .filter { item in !due.contains(where: { $0.id == item.id }) }
        self.batch = Array((due + fresh).prefix(batchSize))
    }

    func advanceStage() {
        let next = LoopStage(rawValue: stage.rawValue + 1)
        if let next { stage = next }
    }

    var isLastStage: Bool { stage == .review }
}
