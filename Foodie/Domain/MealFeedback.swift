//
//  MealFeedback.swift
//  Foodie
//

import Foundation

enum MealFeedbackMode: String, Codable, CaseIterable, Hashable {
    case measured
    case predicted
}

struct MealFeedback: Identifiable, Codable, Hashable {
    let id: UUID
    var mealLogID: UUID
    var createdAt: Date
    var mode: MealFeedbackMode
    var headline: String
    var summary: String
    var coachMessage: String
    var suggestedSwap: String?
    var linkedSpikeEventID: UUID?
    var suggestedCartItems: [String]

    init(id: UUID = UUID(),
         mealLogID: UUID,
         createdAt: Date = Date(),
         mode: MealFeedbackMode,
         headline: String,
         summary: String,
         coachMessage: String,
         suggestedSwap: String? = nil,
         linkedSpikeEventID: UUID? = nil,
         suggestedCartItems: [String] = []) {
        self.id = id
        self.mealLogID = mealLogID
        self.createdAt = createdAt
        self.mode = mode
        self.headline = headline
        self.summary = summary
        self.coachMessage = coachMessage
        self.suggestedSwap = suggestedSwap
        self.linkedSpikeEventID = linkedSpikeEventID
        self.suggestedCartItems = suggestedCartItems
    }
}
