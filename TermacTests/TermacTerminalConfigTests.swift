//
//  TermacTerminalConfigTests.swift
//  TermacTests
//

import Testing
@testable import Termac

struct TermacTerminalConfigTests {
    @Test func makeLaunchCommandForPlainPath() {
        let command = TermacTerminalConfig.makeLaunchCommand(shellPath: "/bin/zsh")
        #expect(command == "/bin/sh -c 'unset CLAUDE_CODE_CHILD_SESSION; exec '\\''/bin/zsh'\\'' -l'")
    }

    @Test func makeLaunchCommandForPathWithSpaces() {
        let command = TermacTerminalConfig.makeLaunchCommand(
            shellPath: "/opt/my shell/zsh"
        )
        #expect(command == "/bin/sh -c 'unset CLAUDE_CODE_CHILD_SESSION; exec '\\''/opt/my shell/zsh'\\'' -l'")
    }

    @Test func makeLaunchCommandForPathWithSingleQuote() {
        let command = TermacTerminalConfig.makeLaunchCommand(shellPath: "/tmp/it's")
        // Nested single-quote escaping: ' → '\'' inside the /bin/sh -c payload.
        #expect(command.hasPrefix("/bin/sh -c "))
        #expect(command.contains("/tmp/it"))
        #expect(command.contains("\\'"))
        #expect(command.hasSuffix(" -l'"))
    }

    @Test func clearsClaudeChildSessionMarkerBeforeLoginShell() {
        let command = TermacTerminalConfig.makeLaunchCommand(shellPath: "/bin/zsh")

        #expect(command.contains("unset CLAUDE_CODE_CHILD_SESSION;"))
    }

    @Test func makeAgentLaunchCommandRunsAgentThenHandsOffToShell() {
        let command = TermacTerminalConfig.makeAgentLaunchCommand(
            shellPath: "/bin/zsh",
            agentCommand: "claude"
        )

        // Non-interactive login boot for the agent (no zshrc wait)...
        #expect(command.contains("-l -c"))
        // ...the agent command itself...
        #expect(command.contains("claude;"))
        // ...a fresh login shell taking over on exit (exec ... -l)...
        #expect(command.contains("; exec"))
        // ...and the child-session marker cleared before boot.
        #expect(command.contains("unset CLAUDE_CODE_CHILD_SESSION;"))
    }

    @Test func makeAgentLaunchCommandKeepsAgentArguments() {
        let command = TermacTerminalConfig.makeAgentLaunchCommand(
            shellPath: "/bin/zsh",
            agentCommand: "tompero start-day"
        )

        #expect(command.contains("tompero start-day;"))
    }
}
