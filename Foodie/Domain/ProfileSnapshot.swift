//
//  ProfileSnapshot.swift
//  Foodie
//

import Foundation

struct ProfileSnapshot: Codable, Hashable {
    var displayName: String
    var dietarySummary: String
    var allergySummary: String
    var goalsSummary: String
    var favoriteCuisinesSummary: String
    var groceryBudgetNotes: String
    var cookingTimeNotes: String
    var joinedDate: Date

    init(displayName: String = "",
         dietarySummary: String = "",
         allergySummary: String = "",
         goalsSummary: String = "",
         favoriteCuisinesSummary: String = "",
         groceryBudgetNotes: String = "",
         cookingTimeNotes: String = "",
         joinedDate: Date = Date()) {
        self.displayName = displayName
        self.dietarySummary = dietarySummary
        self.allergySummary = allergySummary
        self.goalsSummary = goalsSummary
        self.favoriteCuisinesSummary = favoriteCuisinesSummary
        self.groceryBudgetNotes = groceryBudgetNotes
        self.cookingTimeNotes = cookingTimeNotes
        self.joinedDate = joinedDate
    }
}

extension ProfileSnapshot {
    init(profile: UserProfile) {
        self.init(
            displayName: profile.displayName,
            dietarySummary: profile.dietarySummary,
            allergySummary: profile.allergySummary,
            goalsSummary: profile.goalsSummary,
            favoriteCuisinesSummary: profile.favoriteCuisinesSummary,
            groceryBudgetNotes: profile.groceryBudgetNotes,
            cookingTimeNotes: profile.cookingTimeNotes,
            joinedDate: profile.joinedDate
        )
    }
}
