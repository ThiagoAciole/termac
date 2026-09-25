//
//  WindowGeometryTests.swift
//  TermacTests
//

import CoreGraphics
import Foundation
import Testing
@testable import Termac

@MainActor
struct WindowGeometryTests {
    private let visible = CGRect(x: 100, y: 50, width: 1200, height: 800)
    private let frameSize = CGSize(width: 400, height: 300)

    @Test func centersFrameInsideVisibleDesktop() {
        let origin = WindowGeometry.centeredOrigin(
            visibleFrame: visible,
            frameSize: frameSize
        )
        #expect(origin == CGPoint(x: 500, y: 300))
    }

    @Test func anchorsOversizedFrameAtVisibleOrigin() {
        let origin = WindowGeometry.centeredOrigin(
            visibleFrame: visible,
            frameSize: CGSize(width: 2_000, height: 1_000)
        )
        #expect(origin == CGPoint(x: visible.minX, y: visible.minY))
    }

    @Test func contentSizeAddsVerticalTabRailWidth() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("termac-geom-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let url = dir.appendingPathComponent("config.yml")
        let settings = AppSettings(configURL: url, persistDebounce: .zero)
        let horizontal = WindowGeometry.contentSize(from: settings)
        settings.verticalTabs = true
        settings.verticalTabBarWidth = Int(TermacConstants.verticalTabBarWidth)
        let vertical = WindowGeometry.contentSize(from: settings)

        #expect(
            vertical.width == horizontal.width + CGFloat(settings.verticalTabBarWidth)
        )
        #expect(vertical.height == horizontal.height)

        settings.verticalTabBarWidth = 240
        let wider = WindowGeometry.contentSize(from: settings)
        #expect(wider.width == horizontal.width + 240)
    }
}
