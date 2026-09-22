//
//  ChromeButton.swift
//  termac
//

import SwiftUI

/// Icon + hit frame shared by chrome buttons and menu triggers, so every
/// header action renders with the exact same size and hover behavior.
struct ChromeIconLabel: View {
    let systemName: String
    let iconSize: CGFloat
    let frameWidth: CGFloat
    let frameHeight: CGFloat

    @State private var isHovered = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: iconSize, weight: .medium))
            .frame(width: frameWidth, height: frameHeight)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.1 : 0))
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isHovered = hovering
                }
            }
    }
}

/// Header chrome button with a subtle hover background.
struct ChromeButton: View {
    let systemName: String
    let help: String
    let iconSize: CGFloat
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ChromeIconLabel(
                systemName: systemName,
                iconSize: iconSize,
                frameWidth: frameWidth,
                frameHeight: frameHeight
            )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
