//
//  AgentMenu.swift
//  termac
//

import SwiftUI

/// Header agents dropdown, left of the settings gear. Runs agents added in
/// Settings → AI Agents in a new tab.
struct AgentMenu: View {
    @ObservedObject var tabs: TabManager
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.headerScale) private var headerScale
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Menu {
            if settings.customAgents.isEmpty {
                Button("No AI agents added") { openSettings() }
            } else {
                ForEach(settings.customAgents) { agent in
                    Button {
                        tabs.runAgentInNewTab(agent)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(agent.color)
                                .frame(width: 8, height: 8)
                            Text(agent.name)
                        }
                    }
                    .help(agent.command)
                }
            }
            Divider()
            Button("Manage Agents…") { openSettings() }
        } label: {
            // Same glyph structure as ChromeButton — the legacy borderless
            // menu style shrank menu labels to menu-bar metrics.
            ChromeIconLabel(
                systemName: "apple.intelligence",
                iconSize: settings.headerSize.actionIconSize * headerScale,
                frameWidth: settings.headerSize.buttonFrameWidth * headerScale,
                frameHeight: settings.headerSize.buttonFrameHeight * headerScale
            )
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("AI Agents")
    }
}
