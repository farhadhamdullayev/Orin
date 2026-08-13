import SwiftUI

/// Turn-based/async duel (see `docs/02-SOCIAL.md` §3 and `server/main.py`'s
/// module docstring for the anti-cheat design) — NOT real-time. Once matched
/// (or while waiting for an opponent), the player answers their own 10
/// questions at their own pace; the server computes the authoritative score
/// and only reveals the opponent's result once both sides have finished.
struct DuelView: View {
    @Environment(LearningStore.self) private var store
    @Environment(ContentStore.self) private var contentStore
    @State private var mode = "word"
    @State private var band: String
    @State private var phase: Phase = .setup
    @State private var errorMessage: String?

    private static let bands = ["Pre-A1", "A1", "A2", "B1", "B2", "C1", "C2"]

    enum Phase {
        case setup
        case playing(duelId: String, questions: [DuelQuestionDTO], index: Int, myScore: Int)
        case finished(myScore: Int, done: Bool, opponentFinished: Bool)
    }

    init() {
        _band = State(initialValue: "A1")
    }

    var body: some View {
        Group {
            switch phase {
            case .setup: setupView
            case .playing(let duelId, let questions, let index, let myScore):
                playingView(duelId: duelId, questions: questions, index: index, myScore: myScore)
            case .finished(let myScore, let done, let opponentFinished):
                finishedView(myScore: myScore, done: done, opponentFinished: opponentFinished)
            }
        }
        .navigationTitle("Duel")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { band = store.estimatedBand }
    }

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("⚔️").font(.system(size: 44))
                Picker("Rejim", selection: $mode) {
                    Text("Söz").tag("word")
                    Text("Qrammatika").tag("grammar")
                }
                .pickerStyle(.segmented)

                Picker("Səviyyə bandı", selection: $band) {
                    ForEach(Self.bands, id: \.self) { Text($0).tag($0) }
                }

                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }

                Button {
                    Task { await startDuel() }
                } label: {
                    Text("Rəqib axtar").frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)

                Text("Asinxron duel: rəqibiniz sizinlə eyni anda olmaya bilər — hər ikiniz öz sürətinizlə cavablandırırsınız, nəticə hər ikiniz bitirdikdən sonra açılır.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private func startDuel() async {
        errorMessage = nil
        do {
            let client = APIClient(baseURLString: store.serverBaseURL)
            let response = try await client.duelJoin(deviceId: store.deviceId, mode: mode, band: band)
            phase = .playing(duelId: response.duelId, questions: response.questions, index: 0, myScore: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func playingView(duelId: String, questions: [DuelQuestionDTO], index: Int, myScore: Int) -> some View {
        DuelQuestionView(
            question: questions[index],
            contentStore: contentStore,
            index: index,
            total: questions.count
        ) { chosen in
            Task { await submitAnswer(duelId: duelId, questions: questions, index: index, myScore: myScore, chosen: chosen) }
        }
    }

    private func submitAnswer(duelId: String, questions: [DuelQuestionDTO], index: Int, myScore: Int, chosen: String) async {
        let client = APIClient(baseURLString: store.serverBaseURL)
        let question = questions[index]
        let newScore: Int
        do {
            let response = try await client.duelAnswer(duelId: duelId, deviceId: store.deviceId, qid: question.qid, chosen: chosen)
            newScore = myScore + response.points
        } catch {
            errorMessage = error.localizedDescription
            newScore = myScore
        }
        if index < questions.count - 1 {
            phase = .playing(duelId: duelId, questions: questions, index: index + 1, myScore: newScore)
        } else {
            do {
                let finish = try await client.duelFinish(duelId: duelId, deviceId: store.deviceId)
                phase = .finished(myScore: finish.myScore, done: finish.done, opponentFinished: finish.opponentFinished)
            } catch {
                errorMessage = error.localizedDescription
                phase = .finished(myScore: newScore, done: false, opponentFinished: false)
            }
        }
    }

    private func finishedView(myScore: Int, done: Bool, opponentFinished: Bool) -> some View {
        VStack(spacing: 20) {
            Image(systemName: done ? "flag.checkered.circle.fill" : "hourglass")
                .font(.system(size: 48))
                .foregroundStyle(done ? .green : .orange)
            Text("Sizin xalınız: \(myScore)").font(.title2.bold())
            if done {
                Text("Rəqib də bitirdi — nəticəni Lider bord/Dostlar bölməsində görə bilərsiniz.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(opponentFinished ? "Rəqib artıq bitirib, nəticə hesablanır." : "Rəqib hələ bitirməyib — daha sonra yoxlayın.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Yeni duel") { phase = .setup }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

/// Renders one duel question — word (resolve `promptItemId`'s gloss as the
/// cue, options are item ids resolved to their English target words) or
/// grammar (literal question/options straight from the server).
private struct DuelQuestionView: View {
    let question: DuelQuestionDTO
    let contentStore: ContentStore
    let index: Int
    let total: Int
    let onAnswer: (String) -> Void

    @Environment(LocalizationStore.self) private var localization
    @State private var selected: String?

    private var promptItem: VocabItem? {
        guard let id = question.promptItemId else { return nil }
        return contentStore.vocab.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Group {
                if question.type == "word", let promptItem {
                    Text(localization.text(promptItem.gloss, fallback: promptItem.target))
                        .font(.title2.bold())
                } else {
                    Text(question.question ?? "")
                        .font(.title3.weight(.medium))
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        selected = option
                        onAnswer(option)
                    } label: {
                        Text(optionLabel(option))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .disabled(selected != nil)
                }
            }
            .padding(.horizontal)

            Spacer()
            Text("\(index + 1) / \(total)").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.bottom)
        .onChange(of: question.qid) { _, _ in selected = nil }
    }

    private func optionLabel(_ option: String) -> String {
        guard question.type == "word" else { return option }
        return contentStore.vocab.first { $0.id == option }?.target ?? option
    }
}
