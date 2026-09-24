//
//  CommandPaletteModel.swift
//  termac
//

import Combine
import Foundation

@MainActor
final class CommandPaletteModel: ObservableObject {
    @Published private(set) var query = ""
    @Published private(set) var filteredItems: [CommandPaletteItem] = []
    @Published private(set) var selectedIndex = 0

    private var allItems: [CommandPaletteItem] = []

    func setItems(_ items: [CommandPaletteItem]) {
        allItems = items
        refreshResults()
    }

    func update(query: String) {
        self.query = query
        refreshResults()
    }

    func moveSelection(by offset: Int) {
        guard !filteredItems.isEmpty else { return }
        selectedIndex = (selectedIndex + offset + filteredItems.count) % filteredItems.count
    }

    func select(index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        selectedIndex = index
    }

    func selectCurrent() -> CommandPaletteItem? {
        guard filteredItems.indices.contains(selectedIndex) else { return nil }
        return filteredItems[selectedIndex]
    }

    func reset() {
        query = ""
        selectedIndex = 0
        refreshResults()
    }

    private func refreshResults() {
        filteredItems = FuzzyMatcher.rank(items: allItems, query: query)
        if filteredItems.isEmpty {
            selectedIndex = 0
        } else {
            selectedIndex = min(selectedIndex, filteredItems.count - 1)
        }
    }
}
