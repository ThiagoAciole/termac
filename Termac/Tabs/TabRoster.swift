//
//  TabRoster.swift
//  termac
//

import Foundation

/// Pure tab order and selection rules used by `TabManager`.
/// Keeps close/next/prev index math free of PTY and AppKit.
struct TabRoster {
    enum RemoveOutcome: Equatable {
        /// List still has tabs; `selectedID` is the post-remove selection.
        case remaining
        /// Last tab exited from the shell — host should open a replacement tab.
        case openReplacementTab
        /// User closed the last tab — host should dismiss the window.
        case dismissWindow
        /// ID was not in the roster.
        case notFound
    }

    private(set) var orderedIDs: [UUID] = []
    private(set) var selectedID: UUID?

    mutating func add(_ id: UUID) {
        orderedIDs.append(id)
        selectedID = id
    }

    mutating func select(_ id: UUID) {
        guard orderedIDs.contains(id) else { return }
        selectedID = id
    }

    mutating func selectNext() {
        guard let selectedID,
              let index = orderedIDs.firstIndex(of: selectedID),
              !orderedIDs.isEmpty
        else { return }
        self.selectedID = orderedIDs[(index + 1) % orderedIDs.count]
    }

    mutating func selectPrevious() {
        guard let selectedID,
              let index = orderedIDs.firstIndex(of: selectedID),
              !orderedIDs.isEmpty
        else { return }
        self.selectedID = orderedIDs[(index - 1 + orderedIDs.count) % orderedIDs.count]
    }

    /// Swaps the selected tab with its neighbor. No-op at ends or with no selection.
    mutating func moveSelected(by offset: Int) {
        guard let selectedID,
              let index = orderedIDs.firstIndex(of: selectedID) else { return }
        let target = index + offset
        guard orderedIDs.indices.contains(target) else { return }
        orderedIDs.swapAt(index, target)
    }

    /// Re-applies an explicit order (e.g. pinned tabs moved to the front),
    /// preserving selection and any ids the caller omitted.
    mutating func applyOrder(_ ids: [UUID]) {
        let known = Set(orderedIDs)
        let sorted = ids.filter { known.contains($0) }
        let omitted = orderedIDs.filter { !ids.contains($0) }
        orderedIDs = sorted + omitted
    }

    /// Moves any known tab to a clamped destination index, preserving selection.
    mutating func move(id: UUID, toIndex: Int) {
        guard let sourceIndex = orderedIDs.firstIndex(of: id), !orderedIDs.isEmpty else { return }
        let item = orderedIDs.remove(at: sourceIndex)
        let destination = min(max(toIndex, 0), orderedIDs.count)
        orderedIDs.insert(item, at: destination)
    }

    /// Removes `id` and updates selection to mirror `TabManager.close`.
    mutating func remove(id: UUID, fromShellExit: Bool) -> RemoveOutcome {
        guard let index = orderedIDs.firstIndex(of: id) else {
            return .notFound
        }

        let wasSelected = selectedID == id
        orderedIDs.remove(at: index)

        if orderedIDs.isEmpty {
            selectedID = nil
            return fromShellExit ? .openReplacementTab : .dismissWindow
        }

        if wasSelected {
            let nextIndex = min(index, orderedIDs.count - 1)
            selectedID = orderedIDs[nextIndex]
        }
        return .remaining
    }
}
