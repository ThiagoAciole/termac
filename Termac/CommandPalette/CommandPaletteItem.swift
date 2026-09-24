//
//  CommandPaletteItem.swift
//  termac
//

import Foundation

struct CommandPaletteItem: Identifiable {
    enum Kind {
        case action
        case tab
        case agent
    }

    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let kind: Kind
    let searchTerms: [String]
    let execute: () -> Void

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: String,
        kind: Kind,
        searchTerms: [String] = [],
        execute: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.kind = kind
        self.searchTerms = searchTerms.isEmpty ? [title] : searchTerms
        self.execute = execute
    }
}
