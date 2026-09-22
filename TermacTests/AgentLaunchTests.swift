//
//  AgentLaunchTests.swift
//  TermacTests
//

import Testing
@testable import Termac

@MainActor
struct AgentLaunchTests {
    @Test func runAgentInNewTabKeepsExistingTabAndTintsNewOne() throws {
        let tabs = TabManager(createInitialTab: false)
        tabs.newTab(inheritingCwd: false)
        let original = try #require(tabs.selectedSession)
        let agent = CustomAgent(name: "Shell", command: "/bin/sh -c", colorHex: "#D97757")

        tabs.runAgentInNewTab(agent)

        #expect(tabs.sessions.count == 2)
        #expect(tabs.sessions.first?.id == original.id)
        #expect(tabs.selectedSession?.id != original.id)
        // The agent boots directly (no paste into a shell), and the tab
        // carries the agent color for the chip tint.
        #expect(tabs.selectedSession?.pendingAgentCommand == nil)
        #expect(tabs.selectedSession?.agentColorHex == "#D97757")
        #expect(tabs.selectedSession?.title == "Shell")
        #expect(original.pendingAgentCommand == nil)
        #expect(original.agentColorHex == nil)
    }
}
