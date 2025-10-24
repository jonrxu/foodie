//
//  NutritionBreakdown.swift
//  Foodie
//
//

import Foundation

struct NutritionBreakdown: Codable, Equatable {
    struct Totals: Codable, Equatable {
        var calories: Double?
        var proteinGrams: Double?
        var carbohydrateGrams: Double?
        var fatGrams: Double?
        var fiberGrams: Double?
        var addedSugarGrams: Double?
        var sodiumMilligrams: Double?
        var saturatedFatGrams: Double?
        var unsaturatedFatGrams: Double?
    }

    struct Portion: Codable, Equatable {
        var unit: String?
        var quantity: Double?
        var text: String?
    }

    struct Item: Codable, Equatable {
        var name: String
        var description: String?
        var portion: Portion?
        var totals: Totals
        var confidence: Double?
        var tags: [String]?
    }

    struct Confidence: Codable, Equatable {
        var overall: Double?
        var calories: Double?
        var protein: Double?
        var carbohydrates: Double?
        var fat: Double?
        var fiber: Double?
        var addedSugar: Double?
        var sodium: Double?
    }

    var totals: Totals
    var items: [Item]
    var confidence: Confidence?
    var notes: [String]?

    init(totals: Totals,
         items: [Item] = [],
         confidence: Confidence? = nil,
         notes: [String]? = nil) {
        self.totals = totals
        self.items = items
        self.confidence = confidence
        self.notes = notes
    }

    static let empty = NutritionBreakdown(totals: Totals(), items: [])
}

extension NutritionBreakdown.Totals {
    mutating func add(_ other: NutritionBreakdown.Totals) {
        calories = (calories ?? 0) + (other.calories ?? 0)
        proteinGrams = (proteinGrams ?? 0) + (other.proteinGrams ?? 0)
        carbohydrateGrams = (carbohydrateGrams ?? 0) + (other.carbohydrateGrams ?? 0)
        fatGrams = (fatGrams ?? 0) + (other.fatGrams ?? 0)
        fiberGrams = (fiberGrams ?? 0) + (other.fiberGrams ?? 0)
        addedSugarGrams = (addedSugarGrams ?? 0) + (other.addedSugarGrams ?? 0)
        sodiumMilligrams = (sodiumMilligrams ?? 0) + (other.sodiumMilligrams ?? 0)
        saturatedFatGrams = (saturatedFatGrams ?? 0) + (other.saturatedFatGrams ?? 0)
        unsaturatedFatGrams = (unsaturatedFatGrams ?? 0) + (other.unsaturatedFatGrams ?? 0)
    }
}


