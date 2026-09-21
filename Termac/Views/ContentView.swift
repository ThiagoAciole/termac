import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showCommandPalette = false
    private var theme: AppTheme { SettingsManager.shared.theme }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TermacToolbar(onNewTab: addTab)

                // Keep all sessions alive, show only the selected one
                ZStack {
                    ForEach(appState.sessions) { session in
                        Group {
                            if SettingsManager.shared.tabLayoutMode == .vertical {
                                HStack(spacing: 0) {
                                    VerticalTabBar(session: session, onAddTab: addTab)
                                    TabContentView(session: session, showsTabBar: false)
                                }
                            } else {
                                TabContentView(session: session)
                            }
                        }
                            .opacity(session.id == appState.selectedSessionID ? 1 : 0)
                            .allowsHitTesting(session.id == appState.selectedSessionID)
                    }

                    if appState.sessions.isEmpty {
                        EmptyStateView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(theme.isGlass ? Color.clear : theme.appCanvasBackground)
            .ignoresSafeArea()

            // Notification toast overlay
            NotificationToastOverlay()

            // Command Palette overlay
            if showCommandPalette {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showCommandPalette = false
                    }

                VStack {
                    CommandPaletteView(isPresented: $showCommandPalette)
                        .padding(.top, 60)
                    Spacer()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Clear current tab's notification when app becomes active
            if let session = appState.selectedSession, let tab = session.activeTab {
                tab.hasNotification = false
                tab.lastNotificationMessage = nil
                appState.updateDockBadge()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleCommandPalette)) { _ in
            showCommandPalette.toggle()
        }
        // MARK: - Keyboard Shortcuts
        .background {
            // Cmd+P — Command Palette
            Button("") { showCommandPalette.toggle() }
                .keyboardShortcut("p", modifiers: .command)
                .hidden()

            // Cmd+T — New Tab
            Button("") { addTab() }
                .keyboardShortcut("t", modifiers: .command)
                .hidden()

            // Cmd+Shift+B — Toggle tab layout
            Button("") {
                SettingsManager.shared.tabLayoutMode = SettingsManager.shared.tabLayoutMode == .horizontal ? .vertical : .horizontal
            }
                .keyboardShortcut("b", modifiers: [.command, .shift])
                .hidden()

            // Cmd+W — Close Tab
            Button("") { closeActiveTab() }
                .keyboardShortcut("w", modifiers: .command)
                .hidden()

            // Cmd+F — Search Terminal
            Button("") {
                NotificationCenter.default.post(name: .toggleTerminalSearch, object: nil)
            }
                .keyboardShortcut("f", modifiers: .command)
                .hidden()

            // Cmd+Plus — Increase Font
            Button("") { SettingsManager.shared.increaseFontSize() }
                .keyboardShortcut("+", modifiers: .command)
                .hidden()

            // Cmd+Minus — Decrease Font
            Button("") { SettingsManager.shared.decreaseFontSize() }
                .keyboardShortcut("-", modifiers: .command)
                .hidden()

            // Cmd+0 — Reset Font Size
            Button("") { SettingsManager.shared.resetFontSize() }
                .keyboardShortcut("0", modifiers: .command)
                .hidden()

            // Cmd+D — Split Right
            Button("") { appState.selectedSession?.splitActiveTab(direction: .right) }
                .keyboardShortcut("d", modifiers: .command)
                .hidden()

            // Cmd+Shift+D — Split Down
            Button("") { appState.selectedSession?.splitActiveTab(direction: .down) }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                .hidden()

            // Cmd+1..9 — Switch Tabs
            ForEach(1...9, id: \.self) { i in
                Button("") { switchToTab(index: i - 1) }
                    .keyboardShortcut(KeyEquivalent(Character("\(i)")), modifiers: .command)
                    .hidden()
            }

            // Cmd+Shift+H — Toggle Terminal History
            Button("") {
                NotificationCenter.default.post(name: .toggleTerminalHistory, object: nil)
            }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                .hidden()

            // Cmd+Shift+Z — Toggle Zoom on active split pane
            Button("") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.selectedSession?.toggleZoom()
                }
            }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .hidden()

        }
    }

    // MARK: - Actions

    private func addTab() {
        guard let session = appState.selectedSession else { return }
        let tab = session.createTab()
        withAnimation(.easeInOut(duration: 0.15)) {
            session.addTab(tab)
        }
    }

    private func closeActiveTab() {
        guard let session = appState.selectedSession,
              let tabID = session.activeTabID else { return }
        if session.tabs.count <= 1 {
            // Last tab — close session
            withAnimation { appState.removeSession(session.id) }
        } else {
            withAnimation { session.removeTab(tabID) }
        }
    }

    private func switchToTab(index: Int) {
        guard let session = appState.selectedSession,
              index < session.tabs.count else { return }
        withAnimation(.easeInOut(duration: 0.1)) {
            session.activeTabID = session.tabs[index].id
        }
    }

}

private struct TermacToolbar: View {
    @Environment(AppState.self) private var appState
    let onNewTab: () -> Void
    private var theme: AppTheme { SettingsManager.shared.theme }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onNewTab) {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("New Tab")

            Text(appState.selectedSession?.activeTab.map { appState.selectedSession?.tabTitle(for: $0) ?? $0.title } ?? "Termac")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)

            Spacer()

            Menu {
                Button("Horizontal") { SettingsManager.shared.tabLayoutMode = .horizontal }
                Button("Vertical") { SettingsManager.shared.tabLayoutMode = .vertical }
                Divider()
                Button("Settings…") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .help("Termac Menu")
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(theme.chromeSurfaceBackground)
    }
}

extension Notification.Name {
    static let toggleTerminalSearch = Notification.Name("toggleTerminalSearch")
    static let toggleTerminalHistory = Notification.Name("toggleTerminalHistory")
}

// MARK: - Sidebar Divider (NSView-based for reliable cursor)

struct SidebarDivider: NSViewRepresentable {
    @Binding var sidebarWidth: CGFloat
    @Binding var dragStartWidth: CGFloat

    func makeNSView(context: Context) -> SidebarDividerNSView {
        let view = SidebarDividerNSView()
        view.onDrag = { delta in
            let newWidth = dragStartWidth + delta
            sidebarWidth = min(max(newWidth, 140), 400)
        }
        view.onDragEnd = {
            dragStartWidth = sidebarWidth
        }
        return view
    }

    func updateNSView(_ nsView: SidebarDividerNSView, context: Context) {
        nsView.onDrag = { delta in
            let newWidth = dragStartWidth + delta
            sidebarWidth = min(max(newWidth, 140), 400)
        }
        nsView.onDragEnd = {
            dragStartWidth = sidebarWidth
        }
    }
}

class SidebarDividerNSView: NSView {
    var onDrag: ((CGFloat) -> Void)?
    var onDragEnd: (() -> Void)?
    private var dragOriginX: CGFloat = 0

    override var intrinsicContentSize: NSSize {
        NSSize(width: 1, height: NSView.noIntrinsicMetric)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Expand hit area to 10px for easier dragging
        let expandedRect = bounds.insetBy(dx: -5, dy: 0)
        return expandedRect.contains(point) ? self : nil
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTrackingArea()
    }

    private func setupTrackingArea() {
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
    }

    override func draw(_ dirtyRect: NSRect) {
        let theme = SettingsManager.shared.theme
        let color: NSColor
        switch theme {
        case .light:
            color = NSColor(white: 0.0, alpha: 0.08)
        case .dark:
            color = NSColor(white: 1.0, alpha: 0.06)
        case .solarized:
            color = NSColor(white: 1.0, alpha: 0.06)
        case .monokai:
            color = NSColor(white: 1.0, alpha: 0.06)
        case .glass:
            color = NSColor(white: 1.0, alpha: 0.1)
        case .glassLight:
            color = NSColor(white: 0.0, alpha: 0.06)
        }
        color.setFill()
        NSRect(x: 0, y: 0, width: 1, height: bounds.height).fill()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func mouseEntered(with event: NSEvent) {
        NSCursor.resizeLeftRight.set()
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        dragOriginX = event.locationInWindow.x
    }

    override func mouseDragged(with event: NSEvent) {
        NSCursor.resizeLeftRight.set()
        let delta = event.locationInWindow.x - dragOriginX
        onDrag?(delta)
    }

    override func mouseUp(with event: NSEvent) {
        onDragEnd?()
    }
}
