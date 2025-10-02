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

    func loadFavoriteCuisines() -> String {
        UserDefaults.standard.string(forKey: cuisinesKey) ?? ""
    }

    func saveFavoriteCuisines(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed, forKey: cuisinesKey)
    }

    func clearFavoriteCuisines() {
        UserDefaults.standard.removeObject(forKey: cuisinesKey)
    }

    func loadBudgetPreferences() -> String {
        UserDefaults.standard.string(forKey: budgetKey) ?? ""
    }

    func saveBudgetPreferences(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed, forKey: budgetKey)
    }

    func clearBudgetPreferences() {
        UserDefaults.standard.removeObject(forKey: budgetKey)
    }
}
