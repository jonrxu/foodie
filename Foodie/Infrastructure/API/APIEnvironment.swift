//
//  APIEnvironment.swift
//  Foodie
//

import Foundation

struct APIEnvironment {
    enum Mode {
        case stub
        case remote(URL)
    }

    let mode: Mode

    static let stub = APIEnvironment(mode: .stub)
    
    static var current: APIEnvironment {
        if let rawValue = ProcessInfo.processInfo.environment["FOODIE_BACKEND_URL"],
           let remoteURL = backendURL(from: rawValue) {
            return APIEnvironment(mode: .remote(remoteURL))
        }

        if let fallbackURLString = AppConfig.defaultBackendBaseURL,
           let remoteURL = backendURL(from: fallbackURLString) {
            return APIEnvironment(mode: .remote(remoteURL))
        }

        return .stub
    }

    private static func backendURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.contains("://") {
            return URL(string: trimmed)
        }

        let scheme = trimmed.hasPrefix("localhost") || trimmed.hasPrefix("127.0.0.1") ? "http" : "https"
        return URL(string: "\(scheme)://\(trimmed)")
    }
}
