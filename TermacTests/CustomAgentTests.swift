//
//  CustomAgentTests.swift
//  TermacTests
//

import Foundation
import Testing
@testable import Termac

struct CustomAgentTests {
    @Test func decodingLegacyAgentWithoutColorFallsBackToGray() throws {
        let json = #"{"name":"Claude Code","command":"claude"}"#
        let agent = try JSONDecoder().decode(CustomAgent.self, from: Data(json.utf8))
        #expect(agent.colorHex == "#8E8E93")
    }

    @Test func roundTripsColor() throws {
        let agent = CustomAgent(name: "Codex", command: "codex", colorHex: "#10A37F")
        let data = try JSONEncoder().encode(agent)
        let decoded = try JSONDecoder().decode(CustomAgent.self, from: data)
        #expect(decoded == agent)
    }
}
