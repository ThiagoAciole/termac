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

    func refresh() {
        installed = AgentDetector.detectedAgents(custom: AppSettings.shared.customAgents)
    }
}
