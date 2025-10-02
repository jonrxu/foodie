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
    var healthTags: [String]?
    var healthHighlights: [String]?

    init(id: UUID = UUID(),
         date: Date = Date(),
         summary: String,
         estimatedCalories: Int? = nil,
         confidence: Double? = nil,
         mealType: String? = nil,
         healthIndex: Int? = nil,
         healthTags: [String]? = nil,
         healthHighlights: [String]? = nil) {
        self.id = id
        self.date = date
        self.summary = summary
        self.estimatedCalories = estimatedCalories
        self.confidence = confidence
        self.mealType = mealType
        self.healthIndex = healthIndex
        self.healthTags = healthTags
        self.healthHighlights = healthHighlights
    }
}


