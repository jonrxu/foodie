//
//  DexcomConnectionViewModel.swift
//  Foodie
//

import Foundation

@MainActor
final class DexcomConnectionViewModel: ObservableObject {
    static let shared = DexcomConnectionViewModel()

    @Published private(set) var connection = ExternalConnection(provider: .dexcom)
    @Published private(set) var weeklySummary: GlucoseSummary?
    @Published private(set) var isLoadingStatus = false
    @Published private(set) var isConnecting = false
    @Published private(set) var isSyncing = false
    @Published private(set) var errorMessage: String?

    private let backendClient: BackendClient
    private let repositories: PrototypeRepositoryContainer
    private var didBootstrap = false

    init(
        backendClient: BackendClient = .shared,
        repositories: PrototypeRepositoryContainer = .shared
    ) {
        self.backendClient = backendClient
        self.repositories = repositories
    }

    var statusLabel: String {
        switch connection.status {
        case .connected:
            if let lastSyncAt = connection.lastSyncAt {
                return "Synced \(Self.relativeFormatter.localizedString(for: lastSyncAt, relativeTo: Date()))"
            }
            return "Dexcom connected"
        case .pending:
            return "Dexcom setup pending"
        case .error:
            return connection.errorMessage ?? "Dexcom needs attention"
        case .disconnected:
            return "Dexcom not connected"
        }
    }

    var statusTitle: String {
        switch connection.status {
        case .connected:
            return "Dexcom connected"
        case .pending:
            return "Finish Dexcom sign-in"
        case .error:
            return "Dexcom needs attention"
        case .disconnected:
            return "Connect Dexcom"
        }
    }

    var actionTitle: String {
        if isConnecting { return "Opening Dexcom..." }
        switch connection.status {
        case .connected:
            return "Reconnect"
        case .pending:
            return "Open Dexcom"
        case .error, .disconnected:
            return "Connect Dexcom"
        }
    }

    func bootstrapIfNeeded() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        await loadCachedState()
        await refreshConnectionStatus()
        await loadWeeklySummary()
    }

    func loadCachedState() async {
        connection = (try? await repositories.connections.fetchConnection(for: .dexcom)) ?? ExternalConnection(provider: .dexcom)
        weeklySummary = try? await repositories.glucose.fetchLatestSummary()
    }

    func refreshConnectionStatus() async {
        isLoadingStatus = true
        defer { isLoadingStatus = false }

        do {
            let response = try await backendClient.fetchDexcomConnectionStatus()
            let mappedConnection = ExternalConnection(
                provider: .dexcom,
                status: mappedStatus(response.status),
                displayName: "Dexcom",
                connectedAt: response.connectedAt,
                updatedAt: Date(),
                lastSyncAt: response.lastSyncAt,
                errorMessage: response.errorMessage
            )
            try await repositories.connections.save(mappedConnection)
            connection = mappedConnection
            errorMessage = response.errorMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestConnectionURL() async -> URL? {
        isConnecting = true
        defer { isConnecting = false }

        do {
            let response = try await backendClient.startDexcomAuthorization()
            let pendingConnection = ExternalConnection(
                provider: .dexcom,
                status: .pending,
                displayName: "Dexcom",
                updatedAt: Date()
            )
            try await repositories.connections.save(pendingConnection)
            connection = pendingConnection
            errorMessage = nil
            return response.authorizationURL
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func handleIncomingURL(_ url: URL) async {
        guard url.scheme?.lowercased() == "foodie",
              url.host?.lowercased() == "dexcom-connected" else {
            return
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let callbackStatus = components?.queryItems?.first(where: { $0.name == "status" })?.value

        await refreshConnectionStatus()
        if callbackStatus == "connected" {
            await syncAndLoadSummary()
        } else if callbackStatus == "error" {
            errorMessage = connection.errorMessage ?? "Dexcom connection failed"
        }
    }

    func syncAndLoadSummary() async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            let updatedConnection = try await backendClient.triggerDexcomSync()
            let mappedConnection = ExternalConnection(
                provider: .dexcom,
                status: mappedStatus(updatedConnection.status),
                displayName: "Dexcom",
                connectedAt: updatedConnection.connectedAt,
                updatedAt: Date(),
                lastSyncAt: updatedConnection.lastSyncAt,
                errorMessage: updatedConnection.errorMessage
            )
            try await repositories.connections.save(mappedConnection)
            connection = mappedConnection
            try await loadWeeklySummary(forceRemote: true)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadWeeklySummary(forceRemote: Bool = false) async {
        if !forceRemote, let cachedSummary = try? await repositories.glucose.fetchLatestSummary() {
            weeklySummary = cachedSummary
        }

        guard connection.status == .connected else { return }

        do {
            let response = try await backendClient.fetchWeeklyGlucoseSummary()
            try await repositories.glucose.saveSummary(response.summary)
            try await repositories.glucose.saveReadings(response.summary.readings)
            weeklySummary = response.summary
        } catch {
            if weeklySummary == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func mappedStatus(_ rawStatus: String) -> ExternalConnectionStatus {
        ExternalConnectionStatus(rawValue: rawStatus) ?? .error
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}
