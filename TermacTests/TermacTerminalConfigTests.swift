//
//  TermacTerminalConfigTests.swift
//  TermacTests
//

import Testing
@testable import Termac

struct TermacTerminalConfigTests {
    @Test func makeLaunchCommandForPlainPath() {
        let command = TermacTerminalConfig.makeLaunchCommand(shellPath: "/bin/zsh")
        #expect(command == "/bin/sh -c 'exec '\\''/bin/zsh'\\'' -l'")
    }

    @Test func makeLaunchCommandForPathWithSpaces() {
        let command = TermacTerminalConfig.makeLaunchCommand(
            shellPath: "/opt/my shell/zsh"
        )
        #expect(command == "/bin/sh -c 'exec '\\''/opt/my shell/zsh'\\'' -l'")
    }

    @Test func makeLaunchCommandForPathWithSingleQuote() {
        let command = TermacTerminalConfig.makeLaunchCommand(shellPath: "/tmp/it's")
        // Nested single-quote escaping: ' → '\'' inside the /bin/sh -c payload.
        #expect(command.hasPrefix("/bin/sh -c "))
        #expect(command.contains("/tmp/it"))
        #expect(command.contains("\\'"))
        #expect(command.hasSuffix(" -l'"))
    }
}
