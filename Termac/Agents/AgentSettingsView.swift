//
//  AgentSettingsView.swift
//  termac
//

import SwiftUI

/// "AI Agents" section: agents added by the user, shown in the header dropdown.
struct AgentSettingsSection: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var isAdding = false
    @State private var editingAgent: CustomAgent?
    @State private var removingAgent: CustomAgent?

    var body: some View {
        Group {
            ForEach($settings.customAgents) { $agent in
                HStack {
                    ColorPicker("", selection: colorBinding(for: $agent), supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 34, height: 24)
                        .help("Agent color — tints tabs where the agent runs")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(agent.name)
                        Text(agent.command)
                            .foregroundStyle(.secondary)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                    }
                    Spacer(minLength: 12)
                    Button { editingAgent = agent } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                    .help("Editar agente")
                    Button(role: .destructive) { removingAgent = agent } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Remover agente")
                    .confirmationDialog(
                        "Remover \(agent.name)?",
                        item: $removingAgent,
                        titleVisibility: .visible
                    ) { agent in
                        Button("Remover", role: .destructive) {
                            settings.removeCustomAgent(agent)
                        }
                        Button("Cancelar", role: .cancel) {}
                    } message: { _ in
                        Text("Esta ação não pode ser desfeita.")
                    }
                }
            }

            Button("Adicionar agente…") { isAdding = true }
                .sheet(isPresented: $isAdding) {
                    AgentEditorSheet(title: "Adicionar agente de IA") { name, command, colorHex in
                        settings.addCustomAgent(name: name, command: command, colorHex: colorHex)
                    }
                }
                .sheet(item: $editingAgent) { agent in
                    AgentEditorSheet(title: "Editar agente de IA", agent: agent) { name, command, colorHex in
                        settings.updateCustomAgent(agent, name: name, command: command, colorHex: colorHex)
                    }
                }

            Text("Os agentes são adicionados manualmente e executados em uma nova aba, no diretório da aba atual. A cor identifica as abas onde cada agente está executando.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    /// Bridges the agent's persisted hex to the ColorWell and back.
    private func colorBinding(for agent: Binding<CustomAgent>) -> Binding<Color> {
        Binding(
            get: { Color(hex: agent.wrappedValue.colorHex) },
            set: { agent.wrappedValue.colorHex = $0.hexString }
        )
    }
}

/// Sheet for adding or editing an agent by name + command + color.
private struct AgentEditorSheet: View {
    let title: String
    let onSave: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var command: String
    @State private var color: Color

    init(title: String, agent: CustomAgent? = nil, onSave: @escaping (String, String, String) -> Void) {
        self.title = title
        self.onSave = onSave
        _name = State(initialValue: agent?.name ?? "")
        _command = State(initialValue: agent?.command ?? "")
        _color = State(initialValue: Color(hex: agent?.colorHex ?? "#8E8E93"))
    }

    private var trimmedCommand: String {
        command.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            TextField("Nome", text: $name)
            TextField("Comando (ex.: claude, codex)", text: $command)
            HStack {
                Text("Cor")
                Spacer()
                ColorPicker("", selection: $color, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 44, height: 26)
            }
            HStack {
                Spacer()
                Button("Cancelar") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Salvar") {
                    onSave(name.isEmpty ? trimmedCommand : name, trimmedCommand, color.hexString)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedCommand.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}
