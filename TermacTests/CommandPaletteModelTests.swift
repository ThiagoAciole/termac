//
//  CommandPaletteModelTests.swift
//  TermacTests
//

import Testing
@testable import Termac

@MainActor
struct CommandPaletteModelTests {
    @Test func selectionWrapsAround() {
        let model = CommandPaletteModel()
        model.setItems([item("one"), item("two")])

        model.moveSelection(by: -1)
        #expect(model.selectCurrent()?.id == "two")
        model.moveSelection(by: 1)
        #expect(model.selectCurrent()?.id == "one")
    }

    @Test func filteringClampsSelection() {
        let model = CommandPaletteModel()
        model.setItems([item("one"), item("two"), item("three")])
        model.moveSelection(by: 2)
        model.update(query: "one")

        #expect(model.selectedIndex == 0)
        #expect(model.selectCurrent()?.id == "one")
    }

    @Test func emptyResultsHaveNoCurrentItem() {
        let model = CommandPaletteModel()
        model.setItems([item("one")])
        model.update(query: "missing")

        #expect(model.filteredItems.isEmpty)
        #expect(model.selectCurrent() == nil)
    }

    private func item(_ id: String) -> CommandPaletteItem {
        CommandPaletteItem(id: id, title: id, icon: "terminal", kind: .action) {}
    }
}
