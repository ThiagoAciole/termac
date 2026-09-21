import SwiftUI

struct VerticalTabBar: View {
    @Bindable var session: TabStore
    let onAddTab: () -> Void
    @State private var draggedTabID: UUID?
    private var theme: AppTheme { SettingsManager.shared.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onAddTab) { Label("New Tab", systemImage: "plus") }
                .buttonStyle(.plain)
                .padding(10)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(session.tabs) { tab in
                        HStack(spacing: 8) {
                            Circle().fill(tab.id == session.activeTabID ? theme.accentColor : theme.secondaryText.opacity(0.4)).frame(width: 7, height: 7)
                            Text(session.tabTitle(for: tab)).lineLimit(1)
                            Spacer()
                            Button { session.removeTab(tab.id) } label: { Image(systemName: "xmark").font(.caption) }
                                .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(tab.id == session.activeTabID ? theme.activeTabBackground : .clear, in: RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                        .onTapGesture { session.activeTabID = tab.id }
                        .onDrag {
                            draggedTabID = tab.id
                            return NSItemProvider(object: tab.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: VerticalTabDropDelegate(
                            targetID: tab.id,
                            session: session,
                            draggedTabID: $draggedTabID
                        ))
                    }
                }
                .padding(.horizontal, 6)
            }
            Spacer()
        }
        .frame(minWidth: 150, idealWidth: 200, maxWidth: 300)
        .background(theme.appCanvasBackground)
    }
}

private struct VerticalTabDropDelegate: DropDelegate {
    let targetID: UUID
    let session: Session
    @Binding var draggedTabID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedTabID,
              draggedTabID != targetID,
              let from = session.tabs.firstIndex(where: { $0.id == draggedTabID }),
              let to = session.tabs.firstIndex(where: { $0.id == targetID }) else { return }
        session.moveTab(from: IndexSet(integer: from), to: to > from ? to + 1 : to)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedTabID = nil
        return true
    }
}
