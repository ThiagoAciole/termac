//
//  AgentSettingsView.swift
//  termac
//

import SwiftUI

/// "AI Agents" section: agents added by the user, shown in the header dropdown.
struct AgentSettingsSection: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var isAdding = false

    var body: some View {
        Group {
            ForEach($settings.customAgents) { $agent in
                HStack {
                    ColorPicker("", selection: colorBinding(for: $agent), supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 34, height: 24)
                        .help("Agent color — tints tabs where the agent runs")
                    Text(agent.name)
                    Spacer(minLength: 12)
                    Text(agent.command)
                        .foregroundStyle(.secondary)
                        .font(.caption.monospaced())
                    Button(role: .destructive) {
                        settings.removeCustomAgent(agent)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Remove agent")
                }
            }

            Button("Add Agent…") { isAdding = true }
                .sheet(isPresented: $isAdding) {
                    AddAgentSheet { name, command, colorHex in
                        settings.addCustomAgent(name: name, command: command, colorHex: colorHex)
                    }
                }

            Text("Agents are added manually above and run in a new tab at the current tab's directory. The color tints tabs where the agent runs.")
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

/// Sheet for adding an agent by name + command + color.
private struct AddAgentSheet: View {
    let onAdd: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var command = ""
    @State private var color = Color(hex: "#8E8E93")

    private var trimmedCommand: String {
        command.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add AI Agent").font(.headline)

            TextField("Name", text: $name)
            TextField("Command (e.g. claude, codex)", text: $command)

            HStack {
                Text("Color")
                Spacer()
                ColorPicker("", selection: $color, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 44, height: 26)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    onAdd(name.isEmpty ? trimmedCommand : name, trimmedCommand, color.hexString)
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
