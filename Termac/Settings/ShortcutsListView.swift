//
//  ShortcutsListView.swift
//  termac
//

import SwiftUI

struct ShortcutsListView: View {
    @State private var searchText = ""

    var body: some View {
        Form {
            ForEach(ShortcutsCatalog.sections) { section in
                let items = filteredItems(in: section)
                if !items.isEmpty {
                    Section(section.title) {
                        ForEach(items) { item in
                            LabeledContent(item.title) {
                                Text(item.keys)
                                    .font(.body.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !searchText.isEmpty && filteredItems.isEmpty {
                ContentUnavailableView(
                    "Nenhum atalho encontrado",
                    systemImage: "magnifyingglass"
                )
            }
        }
        .searchable(text: $searchText, prompt: "Buscar atalho")
        .formStyle(.grouped)
    }

    private var filteredItems: [ShortcutsCatalog.Item] {
        ShortcutsCatalog.sections.flatMap { filteredItems(in: $0) }
    }

    private func filteredItems(in section: ShortcutsCatalog.Section) -> [ShortcutsCatalog.Item] {
        section.items.filter { item in
            searchText.isEmpty
                || item.title.localizedCaseInsensitiveContains(searchText)
                || item.keys.localizedCaseInsensitiveContains(searchText)
                || item.id.localizedCaseInsensitiveContains(searchText)
        }
    }
}
