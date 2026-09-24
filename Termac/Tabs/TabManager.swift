//
//  TabManager.swift
//  termac
//

import AppKit
import Combine
import Foundation

@MainActor
final class TabManager: ObservableObject {
    @Published private(set) var sessions: [TerminalSession] = []
    @Published private(set) var selectedID: TerminalSession.ID?
    @Published private(set) var isFindPresented = false
    @Published private(set) var findQuery = ""
    /// Bumped when Find should re-focus the query field (e.g. ⌘F while already open).
    @Published private(set) var findFocusToken = 0
    @Published private(set) var isCommandPalettePresented = false

    var selectedSession: TerminalSession? {
        sessions.first { $0.id == selectedID }
    }

    var parkedSessions: [TerminalSession] {
        sessions.filter { $0.id != selectedID }
    }

    private var roster = TabRoster()
    private var cancellables = Set<AnyCancellable>()
    private let makeSession: (String) -> TerminalSession
    private let makeAgentSession: (String, CustomAgent) -> TerminalSession
    private let confirmCloseHandler: (TerminalSession, @escaping () -> Void) -> Void
    private let closeWindowHandler: (NSWindow?) -> Void
    private let shouldConfirmBusyClose: () -> Bool
    private let isSessionBusy: (TerminalSession) -> Bool
    private let agentsProvider: () -> [CustomAgent]
    private var closedTabSnapshots: [ClosedTabSnapshot] = []

    init(
        makeSession: ((String) -> TerminalSession)? = nil,
        makeAgentSession: ((String, CustomAgent) -> TerminalSession)? = nil,
        createInitialTab: Bool = true,
        confirmClose: ((TerminalSession, @escaping () -> Void) -> Void)? = nil,
        closeWindow: ((NSWindow?) -> Void)? = nil,
        shouldConfirmBusyClose: (() -> Bool)? = nil,
        isSessionBusy: ((TerminalSession) -> Bool)? = nil,
        agentsProvider: (() -> [CustomAgent])? = nil
    ) {
        self.makeSession = makeSession ?? { TerminalSession(workingDirectory: $0) }
        self.makeAgentSession = makeAgentSession ?? {
            TerminalSession(runningAgent: $1, workingDirectory: $0)
        }
        self.closeWindowHandler = closeWindow ?? { window in
            DispatchQueue.main.async { window?.close() }
        }
        self.confirmCloseHandler = confirmClose ?? Self.defaultConfirmClose
        self.shouldConfirmBusyClose = shouldConfirmBusyClose
            ?? { AppSettings.shared.confirmCloseRunningCommand }
        self.isSessionBusy = isSessionBusy ?? { $0.hasRunningCommand }
        self.agentsProvider = agentsProvider ?? { AppSettings.shared.customAgents }

        if createInitialTab {
            newTab(inheritingCwd: false)
        }
        NotificationCenter.default.publisher(for: .termacSettingsDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshAppearance()
                self?.refreshTitles()
            }
            .store(in: &cancellables)
        // On quit, kill every PTY child so shells (and their foreground
        // commands) don't get orphaned to launchd and linger in the
        // background. Selector-based observer fires synchronously during
        // `willTerminate` — unlike the Combine `receive(on:)` hop above,
        // it is guaranteed to run before the process exits.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    /// Tears down all live surfaces on app termination: `TerminalSession
    /// .terminate()` frees the Ghostty surface, which closes the PTY and
    /// signals the child process group so shells don't outlive the app.
    @objc private func applicationWillTerminate() {
        for session in sessions {
            session.terminate()
        }
    }

    /// Opens a tab. When `inheritingCwd` is true, launches in the selected tab's cwd.
    func newTab(inheritingCwd: Bool = true) {
        openSession(makeSession, inheritingCwd: inheritingCwd)
    }

    /// Runs a configured agent in a new tab, inheriting the selected tab's cwd.
    /// The agent boots directly through a non-interactive login shell instead of
    /// being pasted into an interactive one, so no zshrc init delays the launch.
    /// The tab chip is tinted with the agent's color.
    func runAgentInNewTab(_ agent: CustomAgent) {
        openSession({ makeAgentSession($0, agent) }, inheritingCwd: true)
        selectedSession?.markAsAgent(name: agent.name, colorHex: agent.colorHex)
    }

    func showCommandPalette() {
        dismissFindIfNeeded()
        isCommandPalettePresented = true
    }

    func hideCommandPalette() {
        isCommandPalettePresented = false
    }

    func togglePinSelected() {
        guard let selectedSession else { return }
        togglePin(selectedSession)
    }

    func commandPaletteItems() -> [CommandPaletteItem] {
        var items: [CommandPaletteItem] = [
            CommandPaletteItem(
                id: "action-new-tab", title: "New Tab", subtitle: "⌘T", icon: "plus", kind: .action,
                searchTerms: ["New Tab", "⌘T"]
            ) { [weak self] in self?.newTab() },
            CommandPaletteItem(
                id: "action-close-tab", title: "Close Tab", subtitle: "⌘W", icon: "xmark", kind: .action,
                searchTerms: ["Close Tab", "⌘W"]
            ) { [weak self] in self?.closeSelected() },
            CommandPaletteItem(
                id: "action-reopen-tab", title: "Reopen Closed Tab", subtitle: "⌘⇧T",
                icon: "arrow.uturn.backward", kind: .action, searchTerms: ["Reopen Closed Tab", "⌘⇧T"]
            ) { [weak self] in self?.reopenClosedTab() },
            CommandPaletteItem(
                id: "action-duplicate-tab", title: "Duplicate Tab", icon: "plus.square.on.square",
                kind: .action, searchTerms: ["Duplicate Tab", "Copy Tab"]
            ) { [weak self] in self?.duplicateSelected() },
            CommandPaletteItem(
                id: "action-move-left", title: "Move Tab Left", subtitle: "⌘⇧←", icon: "arrow.left",
                kind: .action, searchTerms: ["Move Tab Left", "⌘⇧←"]
            ) { [weak self] in self?.moveSelectedLeft() },
            CommandPaletteItem(
                id: "action-move-right", title: "Move Tab Right", subtitle: "⌘⇧→", icon: "arrow.right",
                kind: .action, searchTerms: ["Move Tab Right", "Move Right", "⌘⇧→"]
            ) { [weak self] in self?.moveSelectedRight() },
            CommandPaletteItem(
                id: "action-pin-tab",
                title: selectedSession?.isPinned == true ? "Unpin Tab" : "Pin Tab",
                icon: "pin",
                kind: .action,
                searchTerms: ["Pin Tab", "Unpin Tab"]
            ) { [weak self] in self?.togglePinSelected() },
            CommandPaletteItem(
                id: "action-find", title: "Find", subtitle: "⌘F", icon: "magnifyingglass", kind: .action,
                searchTerms: ["Find", "Search", "⌘F"]
            ) { [weak self] in self?.showFind() },
        ]

        items.append(contentsOf: sessions.map { session in
            CommandPaletteItem(
                id: "tab-\(session.id.uuidString)", title: session.title,
                subtitle: session.id == selectedID ? "Current Tab" : nil,
                icon: session.isPinned ? "pin.fill" : "terminal", kind: .tab,
                searchTerms: [session.title, session.customTitle ?? ""]
            ) { [weak self] in self?.select(session.id) }
        })

        items.append(contentsOf: agentsProvider().map { agent in
            CommandPaletteItem(
                id: "agent-\(agent.id)", title: agent.name, subtitle: agent.command,
                icon: "sparkles", kind: .agent,
                searchTerms: [agent.name, agent.command, "agent"]
            ) { [weak self] in self?.runAgentInNewTab(agent) }
        })
        return items
    }

    func duplicateSelected() {
        guard let session = selectedSession else { return }
        if let agentName = session.agentName,
           let agent = agentsProvider().first(where: { $0.name == agentName }) {
            openSession({ makeAgentSession($0, agent) }, inheritingCwd: true)
            selectedSession?.markAsAgent(name: agent.name, colorHex: agent.colorHex)
        } else {
            let cwd = session.resolvedWorkingDirectory
            let customTitle = session.customTitle
            openSession({ makeSession($0) }, inheritingCwd: false, workingDirectory: cwd)
            selectedSession?.applyCustomTitle(customTitle ?? "")
        }
    }

    func reopenClosedTab() {
        guard let snapshot = closedTabSnapshots.popLast() else { return }
        let session: TerminalSession
        if let agentName = snapshot.agentName,
           let agent = agentsProvider().first(where: { $0.name == agentName }) {
            session = makeAgentSession(snapshot.workingDirectory, agent)
            session.agentName = agent.name
            session.agentColorHex = agent.colorHex
        } else {
            session = makeSession(snapshot.workingDirectory)
        }
        session.onExited = { [weak self] exited in self?.close(exited, fromShellExit: true) }
        session.isPinned = snapshot.isPinned
        session.applyCustomTitle(snapshot.customTitle ?? "")
        let insertionIndex = min(max(snapshot.position, 0), sessions.count)
        sessions.insert(session, at: insertionIndex)
        roster.add(session.id)
        roster.move(id: session.id, toIndex: insertionIndex)
        selectedID = session.id
    }

    func moveSession(_ id: TerminalSession.ID, toIndex: Int) {
        guard let sourceIndex = sessions.firstIndex(where: { $0.id == id }) else { return }
        let session = sessions.remove(at: sourceIndex)
        let destination = min(max(toIndex, 0), sessions.count)
        sessions.insert(session, at: destination)
        roster.move(id: id, toIndex: destination)
        selectedID = roster.selectedID
    }

    private func openSession(
        _ factory: (String) -> TerminalSession,
        inheritingCwd: Bool,
        workingDirectory: String? = nil
    ) {
        dismissFindIfNeeded()
        let cwd = workingDirectory ?? Self.workingDirectoryForNewTab(
            inheritingCwd: inheritingCwd,
            selected: selectedSession?.resolvedWorkingDirectory
        )
        let session = factory(cwd)
        session.onExited = { [weak self] exited in
            self?.close(exited, fromShellExit: true)
        }
        sessions.append(session)
        roster.add(session.id)
        selectedID = roster.selectedID
    }

    /// Pure policy for which directory a new tab should launch in.
    static func workingDirectoryForNewTab(
        inheritingCwd: Bool,
        selected: String?,
        home: String = NSHomeDirectory()
    ) -> String {
        if inheritingCwd, let selected {
            return selected
        }
        return home
    }

    /// Pure policy for whether closing a busy tab should show the confirm alert.
    static func shouldConfirmClose(
        fromShellExit: Bool,
        skipConfirm: Bool,
        hasRunningCommand: Bool,
        confirmEnabled: Bool
    ) -> Bool {
        !fromShellExit && !skipConfirm && hasRunningCommand && confirmEnabled
    }

    func select(_ id: TerminalSession.ID) {
        if id != selectedID {
            dismissFindIfNeeded()
        }
        roster.select(id)
        selectedID = roster.selectedID
    }

    func closeSelected() {
        guard let selectedSession else { return }
        close(selectedSession)
    }

    func close(
        _ session: TerminalSession,
        fromShellExit: Bool = false,
        skipConfirm: Bool = false
    ) {
        if Self.shouldConfirmClose(
            fromShellExit: fromShellExit,
            skipConfirm: skipConfirm,
            hasRunningCommand: isSessionBusy(session),
            confirmEnabled: shouldConfirmBusyClose()
        ) {
            confirmCloseHandler(session) { [weak self] in
                self?.close(session, skipConfirm: true)
            }
            return
        }

        guard sessions.contains(where: { $0.id == session.id }) else {
            return
        }

        if session.id == selectedID {
            dismissFindIfNeeded()
        }

        // Capture lightweight metadata before teardown so the tab can be reopened
        // without retaining the old Ghostty surface, PTY, or scrollback.
        if !fromShellExit, let position = sessions.firstIndex(where: { $0.id == session.id }) {
            closedTabSnapshots.append(
                ClosedTabSnapshot(
                    workingDirectory: session.resolvedWorkingDirectory,
                    customTitle: session.customTitle,
                    isPinned: session.isPinned,
                    agentName: session.agentName,
                    agentColorHex: session.agentColorHex,
                    position: position
                )
            )
            if closedTabSnapshots.count > 10 {
                closedTabSnapshots.removeFirst()
            }
        }

        // Capture before teardown: after terminate the view may leave the hierarchy,
        // and SwiftUI dismiss() is unreliable from an NSAlert sheet completion.
        let shouldCloseWindow = sessions.count == 1 && !fromShellExit
        let windowToClose = shouldCloseWindow
            ? (session.terminalView.window ?? NSApp.keyWindow)
            : nil

        // Drop from the array before terminate so any late surface-close
        // callback cannot re-enter and remove(at:) with a stale index.
        sessions.removeAll { $0.id == session.id }
        let outcome = roster.remove(id: session.id, fromShellExit: fromShellExit)
        selectedID = roster.selectedID

        if !fromShellExit, !session.hasExited {
            session.terminate()
        }

        switch outcome {
        case .openReplacementTab:
            // Shell exit keeps the window alive with a fresh tab at home.
            newTab(inheritingCwd: false)
        case .dismissWindow:
            closeWindowHandler(windowToClose)
        case .remaining, .notFound:
            break
        }
    }

    func selectNext() {
        dismissFindIfNeeded()
        roster.selectNext()
        selectedID = roster.selectedID
    }

    func selectPrevious() {
        dismissFindIfNeeded()
        roster.selectPrevious()
        selectedID = roster.selectedID
    }

    func moveSelectedLeft() {
        moveSelected(by: -1)
    }

    func moveSelectedRight() {
        moveSelected(by: 1)
    }

    private func moveSelected(by offset: Int) {
        guard let selectedID,
              let index = sessions.firstIndex(where: { $0.id == selectedID }) else { return }
        let target = index + offset
        guard sessions.indices.contains(target) else { return }
        sessions.swapAt(index, target)
        roster.moveSelected(by: offset)
        self.selectedID = roster.selectedID
    }

    /// Toggles the pin flag; pinned tabs sort to the front of the strip.
    func togglePin(_ session: TerminalSession) {
        session.isPinned.toggle()
        sessions = sessions.filter(\.isPinned) + sessions.filter { !$0.isPinned }
        roster.applyOrder(sessions.map(\.id))
        selectedID = roster.selectedID
    }

    func refreshAppearance() {
        for session in sessions {
            session.applyAppearance()
        }
    }

    func refreshTitles() {
        for session in sessions {
            session.refreshTitle()
        }
    }

    func increaseZoom() {
        AppSettings.shared.increaseZoom()
    }

    func decreaseZoom() {
        AppSettings.shared.decreaseZoom()
    }

    func resetZoom() {
        AppSettings.shared.resetZoom()
    }

    // MARK: - Find

    func showFind() {
        isFindPresented = true
        findFocusToken &+= 1
        applyFindQuery()
    }

    func hideFind(endSearch: Bool = true) {
        if endSearch {
            endSearchOnSelected()
        }
        isFindPresented = false
        findQuery = ""
    }

    func updateFindQuery(_ query: String) {
        findQuery = query
        applyFindQuery()
    }

    func findNext() {
        guard isFindPresented, !findQuery.isEmpty else { return }
        selectedSession?.performFindNext()
    }

    func findPrevious() {
        guard isFindPresented, !findQuery.isEmpty else { return }
        selectedSession?.performFindPrevious()
    }

    /// Ends Ghostty search and closes the find bar only when find is open.
    private func dismissFindIfNeeded() {
        guard isFindPresented else { return }
        hideFind(endSearch: true)
    }

    private func applyFindQuery() {
        guard isFindPresented, let session = selectedSession else { return }
        session.performFindSearch(findQuery)
    }

    private func endSearchOnSelected() {
        selectedSession?.endFindSearch()
    }

    private static func defaultConfirmClose(
        _ session: TerminalSession,
        onConfirm: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "Close this tab?"
        alert.informativeText =
            "You have a running process in this tab. Closing it will terminate the process."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Cancel")

        let respond: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .alertFirstButtonReturn else { return }
            // Let the sheet finish dismissing before closing tab/window.
            DispatchQueue.main.async {
                onConfirm()
            }
        }

        if let window = session.terminalView.window ?? NSApp.keyWindow {
            alert.beginSheetModal(for: window, completionHandler: respond)
        } else {
            respond(alert.runModal())
        }
    }
}
