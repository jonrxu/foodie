//
//  FoodLogEntry.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

struct FoodLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var summary: String
    var estimatedCalories: Int?
    var confidence: Double?
    var mealType: String?
    var healthIndex: Int?
    var healthLevel: String?
    var healthAxes: FoodHealthAssessment.Axes?
    var healthTags: [String]?
    var healthHighlights: [String]?
    var nutrition: NutritionBreakdown?

    init(id: UUID = UUID(),
         date: Date = Date(),
         summary: String,
         estimatedCalories: Int? = nil,
         confidence: Double? = nil,
         mealType: String? = nil,
         healthIndex: Int? = nil,
         healthLevel: String? = nil,
         healthAxes: FoodHealthAssessment.Axes? = nil,
         healthTags: [String]? = nil,
         healthHighlights: [String]? = nil,
         nutrition: NutritionBreakdown? = nil) {
        self.id = id
        self.date = date
        self.summary = summary
        self.estimatedCalories = estimatedCalories
        self.confidence = confidence
        self.mealType = mealType
        self.healthIndex = healthIndex
        self.healthLevel = healthLevel
        self.healthAxes = healthAxes
        self.healthTags = healthTags
        self.healthHighlights = healthHighlights
        self.nutrition = nutrition
    }
}

extension FoodLogEntry {
    static func == (lhs: FoodLogEntry, rhs: FoodLogEntry) -> Bool {
        lhs.id == rhs.id
    }
}


