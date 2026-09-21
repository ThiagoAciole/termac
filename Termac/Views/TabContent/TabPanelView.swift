import SwiftUI

struct TabPanelView: View {
    @Environment(AppState.self) private var appState
    @Bindable var tab: Tab
    var workingDirectory: String = ""
    private var theme: AppTheme { SettingsManager.shared.theme }

    var body: some View {
        Group {
            switch tab.content {
            case .terminal:
                terminalView

            case .text(let text):
                TextEditorPanel(text: text) { newText in
                    tab.content = .text(newText)
                }

            case .notes(let notes):
                NotesPanel(notes: notes) { newNotes in
                    tab.content = .notes(newNotes)
                }

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var terminalView: some View {
        TerminalSwiftUIView(workingDirectory: workingDirectory, tab: tab, appState: appState)
    }
}

// MARK: - Text Editor Panel

struct TextEditorPanel: View {
    @State private var text: String
    var onChange: (String) -> Void
    private var theme: AppTheme { SettingsManager.shared.theme }

    init(text: String, onChange: @escaping (String) -> Void) {
        self._text = State(initialValue: text)
        self.onChange = onChange
    }

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(theme.primaryText)
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(theme.contentBackground)
            .onChange(of: text) { _, newValue in
                onChange(newValue)
            }
    }
}

// MARK: - Notes Panel

struct NotesPanel: View {
    @State private var notes: String
    var onChange: (String) -> Void
    private var theme: AppTheme { SettingsManager.shared.theme }

    init(notes: String, onChange: @escaping (String) -> Void) {
        self._notes = State(initialValue: notes)
        self.onChange = onChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(.orange)
                Text("Notes")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(theme.secondaryText)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.elevatedSurface)

            TextEditor(text: $notes)
                .font(.body)
                .foregroundStyle(theme.primaryText)
                .scrollContentBackground(.hidden)
                .padding(12)
                .onChange(of: notes) { _, newValue in
                    onChange(newValue)
                }
        }
        .background(theme.contentBackground)
    }
}

