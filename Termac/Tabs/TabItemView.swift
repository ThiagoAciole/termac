//
//  TabItemView.swift
//  termac
//

import SwiftUI

struct TabItemView: View {
    @ObservedObject var session: TerminalSession
    let isSelected: Bool
    let fillsWidth: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    let onTogglePin: () -> Void
    let onDuplicate: () -> Void
    let onMove: (UUID) -> Void

    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.headerScale) private var headerScale
    @State private var isCloseHovered = false
    @State private var isHovered = false
    @State private var isRenaming = false
    @State private var draftTitle = ""

    /// Agent color launched in this tab, if any; tints the whole chip.
    private var agentColor: Color? {
        session.agentColorHex.map { Color(hex: $0) }
    }

    /// Selected > hovered > idle background tint for the tab chip.
    /// An agent color replaces the neutral tint.
    private var backgroundFill: Color {
        if let agentColor {
            if isSelected { return agentColor.opacity(0.38) }
            if isHovered { return agentColor.opacity(0.24) }
            return agentColor.opacity(0.16)
        }
        if isSelected { return Color.primary.opacity(0.15) }
        if isHovered { return Color.primary.opacity(0.08) }
        return Color.clear
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: session.isPinned ? "pin.fill" : "terminal")
                .font(.system(size: settings.headerSize.tabIconSize * headerScale))
                .frame(
                    width: settings.headerSize.tabIconSize * headerScale,
                    height: settings.headerSize.tabIconSize * headerScale
                )
                .foregroundStyle(session.isPinned ? Color.orange : .secondary)

            Text(session.title)
                .lineLimit(1)
                .truncationMode(.tail)
                // minWidth 0 lets the label shrink under the chip max instead of resisting truncation.
                .frame(minWidth: 0, alignment: .leading)

            Spacer(minLength: 8)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: settings.headerSize.closeButtonSize * headerScale, weight: .semibold))
                    .frame(width: 16, height: 16)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(isCloseHovered ? 0.12 : 0))
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isCloseHovered ? 1.0 : (isSelected ? 0.7 : 0.45))
            .help("Close Tab")
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isCloseHovered = hovering
                }
            }
        }
        .font(.system(size: settings.headerSize.tabFontSize * headerScale))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(
            maxWidth: fillsWidth ? .infinity : TermacConstants.maxTabWidth,
            alignment: .leading
        )
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundFill)
        )
        .contentShape(Rectangle())
        .help(session.title)
        .onTapGesture(perform: onSelect)
        .draggable(TabDragID(id: session.id.uuidString))
        .dropDestination(for: TabDragID.self) { dropped, _ in
            guard let dragged = dropped.first,
                  let draggedID = UUID(uuidString: dragged.id),
                  draggedID != session.id
            else { return false }
            onMove(draggedID)
            return true
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Rename Tab…") {
                draftTitle = session.customTitle ?? ""
                isRenaming = true
            }
            Button(session.isPinned ? "Unpin Tab" : "Pin Tab", action: onTogglePin)
            Button("Duplicate Tab", action: onDuplicate)
            Divider()
            Button("Close Tab", action: onClose)
        }
        .alert("Rename Tab", isPresented: $isRenaming) {
            TextField("Name", text: $draftTitle)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                session.applyCustomTitle(draftTitle)
            }
        } message: {
            Text("Leave empty to restore the automatic title.")
        }
    }
}
