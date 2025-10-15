//
//  UserProfile.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

struct UserProfile: Codable {
    enum DietaryStyle: String, CaseIterable, Codable, Identifiable {
        case omnivore
        case vegetarian
        case vegan
        case pescatarian
        case flexitarian
        case keto
        case paleo
        case mediterranean
        case glutenFree
        case dairyFree
        case lowFodmap
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .omnivore: return "Balanced omnivore"
            case .vegetarian: return "Vegetarian"
            case .vegan: return "Vegan"
            case .pescatarian: return "Pescatarian"
            case .flexitarian: return "Flexitarian"
            case .keto: return "Lower carb / keto"
            case .paleo: return "Paleo"
            case .mediterranean: return "Mediterranean"
            case .glutenFree: return "Gluten free"
            case .dairyFree: return "Dairy free"
            case .lowFodmap: return "Low FODMAP"
            case .custom: return "Custom"
            }
        }
    }

    enum AllergyTag: String, CaseIterable, Codable, Identifiable {
        case peanuts
        case treeNuts
        case soy
        case eggs
        case dairy
        case shellfish
        case fish
        case wheat
        case sesame
        case gluten
        case none
        case other

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .peanuts: return "Peanuts"
            case .treeNuts: return "Tree nuts"
            case .soy: return "Soy"
            case .eggs: return "Eggs"
            case .dairy: return "Dairy"
            case .shellfish: return "Shellfish"
            case .fish: return "Fish"
            case .wheat: return "Wheat"
            case .sesame: return "Sesame"
            case .gluten: return "Gluten"
            case .none: return "No allergies"
            case .other: return "Other"
            }
        }
    }

    enum HealthGoal: String, CaseIterable, Codable, Identifiable {
        case eatHealthier
        case manageWeight
        case buildMuscle
        case improveEnergy
        case supportMedical
        case saveTime
        case saveMoney
        case exploreRecipes

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .eatHealthier: return "Eat healthier"
            case .manageWeight: return "Weight management"
            case .buildMuscle: return "Build muscle"
            case .improveEnergy: return "Improve energy"
            case .supportMedical: return "Support a medical need"
            case .saveTime: return "Save time"
            case .saveMoney: return "Spend less on food"
            case .exploreRecipes: return "Find new recipes"
            }
        }
    }

    var displayName: String
    var email: String?
    var dietaryStyles: [DietaryStyle]
    var customDietaryNotes: String
    var allergyTags: [AllergyTag]
    var customAllergyNotes: String
    var healthGoals: [HealthGoal]
    var favoriteCuisines: [String]
    var groceryBudgetNotes: String
    var cookingTimeNotes: String
    var dailyCalorieGoal: Int?
    var joinedDate: Date
    var hasCompletedOnboarding: Bool

    init(displayName: String = "",
         email: String? = nil,
         dietaryStyles: [DietaryStyle] = [],
         customDietaryNotes: String = "",
         allergyTags: [AllergyTag] = [],
         customAllergyNotes: String = "",
         healthGoals: [HealthGoal] = [],
         favoriteCuisines: [String] = [],
         groceryBudgetNotes: String = "",
         cookingTimeNotes: String = "",
         dailyCalorieGoal: Int? = nil,
         joinedDate: Date = Date(),
         hasCompletedOnboarding: Bool = false) {
        self.displayName = displayName
        self.email = email
        self.dietaryStyles = dietaryStyles
        self.customDietaryNotes = customDietaryNotes
        self.allergyTags = allergyTags
        self.customAllergyNotes = customAllergyNotes
        self.healthGoals = healthGoals
        self.favoriteCuisines = favoriteCuisines
        self.groceryBudgetNotes = groceryBudgetNotes
        self.cookingTimeNotes = cookingTimeNotes
        self.dailyCalorieGoal = dailyCalorieGoal
        self.joinedDate = joinedDate
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

extension UserProfile {
    var dietarySummary: String {
        let styleText = dietaryStyles
            .filter { $0 != .custom }
            .map { $0.displayName }
            .joined(separator: ", ")

        let notes = customDietaryNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        return [styleText, notes].filter { !$0.isEmpty }.joined(separator: "; ")
    }

    var allergySummary: String {
        let tags = allergyTags
            .filter { $0 != .none && $0 != .other }
            .map { $0.displayName }
            .joined(separator: ", ")

        let notes = customAllergyNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        return [tags, notes].filter { !$0.isEmpty }.joined(separator: "; ")
    }

    var goalsSummary: String {
        healthGoals.map { $0.displayName }.joined(separator: ", ")
    }

    var favoriteCuisinesSummary: String {
        favoriteCuisines.joined(separator: ", ")
    }

    var lifestyleSummary: String {
        [groceryBudgetNotes, cookingTimeNotes]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "; ")
    }
}


