//
//  CommandPaletteView.swift
//  termac
//

import SwiftUI

struct CommandPaletteView: View {
    @ObservedObject var tabs: TabManager
    @StateObject private var model = CommandPaletteModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { tabs.hideCommandPalette() }

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search commands, tabs, and agents", text: Binding(
                        get: { model.query },
                        set: { model.update(query: $0) }
                    ))
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onSubmit { executeCurrent() }
                }
                .padding(14)

                Divider()

                if model.filteredItems.isEmpty {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass")
                        .frame(height: 160)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(Array(model.filteredItems.enumerated()), id: \.element.id) { index, item in
                                    CommandPaletteRow(
                                        item: item,
                                        isSelected: index == model.selectedIndex
                                    ) {
                                        model.select(index: index)
                                        executeCurrent()
                                    }
                                    .id(item.id)
                                }
                            }
                            .padding(6)
                        }
                        .frame(maxHeight: 360)
                        .onChange(of: model.selectedIndex) { _, index in
                            guard model.filteredItems.indices.contains(index) else { return }
                            withAnimation(.easeOut(duration: 0.1)) {
                                proxy.scrollTo(model.filteredItems[index].id, anchor: .center)
                            }
                        }
                    }
                }
            }
            .frame(width: 560)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.16))
            }
            .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
        }
        .onAppear {
            model.setItems(tabs.commandPaletteItems())
            isSearchFocused = true
        }
        .onChange(of: tabs.sessions.map(\.id)) { _, _ in
            model.setItems(tabs.commandPaletteItems())
        }
        .onChange(of: tabs.selectedID) { _, _ in
            model.setItems(tabs.commandPaletteItems())
        }
        .onChange(of: tabs.isCommandPalettePresented) { _, isPresented in
            if isPresented {
                model.reset()
                model.setItems(tabs.commandPaletteItems())
                isSearchFocused = true
            }
        }
        .onKeyPress(.upArrow) {
            model.moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            model.moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.escape) {
            tabs.hideCommandPalette()
            return .handled
        }
    }

    private func executeCurrent() {
        guard let item = model.selectCurrent() else { return }
        tabs.hideCommandPalette()
        item.execute()
    }
}

private struct CommandPaletteRow: View {
    let item: CommandPaletteItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .lineLimit(1)
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.14) : .clear)
        }
    }
}
