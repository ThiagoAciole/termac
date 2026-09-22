//
//  ChromeIconOptions.swift
//  termac
//

import Foundation

/// Curated SF Symbol choices for the right-side chrome buttons
/// (agents menu, settings) offered in Settings → Header.
enum ChromeIconOptions {
    static let agentsMenu = [
        "app.grid.2x2.topleft.filled",
        "command",
        "sparkles",
        "terminal",
        "wand.and.stars",
        "asterisk",
        "brain.head.profile",
        "puzzlepiece",
    ]

    static let settingsMenu = [
        "ellipsis.circle",
        "text.justify",
        "gearshape",
        "gearshape.fill",
        "slider.horizontal.3",
        "switch.2",
        "dial.min",
        "wrench.and.screwdriver",
    ]

    /// Falls back to the first option when a hand-edited config has an unknown symbol.
    static func sanitized(_ name: String, from options: [String]) -> String {
        options.contains(name) ? name : options[0]
    }
}
