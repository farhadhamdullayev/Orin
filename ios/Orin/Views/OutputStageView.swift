import SwiftUI

/// Stage 3 — Output (Danış). The gap Duolingo leaves open: real production.
/// The learner shadows the sentence aloud; on-device ASR gives an *approximate*
/// closeness signal (honestly framed), not a hard pronunciation score.
struct OutputStageView: View {
    @Bindable var session: SessionViewModel
    @State private var index = 0
    @State private var recognizer = SpeechRecognizer()
    @State private var permissionGranted: Bool?

    private var item: LearningItem { session.batch[index] }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Səsli təkrarla (shadowing)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.exampleTarget)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Button {
                    Speaker.shared.speak(item.exampleTarget)
                } label: {
                    Label("Model səsi dinlə", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)

            micSection

            Spacer()

            HStack {
                Text("\(index + 1) / \(session.batch.count)")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(isLast ? "Nəticəyə keç" : "Növbəti") {
                    recognizer.stop()
                    if isLast { session.advanceStage() }
                    else { withAnimation { index += 1 } }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .task {
            if permissionGranted == nil {
                permissionGranted = await recognizer.requestPermission()
            }
        }
        .onDisappear { recognizer.stop() }
    }

    @ViewBuilder
    private var micSection: some View {
        switch recognizer.state {
        case .idle:
            recordButton(title: "Danış", listening: false)
        case .listening:
            recordButton(title: "Dinləyirəm… (dayandır)", listening: true)
        case .result(let transcript):
            VStack(spacing: 10) {
                let score = SpeechRecognizer.closeness(target: item.exampleTarget, heard: transcript)
                Text("Eşitdim: \(transcript)")
                    .font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                ProgressView(value: score)
                    .tint(score > 0.7 ? .green : .orange)
                    .padding(.horizontal, 40)
                // Honest framing (strategy §1.5): on-device recognition does
                // transcription only — this is a "were your words understood"
                // signal, NOT a pronunciation-quality grade. Automated stress/
                // intonation scoring is unreliable, so we don't claim it.
                Text("Sözlərin \(Int(score * 100))%-i tanındı — başa düşülmə göstəricisi (tələffüz balı deyil, yalnız istiqamət)")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                recordButton(title: "Yenidən danış", listening: false)
            }
        case .unavailable(let reason):
            VStack(spacing: 8) {
                Image(systemName: "mic.slash").font(.title)
                Text(reason).font(.caption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("(Simulyatorda mikrofon olmaya bilər — real cihazda işləyir.)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            .padding()
        }
    }

    private func recordButton(title: String, listening: Bool) -> some View {
        Button {
            if listening { recognizer.stop() } else { recognizer.start() }
        } label: {
            Label(title, systemImage: listening ? "stop.circle.fill" : "mic.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(listening ? .red : .accentColor)
        .padding(.horizontal)
        .disabled(permissionGranted == false)
    }

    private var isLast: Bool { index == session.batch.count - 1 }
}
