//
//  ZoomSetting.swift
//  termac
//

import CoreGraphics

/// Shared percentage zoom for the terminal content and tab chrome.
enum ZoomSetting {
    static let step = 10.0

    static func clamp(_ percent: Double) -> Double {
        min(max(percent, AppSettings.Limits.uiZoom.lowerBound), AppSettings.Limits.uiZoom.upperBound)
    }

    static func increased(_ percent: Double) -> Double {
        clamp(percent + step)
    }

    static func decreased(_ percent: Double) -> Double {
        clamp(percent - step)
    }

    static func resolvedFontSize(base: Double, zoomPercent: Double) -> Double {
        let scaled = base * zoomPercent / 100
        return min(
            max(scaled, AppSettings.Limits.fontSize.lowerBound),
            AppSettings.Limits.fontSize.upperBound
        )
    }

    static func headerFactor(zoomPercent: Double) -> CGFloat {
        CGFloat(clamp(zoomPercent) / 100)
    }
}
