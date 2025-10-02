//
//  UserPreferencesStore.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

final class UserPreferencesStore {
    static let shared = UserPreferencesStore()

    private let dietaryKey = "USER_DIETARY_PREFERENCES"

    func loadDietaryPreferences() -> String {
        UserDefaults.standard.string(forKey: dietaryKey) ?? ""
    }

    func saveDietaryPreferences(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed, forKey: dietaryKey)
    }

    func clearDietaryPreferences() {
        UserDefaults.standard.removeObject(forKey: dietaryKey)
    }
}
