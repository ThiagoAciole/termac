//
//  AgentDetector.swift
//  termac
//

import Foundation

/// Detects installed CLI agents on the user's login shell PATH.
enum AgentDetector {
    /// Returns built-in + custom agents whose executable resolves in the login shell.
    static func detectedAgents(custom: [CustomAgent] = []) -> [CLIAgent] {
        let candidates = AgentCatalog.builtIn + custom.map(AgentCatalog.custom)
        var seenCommands = Set<String>()

        return candidates.filter { agent in
            guard seenCommands.insert(agent.command).inserted else { return false }
            return isInstalled(agent.command)
        }
    }

    /// Supports commands with arguments (for example, `tompero start-day`).
    /// Only the executable token is resolved; the complete command is still run.
    static func isInstalled(_ command: String) -> Bool {
        guard let executable = executableToken(in: command) else { return false }
        return path(of: executable) != nil || resolvesInLoginShell(executable)
    }

    /// Absolute path of a binary on the process PATH, or nil.
    static func path(of command: String) -> String? {
        guard let executable = executableToken(in: command) else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [executable]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = out.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (path?.isEmpty == false) ? path : nil
        } catch {
            return nil
        }
    }

    /// Extracts the executable token while allowing a custom command to include args.
    static func executableToken(in command: String) -> String? {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.split(whereSeparator: { $0.isWhitespace }).first else {
            return nil
        }
        return String(first).trimmingCharacters(in: CharacterSet(charactersIn: "\\\"'"))
    }

    /// Finder-launched apps do not inherit the interactive shell's PATH. Resolve
    /// there as a fallback so aliases and tools installed in user directories work.
    private static func resolvesInLoginShell(_ executable: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-ilc", "command -v -- \(shellQuote(executable))"]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return false }
            return !out.fileHandleForReading.readDataToEndOfFile().isEmpty
        } catch {
            return false
        }
    }

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\\\''") + "'"
    }
}
