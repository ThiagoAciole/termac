//
//  CLIAgent.swift
//  termac
//

import SwiftUI

/// The native SF Symbol used for an agent while it is running in a tab.
enum TabAgentIcon: String, CaseIterable, Equatable {
    case claude
    case codex
    case openCode = "opencode"
    case deepseek
    case hermes
    case gemini
    case aider
    case cursorAgent = "cursor-agent"
    case goose
    case amazonQ = "amazon-q"

    var symbolName: String {
        switch self {
        case .claude: return "asterisk"
        case .codex: return "brain.head.profile"
        case .openCode: return "chevron.left.forwardslash.chevron.right"
        case .deepseek: return "sparkle"
        case .hermes: return "bird"
        case .gemini: return "sparkle.magnifyingglass"
        case .aider: return "wand.and.stars"
        case .cursorAgent: return "cursorarrow"
        case .goose: return "bird"
        case .amazonQ: return "q.circle"
        }
    }

    var colorHex: String {
        switch self {
        case .claude: return "#D97757"
        case .codex: return "#10A37F"
        case .openCode: return "#3B82F6"
        case .deepseek: return "#4D6BFE"
        case .hermes: return "#8E8E93"
        case .gemini: return "#4285F4"
        case .aider: return "#14B8A6"
        case .cursorAgent: return "#6B7280"
        case .goose: return "#8B5CF6"
        case .amazonQ: return "#FF9900"
        }
    }

    var color: Color { Color(hex: colorHex) }

    static func match(processName: String?) -> Self? {
        guard let processName else { return nil }
        let normalized = (processName as NSString).lastPathComponent.lowercased()
        return allCases.first { $0.rawValue == normalized }
    }
}

/// A CLI AI agent surfaced in the header menu and run in the terminal.
struct CLIAgent: Identifiable, Hashable {
    let name: String
    let command: String
    let colorHex: String
    let symbolName: String

    var id: String { command }

    var color: Color { Color(hex: colorHex) }

    /// First letter for the badge monogram.
    var monogram: String { String(name.prefix(1)).uppercased() }
}

/// A user-added agent persisted to config (no brand styling).
struct CustomAgent: Codable, Hashable, Identifiable {
    var name: String
    var command: String

    var id: String { command }
}

/// Built-in CLI agents, keyed by their detection/run command.
enum AgentCatalog {
    static let builtIn: [CLIAgent] = [
        CLIAgent(name: "Claude Code", command: "claude", colorHex: "#D97757", symbolName: "asterisk"),
        CLIAgent(name: "Codex", command: "codex", colorHex: "#10A37F", symbolName: "brain.head.profile"),
        CLIAgent(name: "OpenCode", command: "opencode", colorHex: "#3B82F6", symbolName: "chevron.left.forwardslash.chevron.right"),
        CLIAgent(name: "Gemini", command: "gemini", colorHex: "#4285F4", symbolName: "sparkle.magnifyingglass"),
        CLIAgent(name: "Aider", command: "aider", colorHex: "#14B8A6", symbolName: "wand.and.stars"),
        CLIAgent(name: "Cursor Agent", command: "cursor-agent", colorHex: "#6B7280", symbolName: "cursorarrow"),
        CLIAgent(name: "Goose", command: "goose", colorHex: "#8B5CF6", symbolName: "bird"),
        CLIAgent(name: "Amazon Q", command: "q", colorHex: "#FF9900", symbolName: "q.circle"),
        CLIAgent(name: "Minion", command: "minion", colorHex: "#F2C94C", symbolName: "person.crop.circle"),
        CLIAgent(name: "Tompero", command: "tompero start-day", colorHex: "#8E8E93", symbolName: "shippingbox"),
    ]

    /// Default look for a user-added agent.
    static func custom(_ spec: CustomAgent) -> CLIAgent {
        CLIAgent(name: spec.name, command: spec.command, colorHex: "#8E8E93", symbolName: "terminal.fill")
    }

    static func isBuiltIn(_ agent: CLIAgent) -> Bool {
        builtIn.contains { $0.command == agent.command }
    }
}

extension Color {
    init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        let r = UInt8(value.prefix(2), radix: 16) ?? 0
        let g = UInt8(value.dropFirst(2).prefix(2), radix: 16) ?? 0
        let b = UInt8(value.dropFirst(4).prefix(2), radix: 16) ?? 0
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
