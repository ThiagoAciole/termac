//
//  WindowGeometry.swift
//  termac
//

import AppKit

/// Estimates window content size from character grid settings and centers
/// new windows inside the visible desktop.
@MainActor
enum WindowGeometry {
    /// Point size for a new window's content area (chrome + padded terminal).
    static func contentSize(from settings: AppSettings? = nil) -> CGSize {
        // Resolve .shared in the @MainActor body — default args are nonisolated.
        let settings = settings ?? .shared
        let cell = estimatedCellSize(from: settings)
        let padding = CGFloat(settings.terminalPadding) * 2
        let chromeWidth = settings.verticalTabs
            ? CGFloat(settings.verticalTabBarWidth)
            : 0
        let width = CGFloat(settings.windowColumns) * cell.width + padding + chromeWidth
        let height = settings.headerSize.barHeight
            + CGFloat(settings.windowRows) * cell.height
            + padding
        return CGSize(width: max(width, 200), height: max(height, 120))
    }

    /// Applies starting size and centers each new window in the visible desktop.
    static func applyInitialFrame(to window: NSWindow, settings: AppSettings? = nil) {
        let settings = settings ?? .shared
        let size = contentSize(from: settings)
        window.setContentSize(size)

        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }
        window.setFrameOrigin(centeredOrigin(
            visibleFrame: screen.visibleFrame,
            frameSize: window.frame.size
        ))
    }

    /// Returns a Cocoa origin that centers a frame in the visible desktop.
    /// Clamping keeps oversized windows anchored at the visible area's origin.
    static func centeredOrigin(visibleFrame: CGRect, frameSize: CGSize) -> CGPoint {
        let availableWidth = max(visibleFrame.width - frameSize.width, 0)
        let availableHeight = max(visibleFrame.height - frameSize.height, 0)
        return CGPoint(
            x: visibleFrame.minX + availableWidth / 2,
            y: visibleFrame.minY + availableHeight / 2
        )
    }

    /// Inverse of `contentSize`: desired pixel width → grid columns,
    /// accounting for padding and the vertical tab rail.
    static func gridColumns(forPixelWidth pixels: CGFloat, settings: AppSettings) -> Int {
        let cell = estimatedCellSize(from: settings)
        let padding = CGFloat(settings.terminalPadding) * 2
        let chromeWidth: CGFloat = settings.verticalTabs
            ? CGFloat(settings.verticalTabBarWidth)
            : 0
        let columns = ((pixels - padding - chromeWidth) / max(cell.width, 1)).rounded()
        return clampedGridCount(columns, to: AppSettings.Limits.windowColumns)
    }

    /// Inverse of `contentSize`: desired pixel height → grid rows,
    /// accounting for padding and the header bar.
    static func gridRows(forPixelHeight pixels: CGFloat, settings: AppSettings) -> Int {
        let cell = estimatedCellSize(from: settings)
        let padding = CGFloat(settings.terminalPadding) * 2
        let header = settings.headerSize.barHeight
        let rows = ((pixels - header - padding) / max(cell.height, 1)).rounded()
        return clampedGridCount(rows, to: AppSettings.Limits.windowRows)
    }

    private static func clampedGridCount(_ value: CGFloat, to range: ClosedRange<Int>) -> Int {
        min(max(Int(value), range.lowerBound), range.upperBound)
    }

    private static func estimatedCellSize(from settings: AppSettings) -> CGSize {
        let font = resolvedFont(from: settings)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let advance = ("M" as NSString).size(withAttributes: attrs).width
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
            * settings.lineHeight
        return CGSize(
            width: max(advance, 1),
            height: max(lineHeight, 1)
        )
    }

    private static func resolvedFont(from settings: AppSettings) -> NSFont {
        let size = CGFloat(settings.fontSize)
        let weight = settings.fontWeight.nsFontWeight
        let sanitized = TerminalFont.sanitizedFamily(settings.fontFamily)
        let family = sanitized.isEmpty
            ? TerminalFont.resolvedDefaultFamily
            : sanitized

        if let font = NSFontManager.shared.font(
            withFamily: family,
            traits: [],
            weight: settings.fontWeight.nsFontManagerWeight,
            size: size
        ) {
            return font
        }
        if let font = NSFont(name: family, size: size) {
            return font
        }
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }
}

private extension FontWeightSetting {
    var nsFontWeight: NSFont.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

    /// `NSFontManager` weight scale (0…15); 5 is Regular.
    var nsFontManagerWeight: Int {
        switch self {
        case .regular: return 5
        case .medium: return 6
        case .semibold: return 8
        case .bold: return 9
        }
    }
}
