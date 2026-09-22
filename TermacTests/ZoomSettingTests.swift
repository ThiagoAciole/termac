//
//  ZoomSettingTests.swift
//  TermacTests
//

import CoreGraphics
import Testing
@testable import Termac

struct ZoomSettingTests {
    @Test func clampUsesPercentageLimits() {
        #expect(ZoomSetting.clamp(1) == AppSettings.Limits.uiZoom.lowerBound)
        #expect(ZoomSetting.clamp(999) == AppSettings.Limits.uiZoom.upperBound)
        #expect(ZoomSetting.clamp(100) == 100)
    }

    @Test func increasesAndDecreasesByTenPercent() {
        #expect(ZoomSetting.increased(100) == 110)
        #expect(ZoomSetting.decreased(100) == 90)
        #expect(ZoomSetting.increased(AppSettings.Limits.uiZoom.upperBound) == 200)
        #expect(ZoomSetting.decreased(AppSettings.Limits.uiZoom.lowerBound) == 50)
    }

    @Test func resolvedFontSizeScalesAndClamps() {
        #expect(ZoomSetting.resolvedFontSize(base: 16, zoomPercent: 50) == 8)
        #expect(ZoomSetting.resolvedFontSize(base: 16, zoomPercent: 125) == 20)
        #expect(ZoomSetting.resolvedFontSize(base: 20, zoomPercent: 200) == 32)
        #expect(ZoomSetting.resolvedFontSize(base: 10, zoomPercent: 50) == 8)
    }

    @Test func headerFactorConvertsPercentageToScale() {
        #expect(ZoomSetting.headerFactor(zoomPercent: 50) == CGFloat(0.5))
        #expect(ZoomSetting.headerFactor(zoomPercent: 100) == CGFloat(1))
        #expect(ZoomSetting.headerFactor(zoomPercent: 200) == CGFloat(2))
    }
}
