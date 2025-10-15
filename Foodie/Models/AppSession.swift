//
//  AppSession.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

@MainActor
final class AppSession: ObservableObject {
    static let shared = AppSession()

    @Published private(set) var profile: UserProfile?
    @Published private(set) var isOnboardingPresented: Bool
    @Published private(set) var isAuthenticating: Bool = false
    @Published private(set) var authErrorMessage: String?

    private let profileStore: UserProfileStore
    private let preferences: UserPreferences
    private let preferencesStore: UserPreferencesStore

    init(profileStore: UserProfileStore = .shared,
         preferences: UserPreferences = .shared,
         preferencesStore: UserPreferencesStore = .shared) {
        self.profileStore = profileStore
        self.preferences = preferences
        self.preferencesStore = preferencesStore

        if let loadedProfile = profileStore.load() {
            profile = loadedProfile
            isOnboardingPresented = !loadedProfile.hasCompletedOnboarding
            applyProfileToLegacyPreferences(loadedProfile)
        } else {
            let provisionalProfile = UserProfile(joinedDate: Date())
            profile = provisionalProfile
            isOnboardingPresented = true
        }
    }

    func startOnboarding() {
        isOnboardingPresented = true
    }

    func cancelOnboarding() {
        if let stored = profileStore.load() {
            profile = stored
        }
        isOnboardingPresented = false
    }

    func updateProfile(_ transform: (inout UserProfile) -> Void) {
        guard var current = profile else { return }
        transform(&current)
        profile = current
        profileStore.save(current)
    }

    func completeOnboarding() {
        guard var current = profile else { return }
        current.hasCompletedOnboarding = true
        if current.joinedDate.timeIntervalSince1970 == 0 {
            current.joinedDate = Date()
        }
        profile = current
        profileStore.save(current)
        applyProfileToLegacyPreferences(current)
        isOnboardingPresented = false
    }

    func signOut() {
        profileStore.clear()
        preferencesStore.clearDisplayName()
        preferencesStore.clearDietaryPreferences()
        preferencesStore.clearFavoriteCuisines()
        preferencesStore.clearBudgetPreferences()
        preferences.dailyCalorieGoal = 2000
        let newProfile = UserProfile(joinedDate: Date())
        profile = newProfile
        isOnboardingPresented = true
    }

    func beginAuthentication() {
        authErrorMessage = nil
        isAuthenticating = true
    }

    func finishAuthentication(email: String?) {
        defer { isAuthenticating = false }
        guard var current = profile else { return }
        current.email = email
        current.joinedDate = current.joinedDate == .distantPast ? Date() : current.joinedDate
        profile = current
        profileStore.save(current)
    }

    func failAuthentication(with error: String) {
        authErrorMessage = error
        isAuthenticating = false
    }

    private func applyProfileToLegacyPreferences(_ profile: UserProfile) {
        preferences.dailyCalorieGoal = profile.dailyCalorieGoal ?? preferences.dailyCalorieGoal
        preferences.joinedDate = profile.joinedDate

        let dietary = profile.dietarySummary
        let allergies = profile.allergySummary
        let combinedDietaryNotes = [dietary, allergies]
            .filter { !$0.isEmpty }
            .joined(separator: "; ")
        preferencesStore.saveDietaryPreferences(combinedDietaryNotes)

        preferencesStore.saveDisplayName(profile.displayName)
        preferencesStore.saveFavoriteCuisines(profile.favoriteCuisinesSummary)

        let budgetNotes = [profile.groceryBudgetNotes, profile.cookingTimeNotes]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "; ")
        preferencesStore.saveBudgetPreferences(budgetNotes)
    }
}


