//
//  AgentSettingsView.swift
//  termac
//

import SwiftUI

/// "AI Agents" section: detected agents (read-only) plus custom agents.
struct AgentSettingsSection: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var store = AgentStore.shared
    @State private var isAdding = false

    var body: some View {
        Group {
            ForEach(store.installed.filter(AgentCatalog.isBuiltIn)) { agent in
                AgentBadge(agent: agent)
            }

            ForEach(settings.customAgents) { spec in
                HStack {
                    AgentBadge(agent: AgentCatalog.custom(spec))
                    Spacer()
                    Button(role: .destructive) {
                        settings.removeCustomAgent(spec)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Remove agent")
                }
            }

            Button("Add Agent…") { isAdding = true }
                .sheet(isPresented: $isAdding) {
                    AddAgentSheet { name, command in
                        settings.addCustomAgent(name: name, command: command)
                    }
                }

            Text("Agents are detected from your PATH. They run in the terminal's current directory.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .onAppear { store.refresh() }
    }
}

/// Sheet for adding a custom agent by name + command.
private struct AddAgentSheet: View {
    let onAdd: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var command = ""

    private var trimmedCommand: String {
        command.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add AI Agent").font(.headline)

            TextField("Name", text: $name)
            TextField("Command (e.g. claude, codex)", text: $command)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    onAdd(name.isEmpty ? trimmedCommand : name, trimmedCommand)
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
