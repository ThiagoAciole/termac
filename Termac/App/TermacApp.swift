//
//  TermacApp.swift
//  termac
//

import AppKit
import SwiftUI

/// A Termac process opened from inside a Claude Code session inherits the
/// child-session marker, and every PTY (shell or `direct:` agent) would pass
/// it on. Clearing it once at startup keeps launched agents independent —
/// the shell chains unset it too, but `direct:` has no shell to do it.
func sanitizeInheritedEnvironment() {
    unsetenv("CLAUDE_CODE_CHILD_SESSION")
}

@main
struct TermacApp: App {
    init() {
        sanitizeInheritedEnvironment()
        // Load prefs early; do not touch NSApp here - it is still nil.
        _ = AppSettings.shared
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            WindowRootView()
                .onAppear {
                    AppSettings.shared.applyAppAppearance()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(WindowGeometry.contentSize())
        .commands {
            TermacCommands()
        }

        Settings {
            SettingsView()
        }
    }
}

private struct WindowRootView: View {
    @StateObject private var tabs = TabManager()

    var body: some View {
        ContentView(tabs: tabs)
            .focusedSceneObject(tabs)
    }
}

private struct TermacCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @FocusedObject private var tabs: TabManager?
    @ObservedObject private var settings = AppSettings.shared

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                openWindow(id: "main")
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Tab") {
                tabs?.newTab()
            }
            .keyboardShortcut("t", modifiers: .command)
            .disabled(tabs == nil)
        }

        CommandGroup(after: .newItem) {
            Button("Close Tab") {
                tabs?.closeSelected()
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(tabs == nil)

            Divider()

            Button("Show Next Tab") {
                tabs?.selectNext()
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])
            .disabled(tabs == nil)

            Button("Show Previous Tab") {
                tabs?.selectPrevious()
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])
            .disabled(tabs == nil)

            Button("Move Tab Left") {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabs?.moveSelectedLeft()
                }
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command, .shift])
            .disabled(tabs == nil)

            Button("Move Tab Right") {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabs?.moveSelectedRight()
                }
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .shift])
            .disabled(tabs == nil)

            Divider()

            Button("Reopen Closed Tab") {
                tabs?.reopenClosedTab()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .disabled(tabs == nil)

            Button("Duplicate Tab") {
                tabs?.duplicateSelected()
            }
            .disabled(tabs == nil)

            Button("Reload Configuration") {
                AppSettings.shared.reloadFromDisk()
            }
            .keyboardShortcut(",", modifiers: [.command, .shift])
        }

        CommandGroup(after: .pasteboard) {
            Button("Command Palette…") {
                tabs?.showCommandPalette()
            }
            .keyboardShortcut("k", modifiers: .command)
            .disabled(tabs == nil)

            Button("Find…") {
                tabs?.showFind()
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(tabs == nil)
        }

        CommandMenu("View") {
            Button("Zoom In") {
                tabs?.increaseZoom()
            }
            .keyboardShortcut("=", modifiers: .command)
            .disabled(tabs == nil)

            Button("Zoom Out") {
                tabs?.decreaseZoom()
            }
            .keyboardShortcut("-", modifiers: .command)
            .disabled(tabs == nil)

            Button("Actual Size (\(Int(settings.uiZoom))%)") {
                tabs?.resetZoom()
            }
            .keyboardShortcut("0", modifiers: .command)
            .disabled(tabs == nil)
        }
    }
}
