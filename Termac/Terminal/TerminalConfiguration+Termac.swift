//
//  TerminalConfiguration+Termac.swift
//  termac
//

import Darwin
import Foundation
import GhosttyTerminal
import GhosttyTheme

/// Ghostty configuration and launch helpers owned by the Termac host.
/// libghostty renders and runs the PTY; the host decides shell, env, keybinds,
/// and which Ghostty defaults to clear so app menus keep Cmd-T / Cmd-W.
/// MainActor-bound: every helper reads `AppSettings` (MainActor state).
@MainActor
enum TermacTerminalConfig {
    static func terminalConfiguration(
        command: String,
        fontSize: Double? = nil
    ) -> TerminalConfiguration {
        let settings = AppSettings.shared
        let sanitized = TerminalFont.sanitizedFamily(settings.fontFamily)
        let family = sanitized.isEmpty
            ? TerminalFont.resolvedDefaultFamily : sanitized
        let resolvedSize = fontSize ?? ZoomSetting.resolvedFontSize(
            base: settings.fontSize,
            zoomPercent: settings.uiZoom
        )
        return TerminalConfiguration { builder in
            builder.withFontFamily(family)
            builder.withFontSize(Float(resolvedSize))
            builder.withFontThicken(false)
            builder.withCustom("font-style", settings.fontWeight.fontStyle)
            builder.withCustom(
                "font-variation",
                "wght=\(settings.fontWeight.variationWeight)"
            )
            // Ghostty uses a relative cell-height adjustment, not a CSS multiplier.
            let cellHeightPercent = (settings.lineHeight - 1.0) * 100
            if cellHeightPercent != 0 {
                let formatted = cellHeightPercent.formatted(
                    .number.precision(.fractionLength(0...1))
                )
                builder.withCustom("adjust-cell-height", "\(formatted)%")
            }
            builder.withCursorStyle(.block)
            builder.withCursorStyleBlink(true)
            builder.withWindowPaddingX(settings.terminalPadding)
            builder.withWindowPaddingY(settings.terminalPadding)
            builder.withCustom("window-padding-balance", "true")
            builder.withCustom("window-padding-color", "extend")
            // Clear Ghostty defaults so Cmd-T / Cmd-W stay with Termac.
            builder.withCustom("keybind", "clear")
            for keybind in ShortcutsCatalog.hostKeybinds {
                builder.withCustom("keybind", keybind)
            }
            builder.withCustom("command", command)
            builder.withCustom("term", "xterm-256color")
            builder.withCustom("shell-integration", "none")
            builder.withCustom("scrollback-limit", TermacConstants.scrollbackLimit)
            builder.withCustom("macos-option-as-alt", "true")
            builder.withCustom("scrollbar", "never")
            // Vendor confirmReadClipboard auto-approves, so "ask"/paste-protection
            // would be a false sense of security. Deny OSC 52 reads until a real UI exists.
            builder.withCustom("clipboard-read", "deny")
            builder.withCustom("clipboard-write", "allow")
            builder.withCustom("clipboard-paste-protection", "false")
        }
    }

    static func ghosttyTheme() -> GhosttyTerminal.TerminalTheme {
        let config = Theme.terminal().toTerminalConfiguration()
        // API requires both slots; the host always uses the same chosen theme.
        return GhosttyTerminal.TerminalTheme(light: config, dark: config)
    }

    static func surfaceEnvironment() -> [String: String] {
        var environment = [
            "TERM": "xterm-256color",
            "COLORTERM": "truecolor",
            "TERM_PROGRAM": "Termac",
        ]
        if let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String, !version.isEmpty {
            environment["TERM_PROGRAM_VERSION"] = version
        }
        if ProcessInfo.processInfo.environment["LANG"] == nil {
            environment["LANG"] = "en_US.UTF-8"
        }
        return environment
    }

    static func makeLaunchCommand(shellPath: String) -> String {
        let quoted = shellQuote(shellPath)
        // A Termac process can be opened from Claude Code and inherit its
        // child-session marker. Clear it before starting every login shell so
        // Claude launched in a new tab is treated as an independent session.
        let command = "unset CLAUDE_CODE_CHILD_SESSION; exec \(quoted) -l"
        return "shell:/bin/sh -c \(shellQuote(command))"
    }

    /// Agent tabs boot the agent through a non-interactive login shell
    /// (`-l -c`: PATH from zprofile, no interactive zshrc/p10k init), then
    /// hand the tab to a fresh login shell when the agent exits.
    static func makeAgentLaunchCommand(shellPath: String, agentCommand: String) -> String {
        // Plain `binary [args…]` commands skip the shell roundtrip entirely:
        // Ghostty execs the resolved binary itself (`direct:`), so the tab
        // never pays for a zsh boot. Anything with shell syntax keeps the
        // login-shell chain so pipes, env prefixes, and quotes keep working.
        if let direct = directExecutableComponents(for: agentCommand) {
            let commandLine = ([direct.path] + direct.arguments).joined(separator: " ")
            return "direct:\(commandLine)"
        }
        return makeKeepOpenLoginShellCommand(shellPath: shellPath, command: agentCommand)
    }

    /// Runs `command` through a non-interactive login shell and hands the tab
    /// to a fresh login shell on exit (Terminal.app's keep-open behavior).
    /// Single shell layer: the `exec`s collapse the boot shell away, so no
    /// wrapper `/bin/sh` is needed to run the unset first.
    private static func makeKeepOpenLoginShellCommand(shellPath: String, command: String) -> String {
        let quotedShell = shellQuote(shellPath)
        let script = "unset CLAUDE_CODE_CHILD_SESSION; \(command); exec \(quotedShell) -l"
        return "shell:\(quotedShell) -l -c \(shellQuote(script))"
    }

    /// Splits `binary [arguments…]` and resolves the executable against the
    /// app PATH plus the usual Homebrew/system prefixes. Returns nil when the
    /// command contains shell syntax or the executable can't be resolved —
    /// the caller then falls back to the shell chain.
    static func directExecutableComponents(for command: String) -> (path: String, arguments: [String])? {
        let parts = command.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard let name = parts.first, !containsShellSyntax(command) else { return nil }
        guard let path = resolveExecutable(named: name) else { return nil }
        return (path, Array(parts.dropFirst()))
    }

    static func resolveExecutable(named name: String) -> String? {
        let file = FileManager.default
        if name.contains("/") {
            guard name.hasPrefix("/") else { return nil }
            return file.isExecutableFile(atPath: name) ? name : nil
        }
        for directory in executableSearchDirectories() {
            let candidate = (directory as NSString).appendingPathComponent(name)
            if file.isExecutableFile(atPath: candidate) { return candidate }
        }
        return nil
    }

    /// GUI apps inherit a slim PATH; Homebrew and local prefixes cover the
    /// common agent installs before the fallback to the login shell.
    private static func executableSearchDirectories() -> [String] {
        var directories = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":", omittingEmptySubsequences: true)
            .map(String.init)
        directories.append(contentsOf: [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
        ])
        var seen = Set<String>()
        return directories.filter { seen.insert($0).inserted }
    }

    /// Shell features `direct:` cannot express: separators, pipes,
    /// redirection, expansion, quotes, and `VAR=value` env prefixes. Flags
    /// like `--model=opus` are plain argv and stay direct.
    static func containsShellSyntax(_ command: String) -> Bool {
        let forbidden = CharacterSet(charactersIn: ";|&<>()$`\"'\\*?~#!\n{}[]")
        if command.rangeOfCharacter(from: forbidden) != nil { return true }
        if let first = command.split(separator: " ", omittingEmptySubsequences: true).first,
           first.contains("="),
           first.range(of: "^[A-Za-z_][A-Za-z0-9_]*=", options: .regularExpression) != nil {
            return true
        }
        return false
    }

    static func loginShell() -> String {
        if let pw = getpwuid(getuid()), let shell = pw.pointee.pw_shell {
            let path = String(cString: shell)
            if !path.isEmpty { return path }
        }
        return ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    }

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
