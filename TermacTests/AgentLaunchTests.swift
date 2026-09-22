//
//  AgentLaunchTests.swift
//  TermacTests
//

import Testing
@testable import Termac

@MainActor
struct AgentLaunchTests {
    @Test func runAgentInNewTabKeepsExistingTabAndQueuesCommand() throws {
        let tabs = TabManager(createInitialTab: false)
        tabs.newTab(inheritingCwd: false)
        let original = try #require(tabs.selectedSession)
        let agent = CLIAgent(
            name: "Shell",
            command: "/bin/sh -c",
            colorHex: "#8E8E93",
            symbolName: "terminal.fill"
        )

        tabs.runAgentInNewTab(agent)

        #expect(tabs.sessions.count == 2)
        #expect(tabs.sessions.first?.id == original.id)
        #expect(tabs.selectedSession?.id != original.id)
        #expect(tabs.selectedSession?.pendingAgentCommand == agent.command)
        #expect(original.pendingAgentCommand == nil)
    }
}
