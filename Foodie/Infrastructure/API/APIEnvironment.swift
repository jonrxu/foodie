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
           let remoteURL = URL(string: rawValue) {
            return APIEnvironment(mode: .remote(remoteURL))
        }

        if let fallbackURLString = AppConfig.defaultBackendBaseURL,
           let remoteURL = URL(string: fallbackURLString) {
            return APIEnvironment(mode: .remote(remoteURL))
        }

        return .stub
    }
}
