//
//  AgentIconTests.swift
//  TermacTests
//

import Testing
@testable import Termac

struct AgentIconTests {
    @Test func processNamesMapToNativeSymbols() {
        #expect(TabAgentIcon.match(processName: "claude") == .claude)
        #expect(TabAgentIcon.match(processName: "Codex") == .codex)
        #expect(TabAgentIcon.match(processName: "DEEPSEEK") == .deepseek)
        #expect(TabAgentIcon.match(processName: "hermes") == .hermes)
        #expect(TabAgentIcon.match(processName: "/usr/local/bin/claude") == .claude)
        #expect(TabAgentIcon.match(processName: "zsh") == nil)
        #expect(TabAgentIcon.match(processName: nil) == nil)
    }

    @Test func everyAgentHasNativeSymbolAndBrandColor() {
        #expect(TabAgentIcon.allCases.allSatisfy { !$0.symbolName.isEmpty })
        #expect(TabAgentIcon.allCases.allSatisfy { !$0.colorHex.isEmpty })
        #expect(TabAgentIcon.claude.symbolName == "asterisk")
        #expect(TabAgentIcon.codex.symbolName == "brain.head.profile")
        #expect(TabAgentIcon.claude.colorHex == "#D97757")
        #expect(TabAgentIcon.codex.colorHex == "#10A37F")
        #expect(TabAgentIcon.deepseek.colorHex == "#4D6BFE")
        #expect(TabAgentIcon.hermes.colorHex == "#8E8E93")
    }

    @Test func catalogSymbolsAndColorsMatchDetectedTabAgents() {
        let tabIconsByExecutable: [String: TabAgentIcon] = [
            "claude": .claude,
            "codex": .codex,
            "opencode": .openCode,
            "gemini": .gemini,
            "aider": .aider,
            "cursor-agent": .cursorAgent,
            "goose": .goose,
            "q": .amazonQ,
        ]

        for agent in AgentCatalog.builtIn {
            let executable = AgentDetector.executableToken(in: agent.command)
            guard let executable, let tabIcon = tabIconsByExecutable[executable] else { continue }
            #expect(agent.symbolName == tabIcon.symbolName)
            #expect(agent.colorHex == tabIcon.colorHex)
        }
    }
}
