//
//  AgentStore.swift
//  termac
//

import Combine
import Foundation

/// Shared cache of detected agents, refreshed when the menu or settings appear.
@MainActor
final class AgentStore: ObservableObject {
    static let shared = AgentStore()

    @Published private(set) var installed: [CLIAgent] = []

    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings = .shared) {
        settings.$customAgents
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    func refresh() {
        installed = AgentDetector.detectedAgents(custom: AppSettings.shared.customAgents)
    }
}
