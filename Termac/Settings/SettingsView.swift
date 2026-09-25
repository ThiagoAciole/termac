//
//  SettingsView.swift
//  termac
//

import AppKit
import OSLog
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
        .frame(width: 480, height: 620)
        .padding(8)
        .sheet(isPresented: $showingShortcuts) {
            ShortcutsView()
        }
    }
}

private struct AppearanceSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    private var previewFont: Font {
        let family = settings.fontFamily.isEmpty
            ? TerminalFont.resolvedDefaultFamily
            : settings.fontFamily
        let weight: Font.Weight
        switch settings.fontWeight {
        case .regular: weight = .regular
        case .medium: weight = .medium
        case .semibold: weight = .semibold
        case .bold: weight = .bold
        }
        return .custom(family, size: settings.fontSize).weight(weight)
    }

    var body: some View {
        Form {
            Section("Tema") {
                Picker("Tema", selection: $settings.theme) {
                    Section("Claro") {
                        ForEach(Theme.lightThemeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    Section("Escuro") {
                        ForEach(Theme.darkThemeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
            }

            Section("Fonte") {
                Picker("Família", selection: $settings.fontFamily) {
                    Text("Sistema").tag("")
                    ForEach(TerminalFont.selectableFamilies(), id: \.self) { family in
                        Text(family).tag(family)
                    }
                }

                LabeledContent("Tamanho") {
                    HStack(spacing: 4) {
                        TextField("", value: $settings.fontSize, format: .number)
                            .frame(width: 48)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                        Text("px").foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Altura da linha") {
                    HStack(spacing: 4) {
                        Text(settings.lineHeight, format: .number.precision(.fractionLength(2)))
                            .monospacedDigit()
                            .frame(width: 36, alignment: .trailing)
                        Text("×").foregroundStyle(.secondary)
                        Stepper("", value: $settings.lineHeight, in: AppSettings.Limits.lineHeight, step: 0.05)
                            .labelsHidden()
                    }
                }

                Picker("Peso", selection: $settings.fontWeight) {
                    ForEach(FontWeightSetting.allCases) { weight in
                        Text(weight.fontStyle).tag(weight)
                    }
                }
            }

            Section("Zoom") {
                LabeledContent("Escala da interface e do terminal") {
                    HStack(spacing: 8) {
                        Text("\(Int(settings.uiZoom))%")
                            .monospacedDigit()
                            .frame(width: 48, alignment: .trailing)
                        Slider(value: $settings.uiZoom, in: AppSettings.Limits.uiZoom, step: ZoomSetting.step)
                    }
                }
            }

            Section("Prévia") {
                Text("thiago.aciole ~ $ claude")
                    .font(previewFont)
                    .lineSpacing(CGFloat(settings.lineHeight - 1) * settings.fontSize)
                    .foregroundStyle(Theme.isDark ? .white : .black)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .formStyle(.grouped)
    }
}

private struct WindowSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var widthText = ""
    @State private var heightText = ""
    @FocusState private var focusedSizeField: SizeField?

    private enum SizeField {
        case width
        case height
    }

    var body: some View {
        Form {
            Section("Comportamento") {
                Toggle(
                    "Confirmar antes de fechar abas com um comando em execução",
                    isOn: $settings.confirmCloseRunningCommand
                )

                Toggle(
                    "Mostrar diretório no título das abas",
                    isOn: $settings.showCwdInTabTitle
                )

                Toggle(
                    "Abas verticais",
                    isOn: $settings.verticalTabs
                )
            }

            Section("Espaçamento do terminal") {
                LabeledContent("Padding configurável") {
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

                LabeledContent("Padding horizontal efetivo") {
                    Text("\(TermacConstants.effectiveTerminalPaddingX(settings.terminalPadding)) px")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Text("Inclui 16 px de respiro visual adicional nas laterais.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Tamanho de novas janelas") {
                LabeledContent("Largura") {
                    HStack(spacing: 4) {
                        TextField("", text: $widthText)
                            .focused($focusedSizeField, equals: .width)
                            .onSubmit { commitWidth() }
                            .frame(width: 72)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                        Text("px")
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Altura") {
                    HStack(spacing: 4) {
                        TextField("", text: $heightText)
                            .focused($focusedSizeField, equals: .height)
                            .onSubmit { commitHeight() }
                            .frame(width: 72)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                        Text("px")
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Aplica-se apenas a novas janelas; o valor é ajustado ao grid do terminal.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Cabeçalho") {
                Picker("Tamanho", selection: $settings.headerSize) {
                    ForEach(HeaderSizeSetting.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }

                Toggle(
                    "Mostrar botão da Command Palette",
                    isOn: $settings.showCommandPaletteButton
                )
            }
        }
        .formStyle(.grouped)
        .onAppear { initializeSizeText() }
        .onChange(of: settings.fontFamily) { _, _ in syncSizeText() }
        .onChange(of: settings.fontSize) { _, _ in syncSizeText() }
        .onChange(of: settings.fontWeight) { _, _ in syncSizeText() }
        .onChange(of: settings.lineHeight) { _, _ in syncSizeText() }
        .onChange(of: settings.terminalPadding) { _, _ in syncSizeText() }
        .onChange(of: settings.headerSize) { _, _ in syncSizeText() }
        .onChange(of: settings.verticalTabs) { _, _ in syncSizeText() }
        .onChange(of: settings.verticalTabBarWidth) { _, _ in syncSizeText() }
        .onChange(of: focusedSizeField) { previous, current in
            if previous == .width, current != .width {
                commitWidth()
            }
            if previous == .height, current != .height {
                commitHeight()
            }
            if current == nil {
                syncSizeText()
            }
        }
    }

    private func commitWidth() {
        guard let value = Double(widthText) else {
            syncSizeText()
            return
        }
        settings.windowColumns = WindowGeometry.gridColumns(
            forPixelWidth: CGFloat(value),
            settings: settings
        )
        syncSizeText()
    }

    private func commitHeight() {
        guard let value = Double(heightText) else {
            syncSizeText()
            return
        }
        settings.windowRows = WindowGeometry.gridRows(
            forPixelHeight: CGFloat(value),
            settings: settings
        )
        syncSizeText()
    }

    private func syncSizeText() {
        let size = WindowGeometry.contentSize(from: settings)
        if focusedSizeField != .width {
            widthText = String(Int(size.width.rounded()))
        }
        if focusedSizeField != .height {
            heightText = String(Int(size.height.rounded()))
        }
    }

    private func initializeSizeText() {
        let size = WindowGeometry.contentSize(from: settings)
        widthText = String(Int(size.width.rounded()))
        heightText = String(Int(size.height.rounded()))
    }

    private func commitFocusedSizeField() {
        switch focusedSizeField {
        case .width: commitWidth()
        case .height: commitHeight()
        case nil: break
        }
    }

}

private struct AgentsSettingsView: View {
    var body: some View {
        Form {
            Section("Agentes IA") {
                AgentSettingsSection()
            }
        }
        .formStyle(.grouped)
    }
}

private struct ShortcutsSettingsView: View {
    @Binding var showingShortcuts: Bool

    var body: some View {
        VStack(spacing: 0) {
            ShortcutsListView()

            HStack {
                Spacer()
                Button("Abrir em janela maior…") {
                    showingShortcuts = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
}

private struct ConfigurationSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section("Arquivo de configuração") {
                Text(settings.configurationPathDisplay)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Text(settings.configurationStatus)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button("Abrir configuração…") {
                    settings.openConfigFile()
                }

                Button("Recarregar configuração") {
                    settings.reloadFromDisk()
                }

                Button("Restaurar padrões…", role: .destructive) {
                    showingResetConfirmation = true
                }
                .confirmationDialog(
                    "Restaurar todas as configurações?",
                    isPresented: $showingResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Restaurar padrões", role: .destructive) {
                        settings.resetToDefaults()
                    }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text("Suas preferências atuais serão substituídas pelos valores padrão.")
                }
            }
        }
        .formStyle(.grouped)
    }
}
