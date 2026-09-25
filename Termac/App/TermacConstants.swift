//
//  TermacConstants.swift
//  termac
//

import CoreGraphics

enum TermacConstants {
    /// Fallback surface size before layout has a real frame.
    static let defaultTerminalWidth: CGFloat = 800
    static let defaultTerminalHeight: CGFloat = 600

    /// Space between the chrome bar and the terminal's first row.
    static let terminalTopInset: CGFloat = 8
    /// Additional horizontal breathing room inside the terminal, independent
    /// from the user-configured terminal padding.
    static let terminalHorizontalInset = 16

    static func effectiveTerminalPaddingX(_ configured: Int) -> Int {
        configured + terminalHorizontalInset
    }
    /// Default width of the left tab rail when vertical tabs are enabled.
    static let verticalTabBarWidth: CGFloat = 180
    static let verticalTabBarMinWidth: CGFloat = 120
    static let verticalTabBarMaxWidth: CGFloat = 360
    /// Cap each tab chip so long titles truncate instead of growing unboundedly.
    static let maxTabWidth: CGFloat = 250
    /// Space reserved for traffic lights when the title bar is hidden.
    static let trafficLightsLeadingInset: CGFloat = 78

    static let scrollbackLimit = "4194304"
}
