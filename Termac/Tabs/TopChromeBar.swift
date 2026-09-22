//
//  TopChromeBar.swift
//  termac
//

import SwiftUI

/// Top strip for the content column in vertical-tabs mode: sidebar toggle, window drag, + / Settings / Layout.
/// When the sidebar is visible, traffic lights sit over it; when collapsed, this bar insets for them.
struct TopChromeBar: View {
    @ObservedObject var tabs: TabManager
    @Binding var isSidebarVisible: Bool
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.openSettings) private var openSettings
    @Environment(\.headerScale) private var headerScale

    var body: some View {
        HStack(spacing: 0) {
            if !isSidebarVisible {
                Color.clear
                    .frame(width: TermacConstants.trafficLightsLeadingInset)
            }

            ChromeButton(
                systemName: "sidebar.left",
                help: isSidebarVisible ? "Hide Sidebar" : "Show Sidebar",
                iconSize: settings.headerSize.buttonIconSize * headerScale,
                frameWidth: settings.headerSize.buttonFrameWidth * headerScale,
                frameHeight: settings.headerSize.buttonFrameHeight * headerScale
            ) {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isSidebarVisible.toggle()
                }
            }
            .padding(.leading, isSidebarVisible ? 6 : 0)

            // Leftover width is non-hit-testable so double-click / drag reach WindowDragRegion.
            Spacer(minLength: 8)

            ChromeButton(
                systemName: "plus",
                help: "New Tab",
                iconSize: settings.headerSize.buttonIconSize * headerScale,
                frameWidth: settings.headerSize.buttonFrameWidth * headerScale,
                frameHeight: settings.headerSize.buttonFrameHeight * headerScale
            ) {
                tabs.newTab()
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
            .padding(.leading, 12)

            WindowLayoutMenu()
                .padding(.trailing, 6)
        }
        .frame(height: settings.headerSize.barHeight * headerScale)
        .background {
            ZStack {
                Theme.chromeBackground
                    .id(settings.theme)
                WindowDragRegion()
            }
        }
    }
}
