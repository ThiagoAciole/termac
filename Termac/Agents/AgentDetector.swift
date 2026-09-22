//
//  AgentDetector.swift
//  termac
//

import Foundation

/// Detects installed CLI agents on PATH.
enum AgentDetector {
    /// Returns built-in + custom agents whose command resolves via `which`.
    static func detectedAgents(custom: [CustomAgent] = []) -> [CLIAgent] {
        let candidates = AgentCatalog.builtIn + custom.map(AgentCatalog.custom)
        return candidates.filter { isInstalled($0.command) }
    }

    static func isInstalled(_ command: String) -> Bool {
        path(of: command) != nil
    }

    /// Absolute path of a binary on PATH, or nil.
    static func path(of command: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]
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
}
