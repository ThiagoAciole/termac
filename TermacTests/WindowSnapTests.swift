//
//  WindowSnapTests.swift
//  TermacTests
//

import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import Termac

@MainActor
struct WindowSnapTests {
    private let visible = CGRect(x: 100, y: 50, width: 1200, height: 800)

    @Test func maximizeFillsVisibleFrame() {
        let frame = WindowSnapTarget.frame(for: .maximize, visibleFrame: visible)
        #expect(frame == visible)
    }

    @Test func leftHalfCoversLeftSide() {
        let frame = WindowSnapTarget.frame(for: .left, visibleFrame: visible)
        #expect(frame.minX == visible.minX)
        #expect(frame.minY == visible.minY)
        #expect(frame.width == 600)
        #expect(frame.height == visible.height)
    }

    @Test func rightHalfCoversRightSide() {
        let frame = WindowSnapTarget.frame(for: .right, visibleFrame: visible)
        #expect(frame.maxX == visible.maxX)
        #expect(frame.minY == visible.minY)
        #expect(frame.width == 600)
        #expect(frame.height == visible.height)
    }

    @Test func halvesMeetWithoutGapOnOddWidth() {
        let odd = CGRect(x: 10, y: 10, width: 1201, height: 900)
        let left = WindowSnapTarget.frame(for: .left, visibleFrame: odd)
        let right = WindowSnapTarget.frame(for: .right, visibleFrame: odd)
        #expect(left.maxX == right.minX)
        #expect(left.width + right.width == odd.width)
    }

    @Test func maximizedDetectionToleratesOnePoint() {
        let window = NSWindow(
            contentRect: visible.insetBy(dx: 0.5, dy: 0.5),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false
        )
        window.setFrame(visible, display: false)
        #expect(WindowSnapping.isMaximized(window: window, visibleFrame: visible))

        window.setFrame(visible.insetBy(dx: 40, dy: 40), display: false)
        #expect(!WindowSnapping.isMaximized(window: window, visibleFrame: visible))
    }
}
