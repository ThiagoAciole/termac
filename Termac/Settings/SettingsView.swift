//
//  SettingsView.swift
//  termac
//

import SwiftUI

struct SettingsView: View {
    @State private var showingShortcuts = false

    var body: some View {
        TabView {
            AppearanceSettingsView()
                .tabItem {
                    Label("Aparência", systemImage: "paintbrush")
                }

            WindowSettingsView()
                .tabItem {
                    Label("Janela", systemImage: "macwindow")
                }

            HeaderSettingsView()
                .tabItem {
                    Label("Header", systemImage: "rectangle.topthird.inset.filled")
                }

            AgentsSettingsView()
                .tabItem {
                    Label("Agentes IA", systemImage: "sparkles")
                }

            ShortcutsSettingsView(showingShortcuts: $showingShortcuts)
                .tabItem {
                    Label("Atalhos", systemImage: "keyboard")
                }

            ConfigurationSettingsView()
                .tabItem {
                    Label("Configuração", systemImage: "gearshape")
                }
        }
        .frame(width: 440, height: 780)
        .padding(8)
        .sheet(isPresented: $showingShortcuts) {
            ShortcutsView()
        }
    }
}

private struct AppearanceSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $settings.theme) {
                    Section("Light") {
                        ForEach(Theme.lightThemeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    Section("Dark") {
                        ForEach(Theme.darkThemeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
            }

            Section("Font") {
                Picker("Family", selection: $settings.fontFamily) {
                    Text("System").tag("")
                    ForEach(TerminalFont.selectableFamilies(), id: \.self) { family in
                        Text(family).tag(family)
                    }
                }

                LabeledContent("Size") {
                    HStack(spacing: 4) {
                        TextField(
                            "",
                            value: $settings.fontSize,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        Text("px")
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Line height") {
                    HStack(spacing: 4) {
                        Text(
                            settings.lineHeight,
                            format: .number.precision(.fractionLength(2))
                        )
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                        Text("×")
                            .foregroundStyle(.secondary)
                        Stepper(
                            "",
                            value: $settings.lineHeight,
                            in: AppSettings.Limits.lineHeight,
                            step: 0.05
                        )
                        .labelsHidden()
                    }
                }

                Picker("Weight", selection: $settings.fontWeight) {
                    ForEach(FontWeightSetting.allCases) { weight in
                        Text(weight.fontStyle).tag(weight)
                    }
                }
            }

            Section("Zoom") {
                LabeledContent("Interface and terminal") {
                    HStack(spacing: 8) {
                        Text("\(Int(settings.uiZoom))%")
                            .monospacedDigit()
                            .frame(width: 48, alignment: .trailing)
                        Slider(
                            value: $settings.uiZoom,
                            in: AppSettings.Limits.uiZoom,
                            step: ZoomSetting.step
                        )
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct WindowSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("Window") {
                Toggle(
                    "Confirm before closing tabs with a running command",
                    isOn: $settings.confirmCloseRunningCommand
                )

                Toggle(
                    "Show directory in tab titles",
                    isOn: $settings.showCwdInTabTitle
                )

                Toggle(
                    "Vertical tabs",
                    isOn: $settings.verticalTabs
                )

                LabeledContent("Padding") {
                    HStack(spacing: 4) {
                        TextField(
                            "",
                            value: $settings.terminalPadding,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        Text("px")
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Position") {
                    HStack(spacing: 8) {
                        TextField(
                            "",
                            value: $settings.windowOriginX,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        Text("×")
                            .foregroundStyle(.secondary)
                        TextField(
                            "",
                            value: $settings.windowOriginY,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                    }
                }
                Text("Position from the top-left of the visible desktop")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                LabeledContent("Size") {
                    HStack(spacing: 8) {
                        TextField(
                            "",
                            value: $settings.windowColumns,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        Text("×")
                            .foregroundStyle(.secondary)
                        TextField(
                            "",
                            value: $settings.windowRows,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                    }
                }
                Text("Size of new windows (e.g. 80 × 24)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct HeaderSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("Header") {
                Picker("Size", selection: $settings.headerSize) {
                    ForEach(HeaderSizeSetting.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct AgentsSettingsView: View {
    var body: some View {
        Form {
            Section("AI Agents") {
                AgentSettingsSection()
            }
        }
        .formStyle(.grouped)
    }
}

private struct ShortcutsSettingsView: View {
    @Binding var showingShortcuts: Bool

    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                Button("View Keyboard Shortcuts…") {
                    showingShortcuts = true
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct ConfigurationSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("Configuration") {
                Button("Open Configuration…") {
                    settings.openConfigFile()
                }
            }
        }
        .formStyle(.grouped)
    }
}
