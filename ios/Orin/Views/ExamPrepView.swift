import SwiftUI

/// Exam-prep is a *routing* feature, not new content — the web app's
/// version is a plan/dashboard that points at existing modules based on a
/// stated goal, not a separate exam question bank. This mirrors that: set
/// a target, get a short recommendation, jump into the modules that matter.
struct ExamPrepView: View {
    @Environment(LearningStore.self) private var store
    @State private var examType = ""
    @State private var examTarget = ""

    private static let examTypes = ["IELTS", "TOEFL", "Digər"]

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    MockTestView()
                } label: {
                    Label("Sınaq İmtahanına başla", systemImage: "flag.checkered")
                        .font(.headline)
                }
            }

            Section("Hədəf") {
                Picker("İmtahan", selection: $examType) {
                    Text("Seçilməyib").tag("")
                    ForEach(Self.examTypes, id: \.self) { Text($0).tag($0) }
                }
                TextField("Hədəf bal (məs. 6.5, ya 90)", text: $examTarget)
                    .keyboardType(.decimalPad)
                Button("Yadda saxla") {
                    store.setExamGoal(type: examType, target: examTarget)
                }
                .disabled(examType == store.examType && examTarget == store.examTarget)
            }

            if !store.examType.isEmpty {
                Section("Tövsiyə olunan plan") {
                    recommendationRow(
                        icon: "book.fill", tint: .blue,
                        text: "Gündəlik lüğət sessiyası — geniş söz bazası hər imtahanın əsasıdır"
                    )
                    recommendationRow(
                        icon: "graduationcap.fill", tint: .purple,
                        text: "AWL (Akademik Söz Siyahısı) — \(store.examType) mətnlərində tez-tez rast gəlinir"
                    )
                    recommendationRow(
                        icon: "text.book.closed.fill", tint: .teal,
                        text: "Oxu təcrübəsi — Məşq tab-ında oxu bölməsi, əhatə faizinə görə sıralanıb"
                    )
                    recommendationRow(
                        icon: "pencil.line", tint: .orange,
                        text: "Yazı məşqi — struktur/söz sayı geri-bildirimi ilə mütəmadi yaz"
                    )
                }
            }
        }
        .navigationTitle("İmtahan hazırlığı")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            examType = store.examType
            examTarget = store.examTarget
        }
    }

    private func recommendationRow(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 20)
            Text(text).font(.subheadline)
        }
    }
}
