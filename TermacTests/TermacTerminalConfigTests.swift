//
//  TermacTerminalConfigTests.swift
//  TermacTests
//

import Testing
@testable import Termac

@MainActor
struct TermacTerminalConfigTests {
    @Test func makeLaunchCommandForPlainPath() {
        let command = TermacTerminalConfig.makeLaunchCommand(shellPath: "/bin/zsh")
        #expect(command == "shell:/bin/sh -c 'unset CLAUDE_CODE_CHILD_SESSION; exec '\\''/bin/zsh'\\'' -l'")
    }

    @Test func makeLaunchCommandForPathWithSpaces() {
        let command = TermacTerminalConfig.makeLaunchCommand(
            shellPath: "/opt/my shell/zsh"
        )
        #expect(command == "shell:/bin/sh -c 'unset CLAUDE_CODE_CHILD_SESSION; exec '\\''/opt/my shell/zsh'\\'' -l'")
    }

    @Test func makeLaunchCommandForPathWithSingleQuote() {
        let command = TermacTerminalConfig.makeLaunchCommand(shellPath: "/tmp/it's")
        // Nested single-quote escaping: ' → '\'' inside the /bin/sh -c payload.
        #expect(command.hasPrefix("shell:/bin/sh -c "))
        #expect(command.contains("/tmp/it"))
        #expect(command.contains("\\'"))
        #expect(command.hasSuffix(" -l'"))
    }

    @Test func clearsClaudeChildSessionMarkerBeforeLoginShell() {
        let command = TermacTerminalConfig.makeLaunchCommand(shellPath: "/bin/zsh")

        #expect(command.contains("unset CLAUDE_CODE_CHILD_SESSION;"))
    }

    @Test func makeAgentLaunchCommandUsesDirectExecutionForPlainBinary() {
        let command = TermacTerminalConfig.makeAgentLaunchCommand(
            shellPath: "/bin/zsh",
            agentCommand: "/bin/echo hello world"
        )

        // No shell wrap: Ghostty execs the binary itself.
        #expect(command == "direct:/bin/echo hello world")
    }

    @Test func makeAgentLaunchCommandKeepsFlagsWithEqualsDirect() {
        let command = TermacTerminalConfig.makeAgentLaunchCommand(
            shellPath: "/bin/zsh",
            agentCommand: "/bin/echo --model=opus"
        )

        #expect(command == "direct:/bin/echo --model=opus")
    }

    @Test func makeAgentLaunchCommandFallsBackToLoginShellForShellSyntax() {
        let command = TermacTerminalConfig.makeAgentLaunchCommand(
            shellPath: "/bin/zsh",
            agentCommand: "FOO=1 claude"
        )

        // Login shell chain...
        #expect(command.hasPrefix("shell:"))
        #expect(command.contains("-l -c"))
        // ...the agent command itself...
        #expect(command.contains("FOO=1 claude;"))
        // ...a fresh login shell taking over on exit (exec ... -l)...
        #expect(command.contains("; exec"))
        // ...and the child-session marker cleared before boot.
        #expect(command.contains("unset CLAUDE_CODE_CHILD_SESSION;"))
    }

    @Test func makeAgentLaunchCommandFallsBackForMissingBinary() {
        let command = TermacTerminalConfig.makeAgentLaunchCommand(
            shellPath: "/bin/zsh",
            agentCommand: "definitely-missing-binary-xyz"
        )

        #expect(command.hasPrefix("shell:"))
        #expect(command.contains("definitely-missing-binary-xyz;"))
    }

    @Test func directExecutableComponentsSplitsPathAndArguments() {
        let components = TermacTerminalConfig.directExecutableComponents(
            for: "/bin/echo hello world"
        )
        #expect(components?.path == "/bin/echo")
        #expect(components?.arguments == ["hello", "world"])
    }

    @Test func directExecutableComponentsRejectsRelativePaths() {
        #expect(TermacTerminalConfig.directExecutableComponents(for: "bin/tool arg") == nil)
    }

    @Test func resolveExecutableVerifiesAbsolutePaths() {
        #expect(TermacTerminalConfig.resolveExecutable(named: "/bin/echo") == "/bin/echo")
        #expect(TermacTerminalConfig.resolveExecutable(named: "/nonexistent/bin") == nil)
    }

    @Test func containsShellSyntaxDetection() {
        #expect(!TermacTerminalConfig.containsShellSyntax("claude"))
        #expect(!TermacTerminalConfig.containsShellSyntax("claude --model=opus"))
        #expect(!TermacTerminalConfig.containsShellSyntax("/usr/local/bin/agent start"))

        #expect(TermacTerminalConfig.containsShellSyntax("FOO=1 claude"))
        #expect(TermacTerminalConfig.containsShellSyntax("claude | head"))
        #expect(TermacTerminalConfig.containsShellSyntax("claude && exit"))
        #expect(TermacTerminalConfig.containsShellSyntax("claude 'quoted arg'"))
        #expect(TermacTerminalConfig.containsShellSyntax("claude ~/notes"))
        #expect(TermacTerminalConfig.containsShellSyntax("claude *.log"))
    }
}
