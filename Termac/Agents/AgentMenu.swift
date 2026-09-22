//
//  AgentMenu.swift
//  termac
//

import SwiftUI

/// Header "AI agents" dropdown, left of the settings gear.
struct AgentMenu: View {
    @ObservedObject var tabs: TabManager
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var store = AgentStore.shared
    @Environment(\.headerScale) private var headerScale
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Menu {
            if store.installed.isEmpty {
                Text("No AI agents detected")
            } else {
                ForEach(store.installed) { agent in
                    Button {
                        tabs.runAgent(agent)
                    } label: {
                        AgentBadge(agent: agent)
                    }
                }
            }
            Divider()
            Button("Manage Agents…") { openSettings() }
        } label: {
            Image(systemName: "sparkles")
                .font(.system(size: settings.headerSize.buttonIconSize * headerScale, weight: .medium))
                .frame(
                    width: settings.headerSize.buttonFrameWidth * headerScale,
                    height: settings.headerSize.buttonFrameHeight * headerScale
                )
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("AI Agents")
        .onAppear { store.refresh() }
    }
}

/// Colored monogram + name + command, used in the menu and settings.
struct AgentBadge: View {
    let agent: CLIAgent

    var body: some View {
        HStack(spacing: 8) {
            Text(agent.monogram)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(agent.color))
            Text(agent.name)
            Spacer(minLength: 12)
            Text(agent.command)
                .foregroundStyle(.secondary)
                .font(.caption.monospaced())
        }
    }
}
