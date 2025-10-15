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
    private let cuisinesKey = "USER_FAVORITE_CUISINES"
    private let budgetKey = "USER_BUDGET_TIME_PREFS"
    private let displayNameKey = "USER_DISPLAY_NAME"
    private let instacartKey = "INSTACART_API_KEY"

    func loadDietaryPreferences() -> String {
        UserDefaults.standard.string(forKey: dietaryKey) ?? ""
    }

    func saveDietaryPreferences(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: dietaryKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: dietaryKey)
        }
    }

    func clearDietaryPreferences() {
        UserDefaults.standard.removeObject(forKey: dietaryKey)
    }

    func loadFavoriteCuisines() -> String {
        UserDefaults.standard.string(forKey: cuisinesKey) ?? ""
    }

    func saveFavoriteCuisines(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: cuisinesKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: cuisinesKey)
        }
    }

    func clearFavoriteCuisines() {
        UserDefaults.standard.removeObject(forKey: cuisinesKey)
    }

    func loadBudgetPreferences() -> String {
        UserDefaults.standard.string(forKey: budgetKey) ?? ""
    }

    func saveBudgetPreferences(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: budgetKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: budgetKey)
        }
    }

    func clearBudgetPreferences() {
        UserDefaults.standard.removeObject(forKey: budgetKey)
    }

    func loadDisplayName() -> String {
        UserDefaults.standard.string(forKey: displayNameKey) ?? ""
    }

    func saveDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: displayNameKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: displayNameKey)
        }
    }

    func clearDisplayName() {
        UserDefaults.standard.removeObject(forKey: displayNameKey)
    }

    func loadInstacartApiKey() -> String? {
        UserDefaults.standard.string(forKey: instacartKey)
    }

    func saveInstacartApiKey(_ key: String?) {
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: instacartKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: instacartKey)
        }
    }

    func clearInstacartApiKey() {
        UserDefaults.standard.removeObject(forKey: instacartKey)
    }
}
