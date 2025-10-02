//
//  ApiKeyStore.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

final class ApiKeyStore {
    static let shared = ApiKeyStore()

    private let userDefaultsKey = "OPENAI_API_KEY"

    func getApiKey() -> String? {
        if let savedKey = UserDefaults.standard.string(forKey: userDefaultsKey), !savedKey.isEmpty {
            return savedKey
        }

        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        if let defaultKey = AppConfig.defaultOpenAIKey, !defaultKey.isEmpty {
            return defaultKey
        }

        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
           let key = plist["OPENAI_API_KEY"] as? String, !key.isEmpty {
            return key
        }

        return nil
    }

    func saveApiKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: userDefaultsKey)
    }
}


