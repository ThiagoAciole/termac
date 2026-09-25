//
//  ShortcutsView.swift
//  termac
//

import SwiftUI

struct ShortcutsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ShortcutsListView()

            HStack {
                Spacer()
                Button("Concluído") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(width: 420, height: 420)
    }
}
