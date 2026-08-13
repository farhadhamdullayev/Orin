import SwiftUI

/// A timed, sectioned mock exam — genuinely new relative to the web app
/// (which only has a planning/routing dashboard here, no real test; verified
/// this session by reading its ExamPlan() function in full). Draws real,
/// already-vetted content from three sources rather than inventing new exam
/// questions: PLACEMENT_BANK (vocabulary), GRAMMAR (grammar), LISTENING
/// (listening) — the same pools the rest of the app already uses.
enum MockTestSection: String, CaseIterable, Identifiable {
    case vocabulary, grammar, listening
    var id: String { rawValue }

    var title: String {
        switch self {
        case .vocabulary: return "Lüğət"
        case .grammar: return "Qrammatika"
        case .listening: return "Dinləmə"
        }
    }
    var icon: String {
        switch self {
        case .vocabulary: return "textformat"
        case .grammar: return "textformat.abc"
        case .listening: return "ear"
        }
    }
}

struct MockTestQuestion: Identifiable {
    let id: String
    let section: MockTestSection
    let prompt: String
    let audioText: String?
    let options: [String]
    let correctAnswer: String
}

enum MockTestLength: Int, CaseIterable, Identifiable {
    case short = 15, medium = 30, full = 60
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .short:  return "Qısa — 15 sual (~5 dəq)"
        case .medium: return "Orta — 30 sual (~10 dəq)"
        case .full:   return "Tam — 60 sual (~20 dəq)"
        }
    }
    /// Questions per section — always split evenly across the 3 sections.
    var perSection: Int { rawValue / 3 }
    /// ~20 seconds/question, matching typical MCQ exam pacing.
    var totalSeconds: Int { rawValue * 20 }
}

/// Entry point: pick a length, then run the timed test.
struct MockTestView: View {
    @Environment(ContentStore.self) private var contentStore
    @State private var runningQuestions: [MockTestQuestion]?

    var body: some View {
        if let runningQuestions {
            MockTestRunnerView(questions: runningQuestions) {
                self.runningQuestions = nil
            }
        } else {
            introView
        }
    }

    private var introView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("📋").font(.system(size: 44))
                Text("Sınaq İmtahanı").font(.title3.bold())
                Text("3 bölmə (Lüğət, Qrammatika, Dinləmə), taymerlə. Nəticə hər bölmə üzrə ayrıca göstərilir.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    ForEach(MockTestLength.allCases) { length in
                        Button {
                            runningQuestions = buildQuestions(length: length)
                        } label: {
                            Text(length.label)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Sınaq İmtahanı")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func buildQuestions(length: MockTestLength) -> [MockTestQuestion] {
        let n = length.perSection

        let vocab = contentStore.placementBank.shuffled().prefix(n).map {
            MockTestQuestion(id: $0.id, section: .vocabulary, prompt: $0.word, audioText: nil, options: $0.options, correctAnswer: $0.correctAnswer)
        }

        let allDrills = contentStore.grammar.flatMap(\.drills)
        let grammar = allDrills.shuffled().prefix(n).map {
            MockTestQuestion(id: $0.id, section: .grammar, prompt: $0.question, audioText: nil, options: $0.options, correctAnswer: $0.options[$0.correctIndex])
        }

        let allListenItems = contentStore.listening.flatMap(\.items)
        let listening = allListenItems.shuffled().prefix(n).map {
            MockTestQuestion(id: $0.id, section: .listening, prompt: $0.question, audioText: $0.english, options: $0.options, correctAnswer: $0.correctAnswer)
        }

        return Array(vocab) + Array(grammar) + Array(listening)
    }
}

/// Runs the timed test: one question at a time, answer selectable/changeable
/// (no immediate right/wrong reveal — real exams don't grade per-question),
/// explicit "Növbəti"/"Keç" navigation, countdown timer auto-submits at zero.
private struct MockTestRunnerView: View {
    let questions: [MockTestQuestion]
    let onFinish: () -> Void

    @State private var index = 0
    @State private var picks: [String?]
    @State private var secondsLeft: Int
    @State private var finished = false

    init(questions: [MockTestQuestion], onFinish: @escaping () -> Void) {
        self.questions = questions
        self.onFinish = onFinish
        _picks = State(initialValue: Array(repeating: nil, count: questions.count))
        _secondsLeft = State(initialValue: max(questions.count, 1) * 20)
    }

    var body: some View {
        Group {
            if finished {
                MockTestResultView(questions: questions, picks: picks, onDone: onFinish)
            } else if index < questions.count {
                questionView(questions[index])
            } else {
                Color.clear.onAppear { finished = true }
            }
        }
        // Attached once at this stable position (not inside `questionView`,
        // which is re-invoked per question) — a single countdown for the
        // whole test. `.task` only (re)starts if its identity changes, and
        // is auto-cancelled when the view goes away, unlike a Combine
        // `Timer.publish(...).autoconnect()` recreated on every re-render
        // (which would stack up multiple overlapping timers).
        .task {
            while !finished {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                if secondsLeft > 0 { secondsLeft -= 1 } else { finished = true }
            }
        }
    }

    private func questionView(_ q: MockTestQuestion) -> some View {
        VStack(spacing: 20) {
            HStack {
                Label(q.section.title, systemImage: q.section.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(timeString)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(secondsLeft <= 30 ? .red : .secondary)
            }
            ProgressView(value: Double(index), total: Double(questions.count))

            Spacer()

            if let audioText = q.audioText {
                Button {
                    Speaker.shared.speak(audioText)
                } label: {
                    Label("Dinlə", systemImage: "speaker.wave.2.fill")
                        .font(.title3)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 4)
            }

            Text(q.prompt)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(q.options, id: \.self) { opt in
                    Button {
                        picks[index] = opt
                    } label: {
                        Text(opt)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .tint(picks[index] == opt ? .accentColor : .primary)
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Text("\(index + 1) / \(questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(picks[index] == nil ? "Keç" : "Növbəti") { advance() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            if let audioText = q.audioText { Speaker.shared.speak(audioText) }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var timeString: String {
        let m = secondsLeft / 60, s = secondsLeft % 60
        return String(format: "%d:%02d", m, s)
    }

    private func advance() {
        if index < questions.count - 1 { index += 1 }
        else { finished = true }
    }
}

private struct MockTestResultView: View {
    let questions: [MockTestQuestion]
    let picks: [String?]
    let onDone: () -> Void

    private struct SectionScore { let correct: Int; let total: Int }

    private var scores: [MockTestSection: SectionScore] {
        var result: [MockTestSection: SectionScore] = [:]
        for section in MockTestSection.allCases {
            let indices = questions.indices.filter { questions[$0].section == section }
            let correct = indices.filter { picks[$0] == questions[$0].correctAnswer }.count
            result[section] = SectionScore(correct: correct, total: indices.count)
        }
        return result
    }
    private var totalCorrect: Int { scores.values.reduce(0) { $0 + $1.correct } }
    private var totalCount: Int { questions.count }
    private var percentage: Int { totalCount == 0 ? 0 : Int((Double(totalCorrect) / Double(totalCount) * 100).rounded()) }

    /// A rough, honestly-labeled band estimate — not a certified score.
    private var estimatedBand: String {
        switch percentage {
        case 90...:   return "C1-C2"
        case 75..<90: return "B2"
        case 55..<75: return "B1"
        case 35..<55: return "A2"
        default:      return "A1"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🏁").font(.system(size: 44))
                Text("\(percentage)%").font(.system(size: 48, weight: .bold))
                Text("Təxmini səviyyə: \(estimatedBand)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    ForEach(MockTestSection.allCases) { section in
                        let score = scores[section] ?? SectionScore(correct: 0, total: 0)
                        HStack {
                            Label(section.title, systemImage: section.icon)
                            Spacer()
                            Text("\(score.correct) / \(score.total)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                Text("⚠️ Bu, rəsmi IELTS/TOEFL balı deyil — daxili söz/qrammatika/dinləmə bankından təxmini göstəricidir.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button("Bitir") { onDone() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("Nəticə")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}
