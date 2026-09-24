//
//  ChromeButton.swift
//  termac
//

import SwiftUI

/// Icon + hit frame shared by chrome buttons and menu triggers, so every
/// header action renders with the exact same size and hover behavior.
struct ChromeIconLabel: View {
    let systemName: String
    let iconSize: CGFloat
    let frameWidth: CGFloat
    let frameHeight: CGFloat

    @State private var isHovered = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: iconSize, weight: .medium))
            .frame(width: frameWidth, height: frameHeight)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.1 : 0))
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isHovered = hovering
                }
            }
    }
}

/// Header chrome button with a subtle hover background.
struct ChromeButton: View {
    let systemName: String
    let help: String
    let iconSize: CGFloat
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ChromeIconLabel(
                systemName: systemName,
                iconSize: iconSize,
                frameWidth: frameWidth,
                frameHeight: frameHeight
            )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

/// Agents + Settings grouped in an outlined pill so the trailing header
/// actions read as one control across both tab-bar layouts.
struct ChromeActionsCluster: View {
    @ObservedObject var tabs: TabManager
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.openSettings) private var openSettings
    @Environment(\.headerScale) private var headerScale

    var body: some View {
        HStack(spacing: 0) {
            ChromeButton(
                systemName: "command.square",
                help: "Command Palette (⌘K)",
                iconSize: settings.headerSize.actionIconSize * settings.actionIconScale * headerScale,
                frameWidth: settings.headerSize.buttonFrameWidth * headerScale,
                frameHeight: settings.headerSize.buttonFrameHeight * headerScale
            ) {
                tabs.showCommandPalette()
            }

            AgentMenu(tabs: tabs)

            ChromeButton(
                systemName: settings.settingsIconSymbol,
                help: "Settings",
                iconSize: settings.headerSize.actionIconSize * settings.actionIconScale * headerScale,
                frameWidth: settings.headerSize.buttonFrameWidth * headerScale,
                frameHeight: settings.headerSize.buttonFrameHeight * headerScale
            ) {
                openSettings()
            }
        }
        .padding(.horizontal, 5)
        .background(
            // Black-based fill so the pill reads as an inset (darker than the
            // chrome bar) in dark themes, matching the reference layout.
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.16))
                )
        )
        .padding(.leading, 12)
        .padding(.trailing, 6)
    }
}
