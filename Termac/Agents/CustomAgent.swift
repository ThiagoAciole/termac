//
//  CustomAgent.swift
//  termac
//

import AppKit
import SwiftUI

/// A user-added command persisted to config, surfaced in the agents dropdown.
/// The color tints tabs where the agent runs.
struct CustomAgent: Codable, Hashable, Identifiable {
    var name: String
    var command: String
    var colorHex: String

    var id: String { command }

    var color: Color { Color(hex: colorHex) }

    enum CodingKeys: String, CodingKey {
        case name
        case command
        case colorHex
    }

    /// Entries saved before colors existed decode as gray.
    init(name: String, command: String, colorHex: String = "#8E8E93") {
        self.name = name
        self.command = command
        self.colorHex = colorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        command = try container.decode(String.self, forKey: .command)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "#8E8E93"
    }
}

extension Color {
    /// Color from a `#RRGGBB` string; invalid input falls back to gray.
    init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        let r = UInt8(value.prefix(2), radix: 16) ?? 0x8E
        let g = UInt8(value.dropFirst(2).prefix(2), radix: 16) ?? 0x8E
        let b = UInt8(value.dropFirst(4).prefix(2), radix: 16) ?? 0x93
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }

    /// `#RRGGBB` string for persistence.
    var hexString: String {
        let srgb = NSColor(self).usingColorSpace(.sRGB)
        return String(
            format: "#%02X%02X%02X",
            Int(round((srgb?.redComponent ?? 0.55) * 255)),
            Int(round((srgb?.greenComponent ?? 0.55) * 255)),
            Int(round((srgb?.blueComponent ?? 0.55) * 255))
        )
    }
}
