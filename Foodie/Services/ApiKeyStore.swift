//
//  ApiKeyStore.swift
//  Foodie
//
//

import Foundation

final class ApiKeyStore {
    static let shared = ApiKeyStore()

    private let legacyUserDefaultsKey = "OPENAI_API_KEY"
    private let keychainAccount = "OPENAI_API_KEY"

    func getApiKey() -> String? {
        if let savedKey = KeychainStore.shared.read(account: keychainAccount), !savedKey.isEmpty {
            return savedKey
        }

        if let savedKey = UserDefaults.standard.string(forKey: legacyUserDefaultsKey), !savedKey.isEmpty {
            _ = KeychainStore.shared.write(savedKey, account: keychainAccount)
            UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
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
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            clearApiKey()
            return
        }
        _ = KeychainStore.shared.write(trimmed, account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
    }

    func clearApiKey() {
        _ = KeychainStore.shared.delete(account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
    }
}

