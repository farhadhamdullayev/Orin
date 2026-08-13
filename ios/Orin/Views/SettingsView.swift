import SwiftUI

/// UI-language picker (switches which language `LocalizationStore` resolves
/// glosses into, live — no relaunch needed) and a personal learning-goal
/// note, persisted via `LearningStore`/`UserProfile`.
struct SettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(LocalizationStore.self) private var localization
    @State private var goalDraft: String = ""
    @State private var serverURLDraft: String = ""
    @State private var displayNameDraft: String = ""
    @State private var registerStatus: String?

    var body: some View {
        Form {
            Section("Lüğət dili") {
                Picker("Dil", selection: Binding(
                    get: { localization.currentLang },
                    set: { newValue in
                        localization.currentLang = newValue
                        store.setUILanguage(newValue)
                    }
                )) {
                    ForEach(LocalizationStore.supportedVocabLanguages, id: \.self) { code in
                        Text(Self.languageName(for: code)).tag(code)
                    }
                }
            }

            Section("Hədəfiniz") {
                TextField("Niyə ingilis öyrənirsiniz?", text: $goalDraft, axis: .vertical)
                    .lineLimit(2...4)
                Button("Yadda saxla") {
                    store.setLearningGoal(goalDraft)
                }
                .disabled(goalDraft == store.learningGoal)
            }

            Section {
                TextField("https://api.sizin-domeniniz.com", text: $serverURLDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                TextField("Görünən adınız", text: $displayNameDraft)
                Button("Yadda saxla və qeydiyyatdan keç") {
                    saveServerSettings()
                }
                .disabled(serverURLDraft.isEmpty || displayNameDraft.isEmpty)
                if let registerStatus {
                    Text(registerStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Server (Duel/Dostlar/Lider-bord)")
            } footer: {
                Text("VPS deploy olunduqdan sonra buraya ünvanı yazın (məs. https://api.orinapp.com). Boş qalarsa Sosial tab-ı deaktiv görünür.")
            }
        }
        .onAppear {
            goalDraft = store.learningGoal
            serverURLDraft = store.serverBaseURL
            displayNameDraft = store.displayName
        }
    }

    private func saveServerSettings() {
        store.setServerBaseURL(serverURLDraft)
        store.setDisplayName(displayNameDraft)
        Task {
            do {
                let response = try await APIClient(baseURLString: serverURLDraft).register(deviceId: store.deviceId, displayName: displayNameDraft)
                registerStatus = "Qeydiyyat uğurlu. Dəvət kodunuz: \(response.inviteCode)"
            } catch {
                registerStatus = "Xəta: \(error.localizedDescription)"
            }
        }
    }

    private static func languageName(for code: String) -> String {
        switch code {
        case "az": return "Azərbaycan dili"
        case "hi": return "हिन्दी"
        case "zh": return "中文"
        case "es": return "Español"
        case "pt": return "Português"
        case "id": return "Bahasa Indonesia"
        case "ar": return "العربية"
        case "vi": return "Tiếng Việt"
        case "ko": return "한국어"
        default: return code
        }
    }
}
