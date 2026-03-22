//
//  MealLog.swift
//  Foodie
//

import Foundation

enum MealLogSource: String, Codable, CaseIterable, Hashable {
    case photo
    case voice
    case text
    case barcode
    case manual
    case imported
    case unknown
}

enum MealTypeValue: String, Codable, CaseIterable, Hashable {
    case breakfast
    case lunch
    case dinner
    case snack
    case drink
    case unknown

    init(rawMealType: String?) {
        switch rawMealType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "breakfast": self = .breakfast
        case "lunch": self = .lunch
        case "dinner": self = .dinner
        case "snack": self = .snack
        case "drink", "beverage": self = .drink
        default: self = .unknown
        }
    }
}

struct MealAsset: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, Hashable {
        case photo
        case audio
        case text
        case barcode
    }

    let id: UUID
    var kind: Kind
    var localIdentifier: String?
    var mimeType: String?
    var createdAt: Date
    var previewText: String?

    init(id: UUID = UUID(),
         kind: Kind,
         localIdentifier: String? = nil,
         mimeType: String? = nil,
         createdAt: Date = Date(),
         previewText: String? = nil) {
        self.id = id
        self.kind = kind
        self.localIdentifier = localIdentifier
        self.mimeType = mimeType
        self.createdAt = createdAt
        self.previewText = previewText
    }
}

struct MealAnalysis: Codable, Hashable {
    var mealType: MealTypeValue?
    var estimatedCalories: Int?
    var confidence: Double?
    var nutrition: NutritionBreakdown?
    var healthIndex: Int?
    var healthLevel: String?
    var healthAxes: FoodHealthAssessment.Axes?
    var healthTags: [String]
    var highlights: [String]

    init(mealType: MealTypeValue? = nil,
         estimatedCalories: Int? = nil,
         confidence: Double? = nil,
         nutrition: NutritionBreakdown? = nil,
         healthIndex: Int? = nil,
         healthLevel: String? = nil,
         healthAxes: FoodHealthAssessment.Axes? = nil,
         healthTags: [String] = [],
         highlights: [String] = []) {
        self.mealType = mealType
        self.estimatedCalories = estimatedCalories
        self.confidence = confidence
        self.nutrition = nutrition
        self.healthIndex = healthIndex
        self.healthLevel = healthLevel
        self.healthAxes = healthAxes
        self.healthTags = healthTags
        self.highlights = highlights
    }
}

struct MealLog: Identifiable, Codable, Hashable {
    let id: UUID
    var loggedAt: Date
    var source: MealLogSource
    var summary: String
    var rawInput: String?
    var notes: String?
    var assets: [MealAsset]
    var analysis: MealAnalysis?

    init(id: UUID = UUID(),
         loggedAt: Date = Date(),
         source: MealLogSource = .unknown,
         summary: String,
         rawInput: String? = nil,
         notes: String? = nil,
         assets: [MealAsset] = [],
         analysis: MealAnalysis? = nil) {
        self.id = id
        self.loggedAt = loggedAt
        self.source = source
        self.summary = summary
        self.rawInput = rawInput
        self.notes = notes
        self.assets = assets
        self.analysis = analysis
    }
}

extension MealLog {
    init(legacy entry: FoodLogEntry) {
        self.init(
            id: entry.id,
            loggedAt: entry.date,
            source: .manual,
            summary: entry.summary,
            analysis: MealAnalysis(
                mealType: MealTypeValue(rawMealType: entry.mealType),
                estimatedCalories: entry.estimatedCalories,
                confidence: entry.confidence,
                nutrition: entry.nutrition,
                healthIndex: entry.healthIndex,
                healthLevel: entry.healthLevel,
                healthAxes: entry.healthAxes,
                healthTags: entry.healthTags ?? [],
                highlights: entry.healthHighlights ?? []
            )
        )
    }
}

extension FoodLogEntry {
    init(domain mealLog: MealLog) {
        self.init(
            id: mealLog.id,
            date: mealLog.loggedAt,
            summary: mealLog.summary,
            estimatedCalories: mealLog.analysis?.estimatedCalories,
            confidence: mealLog.analysis?.confidence,
            mealType: mealLog.analysis?.mealType?.rawValue,
            healthIndex: mealLog.analysis?.healthIndex,
            healthLevel: mealLog.analysis?.healthLevel,
            healthAxes: mealLog.analysis?.healthAxes,
            healthTags: mealLog.analysis?.healthTags.isEmpty == false ? mealLog.analysis?.healthTags : nil,
            healthHighlights: mealLog.analysis?.highlights.isEmpty == false ? mealLog.analysis?.highlights : nil,
            nutrition: mealLog.analysis?.nutrition
        )
    }
}
