//
//  WindowChrome.swift
//  termac
//

import AppKit
import ObjectiveC
import SwiftUI

/// Transparent region that lets mouse-downs drag the window (needed with a hidden title bar).
struct WindowDragRegion: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowDragNSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

@MainActor
final class WindowLifecycleCoordinator {
    static let shared = WindowLifecycleCoordinator()

    private var observer: NSObjectProtocol?

    private init() {}

    func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            MainActor.assumeIsolated {
                self?.terminalWindowWillClose(window)
            }
        }
    }

    private func terminalWindowWillClose(_ window: NSWindow) {
        guard window.termacDidApplyChromeStyle else { return }

        let hasAnotherTerminalWindow = NSApp.windows.contains { candidate in
            candidate !== window
                && candidate.termacDidApplyChromeStyle
        }
        guard !hasAnotherTerminalWindow else { return }

        for candidate in NSApp.windows where candidate !== window {
            guard !candidate.termacDidApplyChromeStyle else { continue }
            candidate.close()
        }
    }
}

private final class WindowDragNSView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            window?.zoom(nil)
            return
        }
        // Single-click drag is handled by mouseDownCanMoveWindow.
    }
}

/// Ensures content draws under the traffic-light area with a transparent titlebar,
/// and applies starting size/position once when the window first appears.
struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            Self.configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            Self.configure(nsView.window)
        }
    }

    private static func configure(_ window: NSWindow?) {
        guard let window else { return }

        if !window.termacDidApplyChromeStyle {
            window.termacDidApplyChromeStyle = true
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.toolbar = nil
        }

        // One-shot: starting geometry from settings applies only to new windows.
        if window.termacDidApplyInitialGeometry { return }
        window.termacDidApplyInitialGeometry = true
        WindowGeometry.applyInitialFrame(to: window)
    }
}

private extension NSWindow {
    private static var initialGeometryKey: UInt8 = 0
    private static var chromeStyleKey: UInt8 = 1

    var termacDidApplyInitialGeometry: Bool {
        get {
            (objc_getAssociatedObject(self, &Self.initialGeometryKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &Self.initialGeometryKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    var termacDidApplyChromeStyle: Bool {
        get {
            (objc_getAssociatedObject(self, &Self.chromeStyleKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &Self.chromeStyleKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
