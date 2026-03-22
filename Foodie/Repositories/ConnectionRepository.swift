//
//  ConnectionRepository.swift
//  Foodie
//

import Foundation

protocol ConnectionRepository {
    func fetchAll() async throws -> [ExternalConnection]
    func fetchConnection(for provider: ExternalProvider) async throws -> ExternalConnection?
    func save(_ connection: ExternalConnection) async throws
}

final class LocalConnectionRepository: ConnectionRepository {
    private let storage = JSONFileStorage(fileName: "external_connections.json")

    func fetchAll() async throws -> [ExternalConnection] {
        let saved = storage.load([ExternalConnection].self) ?? []

        var byProvider = Dictionary(uniqueKeysWithValues: saved.map { ($0.provider, $0) })
        for provider in ExternalProvider.allCases where byProvider[provider] == nil {
            byProvider[provider] = ExternalConnection(provider: provider)
        }

        return ExternalProvider.allCases.compactMap { byProvider[$0] }
    }

    func fetchConnection(for provider: ExternalProvider) async throws -> ExternalConnection? {
        try await fetchAll().first(where: { $0.provider == provider })
    }

    func save(_ connection: ExternalConnection) async throws {
        var connections = try await fetchAll()
        if let index = connections.firstIndex(where: { $0.provider == connection.provider }) {
            connections[index] = connection
        } else {
            connections.append(connection)
        }
        storage.save(connections)
    }
}
