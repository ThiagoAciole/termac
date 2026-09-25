//
//  TermacConfigStore.swift
//  termac
//

import AppKit
import Foundation
import UniformTypeIdentifiers
import Yams

/// YAML float written as exactly two fractional digits (e.g. `1.40`), not scientific notation.
private struct TwoDecimalFloat: Equatable {
    var value: Double

    init(_ value: Double) {
        self.value = (value * 100).rounded() / 100
    }
}

extension TwoDecimalFloat: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Double.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension TwoDecimalFloat: YAMLEncodable {
    func box() -> Node {
        Node(String(format: "%.2f", value), Tag(.float))
    }
}

/// On-disk YAML shape for `~/.config/termac/config.yml`.
/// Missing keys (including whole `font` / `window` sections) decode as defaults.
struct TermacConfigFile: Codable, Equatable {
    struct Font: Codable, Equatable {
        var family: String
        /// Whole pixels in YAML (`14`, not `1.4e+1`).
        var size: Int
        var weight: String
        var lineHeight: Double

        enum CodingKeys: String, CodingKey {
            case family
            case size
            case weight
            case lineHeight = "line_height"
        }

        static var `default`: Font {
            Font(
                family: "",
                size: Int(TerminalFont.defaultSize.rounded()),
                weight: FontWeightSetting.regular.rawValue,
                lineHeight: AppSettings.Defaults.lineHeight
            )
        }

        init(family: String, size: Int, weight: String, lineHeight: Double) {
            self.family = family
            self.size = size
            self.weight = weight
            self.lineHeight = lineHeight
        }

        init(from decoder: Decoder) throws {
            let defaults = Font.default
            let container = try decoder.container(keyedBy: CodingKeys.self)
            family = try container.decodeIfPresent(String.self, forKey: .family) ?? defaults.family
            if container.contains(.size) {
                // Accept legacy scientific/float sizes from earlier YAML writes.
                if let intSize = try? container.decode(Int.self, forKey: .size) {
                    size = intSize
                } else if let doubleSize = try? container.decode(Double.self, forKey: .size) {
                    size = Int(doubleSize.rounded())
                } else {
                    size = defaults.size
                }
            } else {
                size = defaults.size
            }
            weight = try container.decodeIfPresent(String.self, forKey: .weight) ?? defaults.weight
            lineHeight = try container.decodeIfPresent(TwoDecimalFloat.self, forKey: .lineHeight)?.value
                ?? defaults.lineHeight
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(family, forKey: .family)
            try container.encode(size, forKey: .size)
            try container.encode(weight, forKey: .weight)
            try container.encode(TwoDecimalFloat(lineHeight), forKey: .lineHeight)
        }
    }

    struct Window: Codable, Equatable {
        var padding: Int
        var columns: Int
        var rows: Int

        enum CodingKeys: String, CodingKey {
            case padding
            case columns
            case rows
        }

        static var `default`: Window {
            Window(
                padding: AppSettings.Defaults.terminalPadding,
                columns: AppSettings.Defaults.windowColumns,
                rows: AppSettings.Defaults.windowRows
            )
        }

        init(padding: Int, columns: Int, rows: Int) {
            self.padding = padding
            self.columns = columns
            self.rows = rows
        }

        init(from decoder: Decoder) throws {
            let defaults = Window.default
            let container = try decoder.container(keyedBy: CodingKeys.self)
            padding = try container.decodeIfPresent(Int.self, forKey: .padding) ?? defaults.padding
            columns = try container.decodeIfPresent(Int.self, forKey: .columns) ?? defaults.columns
            rows = try container.decodeIfPresent(Int.self, forKey: .rows) ?? defaults.rows
        }
    }

    var theme: String
    var font: Font
    var window: Window
    /// Global percentage zoom shared by terminal text and tab chrome.
    var zoom: Double
    /// When true, closing a tab with a foreground process prompts for confirmation.
    var confirmCloseRunningCommand: Bool
    /// When true, tab titles are prefixed with the cwd basename (`dir - node`).
    var showCwdInTabTitle: Bool
    /// When true, tabs are shown in a left rail instead of a top strip.
    var verticalTabs: Bool
    /// Width of the vertical tab rail in points.
    var verticalTabBarWidth: Int
    /// Header chrome scale (see `HeaderSizeSetting`).
    var headerSize: String
    /// Whether the Command Palette button is shown in the header.
    var showCommandPaletteButton: Bool
    /// User-added CLI AI agents.
    var customAgents: [CustomAgent]

    enum CodingKeys: String, CodingKey {
        case theme
        case font
        case window
        case zoom
        case confirmCloseRunningCommand = "confirm_close_running_command"
        case showCwdInTabTitle = "show_cwd_in_tab_title"
        case verticalTabs = "vertical_tabs"
        case verticalTabBarWidth = "vertical_tab_bar_width"
        case headerSize = "header_size"
        case showCommandPaletteButton = "show_command_palette_button"
        case customAgents = "custom_agents"
    }

    static var `default`: TermacConfigFile {
        TermacConfigFile(
            theme: Theme.defaultDarkThemeName,
            font: .default,
            window: .default,
            zoom: AppSettings.Defaults.uiZoom,
            confirmCloseRunningCommand: AppSettings.Defaults.confirmCloseRunningCommand,
            showCwdInTabTitle: AppSettings.Defaults.showCwdInTabTitle,
            verticalTabs: AppSettings.Defaults.verticalTabs,
            verticalTabBarWidth: AppSettings.Defaults.verticalTabBarWidth,
            headerSize: AppSettings.Defaults.headerSize.rawValue,
            showCommandPaletteButton: AppSettings.Defaults.showCommandPaletteButton,
            customAgents: AppSettings.Defaults.customAgents
        )
    }

    init(
        theme: String,
        font: Font,
        window: Window,
        zoom: Double = AppSettings.Defaults.uiZoom,
        confirmCloseRunningCommand: Bool = AppSettings.Defaults.confirmCloseRunningCommand,
        showCwdInTabTitle: Bool = AppSettings.Defaults.showCwdInTabTitle,
        verticalTabs: Bool = AppSettings.Defaults.verticalTabs,
        verticalTabBarWidth: Int = AppSettings.Defaults.verticalTabBarWidth,
        headerSize: String = AppSettings.Defaults.headerSize.rawValue,
        showCommandPaletteButton: Bool = AppSettings.Defaults.showCommandPaletteButton,
        customAgents: [CustomAgent] = AppSettings.Defaults.customAgents
    ) {
        self.theme = theme
        self.font = font
        self.window = window
        self.zoom = zoom
        self.confirmCloseRunningCommand = confirmCloseRunningCommand
        self.showCwdInTabTitle = showCwdInTabTitle
        self.verticalTabs = verticalTabs
        self.verticalTabBarWidth = verticalTabBarWidth
        self.headerSize = headerSize
        self.showCommandPaletteButton = showCommandPaletteButton
        self.customAgents = customAgents
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(theme, forKey: .theme)
        try container.encode(font, forKey: .font)
        try container.encode(window, forKey: .window)
        try container.encode(TwoDecimalFloat(zoom), forKey: .zoom)
        try container.encode(confirmCloseRunningCommand, forKey: .confirmCloseRunningCommand)
        try container.encode(showCwdInTabTitle, forKey: .showCwdInTabTitle)
        try container.encode(verticalTabs, forKey: .verticalTabs)
        try container.encode(verticalTabBarWidth, forKey: .verticalTabBarWidth)
        try container.encode(headerSize, forKey: .headerSize)
        try container.encode(showCommandPaletteButton, forKey: .showCommandPaletteButton)
        try container.encode(customAgents, forKey: .customAgents)
    }

    init(from decoder: Decoder) throws {
        let defaults = TermacConfigFile.default
        let container = try decoder.container(keyedBy: CodingKeys.self)
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? defaults.theme
        font = try container.decodeIfPresent(Font.self, forKey: .font) ?? defaults.font
        window = try container.decodeIfPresent(Window.self, forKey: .window) ?? defaults.window
        zoom = try container.decodeIfPresent(TwoDecimalFloat.self, forKey: .zoom)?.value
            ?? defaults.zoom
        confirmCloseRunningCommand = try container.decodeIfPresent(
            Bool.self,
            forKey: .confirmCloseRunningCommand
        ) ?? defaults.confirmCloseRunningCommand
        showCwdInTabTitle = try container.decodeIfPresent(
            Bool.self,
            forKey: .showCwdInTabTitle
        ) ?? defaults.showCwdInTabTitle
        verticalTabs = try container.decodeIfPresent(
            Bool.self,
            forKey: .verticalTabs
        ) ?? defaults.verticalTabs
        verticalTabBarWidth = try container.decodeIfPresent(
            Int.self,
            forKey: .verticalTabBarWidth
        ) ?? defaults.verticalTabBarWidth
        headerSize = try container.decodeIfPresent(
            String.self,
            forKey: .headerSize
        ) ?? defaults.headerSize
        showCommandPaletteButton = try container.decodeIfPresent(
            Bool.self,
            forKey: .showCommandPaletteButton
        ) ?? defaults.showCommandPaletteButton
        customAgents = try container.decodeIfPresent(
            [CustomAgent].self,
            forKey: .customAgents
        ) ?? defaults.customAgents
    }
}

enum TermacConfigStore {
    /// XDG-style path: `~/.config/termac/config.yml`.
    static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("termac", isDirectory: true)
            .appendingPathComponent("config.yml", isDirectory: false)
    }

    static func load(from url: URL) throws -> TermacConfigFile {
        let data = try Data(contentsOf: url)
        let decoder = YAMLDecoder()
        return try decoder.decode(TermacConfigFile.self, from: data)
    }

    /// Encodes and writes atomically (`config.yml.tmp` then replace).
    static func save(_ config: TermacConfigFile, to url: URL) throws {
        let encoder = YAMLEncoder()
        let yaml = try encoder.encode(config)
        let parent = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )
        let tempURL = parent.appendingPathComponent("config.yml.tmp")
        try yaml.write(to: tempURL, atomically: true, encoding: .utf8)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: url)
        }
    }

    /// Creates parent dirs and writes `seeding` (or defaults) when the file is missing.
    @discardableResult
    static func ensureExists(
        at url: URL,
        seeding: TermacConfigFile = .default
    ) throws -> TermacConfigFile {
        if FileManager.default.fileExists(atPath: url.path) {
            return try load(from: url)
        }
        try save(seeding, to: url)
        return seeding
    }

    /// Opens the config in the default `.yml` app, else the default plain-text editor
    /// (Ghostty-style; often TextEdit).
    static func openInEditor(url: URL) {
        let workspace = NSWorkspace.shared
        let editor =
            workspace.urlForApplication(toOpen: url)
            ?? workspace.urlForApplication(toOpen: UTType.yaml)
            ?? workspace.urlForApplication(toOpen: UTType.plainText)
        if let editor {
            workspace.open(
                [url],
                withApplicationAt: editor,
                configuration: NSWorkspace.OpenConfiguration()
            )
        } else {
            workspace.open(url)
        }
    }
}
