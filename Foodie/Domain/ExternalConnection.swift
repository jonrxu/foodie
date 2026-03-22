//
//  ExternalConnection.swift
//  Foodie
//

import Foundation

enum ExternalProvider: String, Codable, CaseIterable, Hashable {
    case dexcom
    case instacart
}

enum ExternalConnectionStatus: String, Codable, CaseIterable, Hashable {
    case disconnected
    case pending
    case connected
    case error
}

struct ExternalConnection: Identifiable, Codable, Hashable {
    var id: ExternalProvider { provider }
    var provider: ExternalProvider
    var status: ExternalConnectionStatus
    var displayName: String?
    var connectedAt: Date?
    var updatedAt: Date
    var lastSyncAt: Date?
    var errorMessage: String?

    init(provider: ExternalProvider,
         status: ExternalConnectionStatus = .disconnected,
         displayName: String? = nil,
         connectedAt: Date? = nil,
         updatedAt: Date = Date(),
         lastSyncAt: Date? = nil,
         errorMessage: String? = nil) {
        self.provider = provider
        self.status = status
        self.displayName = displayName
        self.connectedAt = connectedAt
        self.updatedAt = updatedAt
        self.lastSyncAt = lastSyncAt
        self.errorMessage = errorMessage
    }
}
