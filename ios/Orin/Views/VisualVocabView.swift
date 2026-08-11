import SwiftUI

/// Category grid for visual vocabulary. Browse-oriented (tap a card to
/// reveal its gloss) rather than graded — mirrors how the web app's visual
/// lüğət is a browsing aid, not a spaced-repetition-scheduled deck.
struct VisualVocabView: View {
    @Environment(ContentStore.self) private var contentStore
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(contentStore.visualVocab) { category in
                    NavigationLink {
                        VisualCategoryView(category: category)
                    } label: {
                        VStack(spacing: 6) {
                            Text(category.icon).font(.system(size: 34))
                            Text(category.title)
                                .font(.caption.weight(.medium))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                            Text("\(category.items.count) söz")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Vizual lüğət")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VisualCategoryView: View {
    let category: VisualCategory
    @State private var revealed: Set<String> = []
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(category.items) { item in
                    Button {
                        if revealed.contains(item.id) { revealed.remove(item.id) }
                        else { revealed.insert(item.id) }
                    } label: {
                        VStack(spacing: 6) {
                            Text(item.emoji.isEmpty ? category.icon : item.emoji)
                                .font(.system(size: 30))
                            Text(item.word)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                            if revealed.contains(item.id) {
                                Text(item.gloss)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .transition(.opacity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
