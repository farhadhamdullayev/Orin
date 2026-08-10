import SwiftUI

/// UI-language picker (switches which language `LocalizationStore` resolves
/// glosses into, live — no relaunch needed) and a personal learning-goal
/// note, persisted via `LearningStore`/`UserProfile`.
struct SettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(LocalizationStore.self) private var localization
    @State private var goalDraft: String = ""

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
        }
        .onAppear { goalDraft = store.learningGoal }
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
