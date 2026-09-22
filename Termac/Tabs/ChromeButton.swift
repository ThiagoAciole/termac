//
//  ChromeButton.swift
//  termac
//

import SwiftUI

/// Header chrome button with a subtle hover background.
struct ChromeButton: View {
    let systemName: String
    let help: String
    let iconSize: CGFloat
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .frame(width: frameWidth, height: frameHeight)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(isHovered ? 0.1 : 0))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}
