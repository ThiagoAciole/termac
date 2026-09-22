//
//  AgentDetectorTests.swift
//  TermacTests
//

import Testing
@testable import Termac

struct AgentDetectorTests {
    @Test func executableTokenSupportsArguments() {
        #expect(AgentDetector.executableToken(in: "tompero start-day") == "tompero")
        #expect(AgentDetector.executableToken(in: "  'tompero' start-day  ") == "tompero")
        #expect(AgentDetector.executableToken(in: "") == nil)
    }

    @Test func detectsCommandsThatResolveOnPath() {
        #expect(AgentDetector.isInstalled("/bin/sh"))
        #expect(AgentDetector.path(of: "/bin/sh") == "/bin/sh")
    }

    @Test func customCommandsWithArgumentsAreDetected() {
        let agents = AgentDetector.detectedAgents(custom: [
            CustomAgent(name: "Shell", command: "/bin/sh -c")
        ])
        #expect(agents.contains { $0.id == "/bin/sh -c" })
    }
}
