//
//  FoodHealthAnalyzer.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

struct FoodHealthAnalyzer {
    let summary: String
    var goal: Goal = .balanced

    enum Goal {
        case balanced
        case weightLoss
        case muscleGain
        case heartHealthy
        case lowSodium
    }

    func compute() -> FoodHealthAssessment {
        let lowered = summary.lowercased()

        var scoreComponents: [String: Double] = [:]

        scoreComponents["whole_foods"] = lowered.containsAny(of: Keys.wholeFoods) ? 0.15 : 0
        scoreComponents["vegetables"] = lowered.containsAny(of: Keys.vegetables) ? 0.12 : 0
        scoreComponents["lean_protein"] = lowered.containsAny(of: Keys.leanProteins) ? 0.12 : 0
        scoreComponents["whole_grain"] = lowered.containsAny(of: Keys.wholeGrains) ? 0.1 : 0
        scoreComponents["fruit"] = lowered.containsAny(of: Keys.fruits) ? 0.08 : 0

        var negatives: Double = 0
        var negativeHighlights: [String] = []

        if lowered.containsAny(of: Keys.ultraProcessed) {
            negatives += 0.18
            negativeHighlights.append("Ultra-processed item")
        }
        if lowered.containsAny(of: Keys.sugary) {
            negatives += 0.16
            negativeHighlights.append("Added sugar")
        }
        if lowered.containsAny(of: Keys.fried) {
            negatives += 0.12
            negativeHighlights.append("Fried preparation")
        }
        if lowered.containsAny(of: Keys.highSodium) {
            negatives += 0.1
            negativeHighlights.append("Likely high sodium")
        }
        if lowered.containsAny(of: Keys.saturatedFat) {
            negatives += 0.08
            negativeHighlights.append("High saturated fat")
        }

        let positiveScore = scoreComponents.values.reduce(0, +)
        let healthScore = Int(((positiveScore - negatives).clamped(to: -1...1) + 1) / 2 * 100)

        var tags: Set<String> = []
        for (key, value) in scoreComponents where value > 0 {
            tags.insert(key)
        }
        if lowered.containsAny(of: Keys.ultraProcessed) { tags.insert("ultra_processed") }
        if lowered.containsAny(of: Keys.sugary) { tags.insert("added_sugar") }
        if lowered.containsAny(of: Keys.fried) { tags.insert("fried") }
        if lowered.containsAny(of: Keys.highSodium) { tags.insert("high_sodium") }
        if lowered.containsAny(of: Keys.saturatedFat) { tags.insert("saturated_fat") }

        var highlights: [String] = []
        if scoreComponents["whole_foods"] ?? 0 > 0 { highlights.append("Whole-food ingredients") }
        if scoreComponents["lean_protein"] ?? 0 > 0 { highlights.append("Lean protein source") }
        if scoreComponents["whole_grain"] ?? 0 > 0 { highlights.append("Whole-grain base") }
        if scoreComponents["fruit"] ?? 0 > 0 { highlights.append("Fruit serving") }
        if scoreComponents["vegetables"] ?? 0 > 0 { highlights.append("Vegetable serving") }

        highlights.append(contentsOf: negativeHighlights)

        let finalScore = max(0, min(100, healthScore))

        return FoodHealthAssessment(score: finalScore,
                                    tags: Array(tags).sorted(),
                                    highlights: Array(highlights.prefix(3)))
    }
}

private enum Keys {
    static let wholeFoods = ["salad", "bowl", "homemade", "fresh", "roasted", "steamed"]
    static let vegetables = ["broccoli", "spinach", "kale", "carrot", "lettuce", "greens", "pepper", "cabbage"]
    static let leanProteins = ["chicken", "turkey", "salmon", "tuna", "cod", "tofu", "tempeh", "lentil", "beans"]
    static let wholeGrains = ["quinoa", "brown rice", "oats", "whole wheat", "farro", "barley"]
    static let fruits = ["apple", "banana", "berries", "orange", "grape", "melon", "pear", "peach", "mango"]
    static let ultraProcessed = ["chips", "fries", "candy", "soda", "fast food", "burger", "pizza", "donut"]
    static let sugary = ["sugary", "sweet", "caramel", "syrup", "frosting", "dessert", "milkshake", "sweetened"]
    static let fried = ["fried", "crispy", "tempura", "deep-fried"]
    static let highSodium = ["soy sauce", "ramen", "instant", "canned", "processed meats"]
    static let saturatedFat = ["butter", "cream", "cheese", "bacon", "sausage", "lard"]
}

private extension String {
    func containsAny(of terms: [String]) -> Bool {
        terms.contains { self.contains($0) }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}


