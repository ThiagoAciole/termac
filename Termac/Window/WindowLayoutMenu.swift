//
//  WindowLayoutMenu.swift
//  termac
//

import AppKit
import SwiftUI

/// Window arrangements offered by the layout dropdown.
enum WindowSnapTarget: Hashable {
    case maximize
    case left
    case right

    /// Target frame within the usable screen area (Cocoa coordinates).
    static func frame(for target: WindowSnapTarget, visibleFrame: CGRect) -> CGRect {
        let halfWidth = visibleFrame.width / 2
        switch target {
        case .maximize:
            return visibleFrame
        case .left:
            return CGRect(
                x: visibleFrame.minX,
                y: visibleFrame.minY,
                width: halfWidth,
                height: visibleFrame.height
            )
        case .right:
            return CGRect(
                x: visibleFrame.minX + halfWidth,
                y: visibleFrame.minY,
                width: visibleFrame.width - halfWidth,
                height: visibleFrame.height
            )
        }
    }
}

/// Applies snap targets to a window. Maximizing stores the pre-zoom frame so
/// a second tap restores the previous geometry.
@MainActor
enum WindowSnapping {
    private static let previousFrames = NSMapTable<NSWindow, NSValue>.weakToStrongObjects()

    static func apply(_ target: WindowSnapTarget, to window: NSWindow) {
        let screen = window.screen ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }

        if target == .maximize, isMaximized(window: window, visibleFrame: visibleFrame) {
            if let previous = previousFrames.object(forKey: window)?.rectValue {
                window.setFrame(previous, display: true, animate: true)
                previousFrames.removeObject(forKey: window)
            }
            return
        }
        if target == .maximize {
            previousFrames.setObject(NSValue(rect: window.frame), forKey: window)
        }
        window.setFrame(
            WindowSnapTarget.frame(for: target, visibleFrame: visibleFrame),
            display: true,
            animate: true
        )
    }

    static func minimize(_ window: NSWindow) {
        window.performMiniaturize(nil)
    }

    static func isMaximized(window: NSWindow, visibleFrame: CGRect) -> Bool {
        let frame = window.frame
        return abs(frame.minX - visibleFrame.minX) < 1
            && abs(frame.minY - visibleFrame.minY) < 1
            && abs(frame.width - visibleFrame.width) < 1
            && abs(frame.height - visibleFrame.height) < 1
    }
}

/// Header dropdown right of Settings: maximize / minimize / half splits,
/// styled after the Windows snap-layouts picker.
struct WindowLayoutMenu: View {
    @State private var showsPanel = false
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.headerScale) private var headerScale

    var body: some View {
        Button {
            showsPanel.toggle()
        } label: {
            ChromeIconLabel(
                systemName: "rectangle.stack",
                iconSize: settings.headerSize.actionIconSize * settings.actionIconScale * headerScale,
                frameWidth: settings.headerSize.buttonFrameWidth * headerScale,
                frameHeight: settings.headerSize.buttonFrameHeight * headerScale
            )
        }
        .buttonStyle(.plain)
        .help("Window Layout")
        .popover(isPresented: $showsPanel, arrowEdge: .bottom) {
            WindowLayoutPanel()
        }
    }
}

/// Frosted panel with layout tiles, mirroring the snap-layouts picker.
private struct WindowLayoutPanel: View {
    @Environment(\.dismiss) private var dismiss

    /// While the popover is open it owns keyWindow; the terminal window
    /// stays the main window, so resolve targets against that.
    private var targetWindow: NSWindow? {
        NSApp.mainWindow ?? NSApp.keyWindow
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                LayoutTile(help: "Maximize") {
                    PaneDiagram()
                } action: {
                    snap(.maximize)
                }

                LayoutTile(help: "Snap Left or Right") {
                    HStack(spacing: 4) {
                        HoverablePane(content: PaneDiagram())
                            .onTapGesture { snap(.left) }
                        HoverablePane(content: PaneDiagram())
                            .onTapGesture { snap(.right) }
                    }
                }
            }

            Divider()

            Button {
                if let window = targetWindow {
                    WindowSnapping.minimize(window)
                }
                dismiss()
            } label: {
                Label("Minimize", systemImage: "arrow.down.to.line")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .controlSize(.small)
            .help("Minimize")
        }
        .padding(12)
        .background(.regularMaterial)
    }

    private func snap(_ target: WindowSnapTarget) {
        if let window = targetWindow {
            WindowSnapping.apply(target, to: window)
        }
        dismiss()
    }
}

/// Fixed-size hoverable tile in the layout panel. Tiles whose panes handle
/// taps themselves omit `action`.
private struct LayoutTile<Content: View>: View {
    let help: String
    @ViewBuilder let content: Content
    var action: () -> Void = {}

    @State private var isHovered = false

    var body: some View {
        content
            .frame(width: 72, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.08 : 0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(isHovered ? 0.3 : 0.15))
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isHovered = hovering
                }
            }
            .onTapGesture(perform: action)
            .help(help)
    }
}

/// Single outlined pane filling its container.
private struct PaneDiagram: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.55))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Pane region with its own hover background so each half of a tile
/// highlights independently.
private struct HoverablePane<Content: View>: View {
    let content: Content

    @State private var isHovered = false

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.12 : 0))
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isHovered = hovering
                }
            }
    }
}
