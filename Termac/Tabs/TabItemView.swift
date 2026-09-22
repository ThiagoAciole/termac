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

    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.headerScale) private var headerScale
    @State private var isCloseHovered = false
    @State private var isHovered = false

    /// Selected > hovered > idle background tint for the tab chip.
    private var backgroundFill: Color {
        if isSelected { return Color.primary.opacity(0.15) }
        if isHovered { return Color.primary.opacity(0.08) }
        return Color.clear
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal")
                .font(.system(size: settings.headerSize.tabIconSize * headerScale, weight: .medium))
                .foregroundStyle(.secondary)

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
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Close Tab", action: onClose)
        }
    }
}
