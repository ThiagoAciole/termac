//
//  HeaderSizeSetting.swift
//  termac
//

import SwiftUI

/// Scales the header chrome (tab bar height, tab labels, and chrome buttons).
/// Persisted as its raw string in `config.yml`.
enum HeaderSizeSetting: String, CaseIterable, Identifiable {
    case compact
    case regular
    case large

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .regular: return "Regular"
        case .large: return "Large"
        }
    }

    /// Tab bar / top strip height in points.
    var barHeight: CGFloat {
        switch self {
        case .compact: return 42
        case .regular: return 50
        case .large: return 60
        }
    }

    /// Tab label font size in points.
    var tabFontSize: CGFloat {
        switch self {
        case .compact: return 13
        case .regular: return 15
        case .large: return 18
        }
    }

    /// Tab leading icon glyph size.
    var tabIconSize: CGFloat { tabFontSize - 2 }

    /// Close "×" glyph size.
    var closeButtonSize: CGFloat {
        switch self {
        case .compact: return 10
        case .regular: return 12
        case .large: return 14
        }
    }

    /// Chrome button glyph size (+, gear, sidebar toggle).
    var buttonIconSize: CGFloat {
        switch self {
        case .compact: return 14
        case .regular: return 16
        case .large: return 18
        }
    }

    /// Larger glyph size for the right-side actions (agents menu, settings gear).
    var actionIconSize: CGFloat {
        switch self {
        case .compact: return 18
        case .regular: return 20
        case .large: return 22
        }
    }

    var buttonFrameWidth: CGFloat {
        switch self {
        case .compact: return 30
        case .regular: return 34
        case .large: return 38
        }
    }

    var buttonFrameHeight: CGFloat {
        switch self {
        case .compact: return 26
        case .regular: return 30
        case .large: return 34
        }
    }

    /// Chevron scroll-button glyph size.
    var scrollButtonSize: CGFloat {
        switch self {
        case .compact: return 11
        case .regular: return 13
        case .large: return 15
        }
    }

    /// Dynamic scale derived from the window width so the header grows with the
    /// window (clamped to stay legible on small windows and comfortable full-screen).
    static func scale(forWidth width: CGFloat) -> CGFloat {
        min(max(width / 800, 0.9), 1.15)
    }
}

private struct HeaderScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    /// Dynamic scale applied to header chrome, derived from the window width.
    var headerScale: CGFloat {
        get { self[HeaderScaleKey.self] }
        set { self[HeaderScaleKey.self] = newValue }
    }
}
