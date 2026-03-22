//
//  PrototypeHomeViewModel.swift
//  Foodie
//

import Foundation

@MainActor
final class PrototypeHomeViewModel: ObservableObject {
    @Published private(set) var mealsLoggedThisWeek = 0
    @Published private(set) var latestCartItemCount = 0
    @Published private(set) var cgmStatusLabel = "Dexcom not connected"

    private let repositories: PrototypeRepositoryContainer

    init(repositories: PrototypeRepositoryContainer = .shared) {
        self.repositories = repositories
    }

    func reload() async {
        async let mealLogsTask = repositories.mealLogs.fetchAll()
        async let cartTask = repositories.carts.fetchLatestDraft()
        async let connectionTask = repositories.connections.fetchConnection(for: .dexcom)

        let mealLogs = (try? await mealLogsTask) ?? []
        let latestCart = (try? await cartTask) ?? nil
        let dexcomConnection = (try? await connectionTask) ?? nil

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date.distantPast
        mealsLoggedThisWeek = mealLogs.filter { $0.loggedAt >= weekAgo }.count
        latestCartItemCount = latestCart?.items.count ?? 0
        cgmStatusLabel = statusLabel(for: dexcomConnection)
    }

    private func statusLabel(for connection: ExternalConnection?) -> String {
        guard let connection else { return "Dexcom not connected" }

        switch connection.status {
        case .connected:
            return "Dexcom connected"
        case .pending:
            return "Dexcom setup pending"
        case .error:
            return "Dexcom needs attention"
        case .disconnected:
            return "Dexcom not connected"
        }
    }
}
