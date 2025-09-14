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
    var confidence: Double?
    var mealType: String?

    init(id: UUID = UUID(), date: Date = Date(), summary: String, confidence: Double? = nil, mealType: String? = nil) {
        self.id = id
        self.date = date
        self.summary = summary
        self.confidence = confidence
        self.mealType = mealType
    }
}


